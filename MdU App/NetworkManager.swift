import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetchPass(completion: @escaping (Data?) -> Void) {
        // Replace with your server URL
        let urlString = "https://yourserver.com/path/to/your.pkpass"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers if needed
        // request.setValue("Bearer your_token", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching pass: \(error)")
                completion(nil)
                return
            }
            completion(data)
        }
        
        task.resume()
    }
    
    func fetchImage(completion: @escaping (Data?) -> Void) {
        // Replace with your server URL for the image
        let urlString = "https://yourserver.com/path/to/your/image.png"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching image: \(error)")
                    completion(nil)
                    return
                }
                completion(data)
            }
        }
        
        task.resume()
    }
} 