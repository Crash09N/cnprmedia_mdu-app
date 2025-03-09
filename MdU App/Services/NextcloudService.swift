import Foundation
import Combine

class NextcloudService: ObservableObject {
    private let baseURL = "http://vpn.privat.krasscrash.ovh:8080"
    
    @Published var isLoading = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Überprüfe, ob der Server erreichbar ist
    func checkServerStatus(completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "\(baseURL)/nextcloud/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("DEBUG: Checking server status at \(url)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DEBUG: Server status check failed with error: \(error)")
                    completion(false, "Netzwerkfehler: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("DEBUG: Invalid response during server status check")
                    completion(false, "Ungültige Serverantwort")
                    return
                }
                
                print("DEBUG: Server status response code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    completion(true, nil)
                } else {
                    var message = "Server nicht erreichbar (Status \(httpResponse.statusCode))"
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("DEBUG: Server status response: \(responseString)")
                        message = "Server-Fehler: \(responseString)"
                    }
                    
                    completion(false, message)
                }
            }
        }.resume()
    }
    
    // Anmeldung mit Benutzername und Passwort
    func login(username: String, password: String, completion: @escaping (Result<NextcloudUser, Error>) -> Void) {
        // Überprüfe zuerst den Server-Status
        checkServerStatus { isAvailable, errorMessage in
            if !isAvailable {
                let error = NSError(domain: "NextcloudService", code: 8, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? "Server nicht erreichbar"])
                print("DEBUG: Server not available: \(errorMessage ?? "Unknown error")")
                self.error = error
                completion(.failure(error))
                return
            }
            
            // Fahre mit der Anmeldung fort, wenn der Server erreichbar ist
            self.isLoading = true
            self.error = nil
            
            let url = URL(string: "\(self.baseURL)/api/login")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let credentials = ["username": username, "password": password]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: credentials)
                print("DEBUG: Sending request to \(url) with credentials: \(credentials)")
            } catch {
                self.error = error
                self.isLoading = false
                print("DEBUG: Error serializing credentials: \(error)")
                completion(.failure(error))
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("DEBUG: Network error: \(error)")
                        self.error = error
                        completion(.failure(error))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        let error = NSError(domain: "NextcloudService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                        print("DEBUG: Invalid response: \(response.debugDescription)")
                        self.error = error
                        completion(.failure(error))
                        return
                    }
                    
                    print("DEBUG: Response status code: \(httpResponse.statusCode)")
                    print("DEBUG: Response headers: \(httpResponse.allHeaderFields)")
                    
                    guard let data = data else {
                        let error = NSError(domain: "NextcloudService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                        print("DEBUG: No data received")
                        self.error = error
                        completion(.failure(error))
                        return
                    }
                    
                    // Print raw response data
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("DEBUG: Raw response: \(responseString)")
                        
                        // Versuche, die Antwort als JSON zu parsen und auszugeben
                        do {
                            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                print("DEBUG: JSON structure: \(jsonObject.keys)")
                                
                                // Überprüfe, ob die erwarteten Felder vorhanden sind
                                print("DEBUG: Has 'success' field: \(jsonObject["success"] != nil)")
                                print("DEBUG: Has 'user_id' field: \(jsonObject["user_id"] != nil)")
                                print("DEBUG: Has 'username' field: \(jsonObject["username"] != nil)")
                            }
                        } catch {
                            print("DEBUG: Could not parse response as JSON: \(error)")
                        }
                    }
                    
                    do {
                        let response = try JSONDecoder().decode(NextcloudResponse.self, from: data)
                        
                        if response.success {
                            if let user = self.mapResponseToUser(response) {
                                print("DEBUG: Successfully mapped user: \(user)")
                                completion(.success(user))
                            } else {
                                let error = NSError(domain: "NextcloudService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fehler beim Verarbeiten der Benutzerdaten"])
                                print("DEBUG: Failed to map user from response")
                                self.error = error
                                completion(.failure(error))
                            }
                        } else {
                            let message = response.message ?? "Unbekannter Fehler"
                            let error = NSError(domain: "NextcloudService", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
                            print("DEBUG: Server returned error: \(message)")
                            self.error = error
                            completion(.failure(error))
                        }
                    } catch {
                        print("DEBUG: JSON decoding error: \(error)")
                        
                        // Versuche, die Antwort als HTML zu interpretieren
                        if let responseString = String(data: data, encoding: .utf8), 
                           responseString.contains("<!DOCTYPE html>") || responseString.contains("<html") {
                            print("DEBUG: Server returned HTML instead of JSON. This might be an error page.")
                            let error = NSError(domain: "NextcloudService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Server returned HTML instead of JSON"])
                            self.error = error
                            completion(.failure(error))
                            return
                        }
                        
                        self.error = error
                        completion(.failure(error))
                    }
                }
            }.resume()
        }
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
            print("DEBUG: Sending refresh request to \(url) with username: \(username)")
        } catch {
            self.error = error
            isLoading = false
            print("DEBUG: Error serializing refresh credentials: \(error)")
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("DEBUG: Refresh network error: \(error)")
                    self.error = error
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = NSError(domain: "NextcloudService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    print("DEBUG: Invalid refresh response: \(response.debugDescription)")
                    self.error = error
                    completion(.failure(error))
                    return
                }
                
                print("DEBUG: Refresh response status code: \(httpResponse.statusCode)")
                print("DEBUG: Refresh response headers: \(httpResponse.allHeaderFields)")
                
                guard let data = data else {
                    let error = NSError(domain: "NextcloudService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    print("DEBUG: No data received for refresh")
                    self.error = error
                    completion(.failure(error))
                    return
                }
                
                // Print raw response data
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Raw refresh response: \(responseString)")
                    
                    // Versuche, die Antwort als JSON zu parsen und auszugeben
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("DEBUG: Refresh JSON structure: \(jsonObject.keys)")
                            
                            // Überprüfe, ob die erwarteten Felder vorhanden sind
                            print("DEBUG: Refresh has 'success' field: \(jsonObject["success"] != nil)")
                            print("DEBUG: Refresh has 'user_id' field: \(jsonObject["user_id"] != nil)")
                            print("DEBUG: Refresh has 'username' field: \(jsonObject["username"] != nil)")
                        }
                    } catch {
                        print("DEBUG: Could not parse refresh response as JSON: \(error)")
                    }
                }
                
                do {
                    let response = try JSONDecoder().decode(NextcloudResponse.self, from: data)
                    
                    if response.success {
                        if let user = self.mapResponseToUser(response) {
                            print("DEBUG: Successfully refreshed user: \(user)")
                            completion(.success(user))
                        } else {
                            let error = NSError(domain: "NextcloudService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Fehler beim Verarbeiten der Benutzerdaten"])
                            print("DEBUG: Failed to map refreshed user")
                            self.error = error
                            completion(.failure(error))
                        }
                    } else {
                        let message = response.message ?? "Unbekannter Fehler"
                        let error = NSError(domain: "NextcloudService", code: 4, userInfo: [NSLocalizedDescriptionKey: message])
                        print("DEBUG: Server returned refresh error: \(message)")
                        self.error = error
                        completion(.failure(error))
                    }
                } catch {
                    print("DEBUG: Refresh JSON decoding error: \(error)")
                    
                    // Versuche, die Antwort als HTML zu interpretieren
                    if let responseString = String(data: data, encoding: .utf8), 
                       responseString.contains("<!DOCTYPE html>") || responseString.contains("<html") {
                        print("DEBUG: Server returned HTML instead of JSON for refresh. This might be an error page.")
                        let error = NSError(domain: "NextcloudService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Server returned HTML instead of JSON"])
                        self.error = error
                        completion(.failure(error))
                        return
                    }
                    
                    self.error = error
                    completion(.failure(error))
                }
            }
        }.resume()
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
            print("DEBUG: Missing required user fields in response. userId: \(response.userId != nil), username: \(response.username != nil), firstName: \(response.firstName != nil), lastName: \(response.lastName != nil), email: \(response.email != nil)")
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Versuche success als Bool zu dekodieren, falls nicht möglich, setze auf false
        do {
            success = try container.decode(Bool.self, forKey: .success)
        } catch {
            print("DEBUG: Error decoding 'success' field: \(error)")
            success = false
        }
        
        // Dekodiere optionale Felder
        message = try? container.decode(String.self, forKey: .message)
        
        // Versuche userId als Int zu dekodieren
        if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = Int(userIdString)
        } else {
            userId = try? container.decode(Int.self, forKey: .userId)
        }
        
        username = try? container.decode(String.self, forKey: .username)
        firstName = try? container.decode(String.self, forKey: .firstName)
        lastName = try? container.decode(String.self, forKey: .lastName)
        email = try? container.decode(String.self, forKey: .email)
        schoolClass = try? container.decode(String.self, forKey: .schoolClass)
        webdavUrl = try? container.decode(String.self, forKey: .webdavUrl)
    }
} 