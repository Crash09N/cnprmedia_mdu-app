import Foundation
import Combine

class NextcloudService: ObservableObject {
    private let baseURL = "http://vpn.privat.krasscrash.ovh"
    
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Anmeldung mit Benutzername und Passwort
    func login(username: String, password: String, completion: @escaping (Result<NextcloudUser, Error>) -> Void) {
        isLoading = true
        error = nil
        
        let url = URL(string: "\(baseURL)/api/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = ["username": username, "password": password]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
        } catch {
            self.error = error
            isLoading = false
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NextcloudResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.isLoading = false
                
                if response.success {
                    if let user = self?.mapResponseToUser(response) {
                        completion(.success(user))
                    } else {
                        let error = NSError(domain: "NextcloudService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fehler beim Verarbeiten der Benutzerdaten"])
                        self?.error = error
                        completion(.failure(error))
                    }
                } else {
                    let message = response.message ?? "Unbekannter Fehler"
                    let error = NSError(domain: "NextcloudService", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
                    self?.error = error
                    completion(.failure(error))
                }
            })
            .store(in: &cancellables)
    }
    
    // Aktualisiere Benutzerdaten mit gespeichertem Passwort
    func refreshUserData(username: String, password: String, completion: @escaping (Result<NextcloudUser, Error>) -> Void) {
        isLoading = true
        error = nil
        
        let url = URL(string: "\(baseURL)/api/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = ["username": username, "password": password]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
        } catch {
            self.error = error
            isLoading = false
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NextcloudResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.isLoading = false
                
                if response.success {
                    if let user = self?.mapResponseToUser(response) {
                        completion(.success(user))
                    } else {
                        let error = NSError(domain: "NextcloudService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Fehler beim Verarbeiten der Benutzerdaten"])
                        self?.error = error
                        completion(.failure(error))
                    }
                } else {
                    let message = response.message ?? "Unbekannter Fehler"
                    let error = NSError(domain: "NextcloudService", code: 4, userInfo: [NSLocalizedDescriptionKey: message])
                    self?.error = error
                    completion(.failure(error))
                }
            })
            .store(in: &cancellables)
    }
    
    // Hole Benutzerdaten aus der Datenbank
    func getUserData(username: String, completion: @escaping (Result<NextcloudUser, Error>) -> Void) {
        isLoading = true
        error = nil
        
        let url = URL(string: "\(baseURL)/api/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["username": username]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            self.error = error
            isLoading = false
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: NextcloudResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isLoading = false
                
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error
                    completion(.failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.isLoading = false
                
                if response.success {
                    if let user = self?.mapResponseToUser(response) {
                        completion(.success(user))
                    } else {
                        let error = NSError(domain: "NextcloudService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Fehler beim Verarbeiten der Benutzerdaten"])
                        self?.error = error
                        completion(.failure(error))
                    }
                } else {
                    let message = response.message ?? "Benutzer nicht gefunden"
                    let error = NSError(domain: "NextcloudService", code: 6, userInfo: [NSLocalizedDescriptionKey: message])
                    self?.error = error
                    completion(.failure(error))
                }
            })
            .store(in: &cancellables)
    }
    
    // Hilfsmethode zum Konvertieren der Antwort in ein Benutzer-Objekt
    private func mapResponseToUser(_ response: NextcloudResponse) -> NextcloudUser? {
        guard let userId = response.userId,
              let username = response.username,
              let firstName = response.firstName,
              let lastName = response.lastName,
              let email = response.email else {
            return nil
        }
        
        return NextcloudUser(
            id: userId,
            username: username,
            firstName: firstName,
            lastName: lastName,
            email: email,
            schoolClass: response.schoolClass,
            webdavUrl: response.webdavUrl
        )
    }
}

// MARK: - Datenmodelle

struct NextcloudUser: Codable, Identifiable {
    let id: Int
    let username: String
    let firstName: String
    let lastName: String
    let email: String
    let schoolClass: String?
    let webdavUrl: String?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
}

struct NextcloudResponse: Codable {
    let success: Bool
    let message: String?
    let userId: Int?
    let username: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let schoolClass: String?
    let webdavUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case userId = "user_id"
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case schoolClass = "school_class"
        case webdavUrl = "webdav_url"
    }
} 