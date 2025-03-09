import Foundation
import AuthenticationServices
import SwiftUI
import LocalAuthentication
import Combine

class OAuthService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var isAuthenticating = false
    @Published var error: Error?
    
    private let nextcloudService = NextcloudService()
    private var cancellables = Set<AnyCancellable>()
    
    // OAuth Konfiguration
    private let clientId = "mdu_app_client"
    private let redirectUri = "mduapp://auth"
    private let scope = "openid profile email"
    private let responseType = "code"
    private let authorizationEndpoint = "http://vpn.privat.krasscrash.ovh/oauth/authorize"
    private let tokenEndpoint = "http://vpn.privat.krasscrash.ovh/oauth/token"
    private let userInfoEndpoint = "http://vpn.privat.krasscrash.ovh/oauth/userinfo"
    private let directLoginEndpoint = "http://vpn.privat.krasscrash.ovh/api/login"
    
    // Callback für erfolgreiche Authentifizierung
    var onAuthenticationCompleted: ((UserEntity) -> Void)?
    
    // Direkte Anmeldung mit Benutzername und Passwort
    func loginWithCredentials(username: String, password: String) {
        isAuthenticating = true
        error = nil
        
        // Verwende den NextcloudService für die Anmeldung
        nextcloudService.login(username: username, password: password) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let nextcloudUser):
                // Speichere das Passwort sicher in der Keychain
                KeychainManager.savePassword(password, for: username)
                
                // Speichere den Benutzer in Core Data
                let coreDataManager = CoreDataManager.shared
                coreDataManager.saveUser(
                    firstName: nextcloudUser.firstName,
                    lastName: nextcloudUser.lastName,
                    email: nextcloudUser.email,
                    username: nextcloudUser.username,
                    birthDate: nil, // Nextcloud liefert kein Geburtsdatum
                    schoolClass: nextcloudUser.schoolClass,
                    accessToken: "nextcloud-token", // Dummy-Token
                    refreshToken: "nextcloud-refresh-token", // Dummy-Token
                    tokenExpiryDate: Date().addingTimeInterval(3600) // 1 Stunde gültig
                )
                
                // Rufe den gespeicherten Benutzer ab
                if let user = coreDataManager.getCurrentUser() {
                    self.onAuthenticationCompleted?(user)
                }
                
            case .failure(let error):
                self.error = error
            }
            
            self.isAuthenticating = false
        }
    }
    
    // Aktualisiere Benutzerdaten mit gespeichertem Passwort
    func refreshUserData(username: String, completion: @escaping (Bool) -> Void) {
        guard let password = KeychainManager.getPassword(for: username) else {
            completion(false)
            return
        }
        
        nextcloudService.refreshUserData(username: username, password: password) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let nextcloudUser):
                // Speichere den aktualisierten Benutzer in Core Data
                let coreDataManager = CoreDataManager.shared
                if let user = coreDataManager.getCurrentUser() {
                    user.firstName = nextcloudUser.firstName
                    user.lastName = nextcloudUser.lastName
                    user.email = nextcloudUser.email
                    user.schoolClass = nextcloudUser.schoolClass
                    coreDataManager.saveContext()
                    completion(true)
                } else {
                    completion(false)
                }
                
            case .failure(let error):
                self.error = error
                completion(false)
            }
        }
    }
    
    // Token aktualisieren, wenn es abgelaufen ist (wird für Nextcloud nicht benötigt)
    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        let coreDataManager = CoreDataManager.shared
        
        // Prüfe, ob das Token noch gültig ist
        if coreDataManager.isTokenValid() {
            completion(true)
            return
        }
        
        // Hole den Benutzernamen
        guard let user = coreDataManager.getCurrentUser(),
              let username = user.username else {
            completion(false)
            return
        }
        
        // Aktualisiere die Benutzerdaten
        refreshUserData(username: username, completion: completion)
    }
    
    // Passwort mit FaceID/TouchID anzeigen
    func getPasswordWithBiometricAuth(for username: String, completion: @escaping (String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Passwort anzeigen"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        let password = KeychainManager.getPassword(for: username)
                        completion(password)
                    } else {
                        completion(nil)
                    }
                }
            }
        } else {
            // Biometrische Authentifizierung nicht verfügbar
            completion(nil)
        }
    }
    
    // Abmelden
    func logout() {
        // Lösche das Passwort aus der Keychain
        if let user = CoreDataManager.shared.getCurrentUser(), let username = user.username {
            KeychainManager.deletePassword(for: username)
        }
        
        // Lösche den Benutzer aus Core Data
        CoreDataManager.shared.deleteCurrentUser()
    }
    
    // ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    static func savePassword(_ password: String, for username: String) {
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Lösche vorhandenes Passwort
        SecItemDelete(query as CFDictionary)
        
        // Speichere neues Passwort
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Fehler beim Speichern des Passworts: \(status)")
        }
    }
    
    static func getPassword(for username: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return String(data: retrievedData, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    static func deletePassword(for username: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Datenmodelle

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

struct LoginResponse: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let email: String
    let birthDate: Date?
    let schoolClass: String?
    let accessToken: String
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case username, email
        case firstName = "first_name"
        case lastName = "last_name"
        case birthDate = "birth_date"
        case schoolClass = "school_class"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct UserInfo: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let email: String
    let birthDate: Date?
    let schoolClass: String?
    let password: String?
    
    enum CodingKeys: String, CodingKey {
        case username, email, password
        case firstName = "first_name"
        case lastName = "last_name"
        case birthDate = "birth_date"
        case schoolClass = "school_class"
    }
} 