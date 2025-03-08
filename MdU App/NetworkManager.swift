import Foundation

// WordPress Article Models
struct WordPressArticle: Identifiable, Codable {
    let id: Int
    let date: String
    let title: RenderedContent
    let content: RenderedContent
    let excerpt: RenderedContent
    let link: String
    let featuredMedia: Int?
    let cachedImagePath: String?
    let featuredMediaURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, date, title, content, excerpt, link, featuredMedia, cachedImagePath, featuredMediaURL
    }
    
    struct RenderedContent: Codable {
        let rendered: String
        
        // Convert HTML to plain text
        var plainText: String {
            rendered.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        }
    }
}

// Server status model
struct ServerStatus: Codable {
    enum Status: String, Codable {
        case online = "ONLINE"
        case offline = "OFFLINE"
        case wordpressOffline = "WORDPRESS_OFFLINE"
        case starting = "STARTING"
        case error = "ERROR"
    }
    
    let status: Status
    let message: String
    let lastUpdate: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case lastUpdate = "lastUpdateFormatted"
    }
}

// API response wrapper
struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
}

class NetworkManager {
    static let shared = NetworkManager()
    
    // Backend server URL - replace with your actual server address when deployed
    private let backendBaseURL = "http://vpn.privat.krasscrash.ovh:8080/api"
    
    // Local cache for articles
    private var cachedArticles: [WordPressArticle] = []
    private var lastCacheUpdate: Date? = nil
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    
    // Server status
    private var serverStatus: ServerStatus?
    
    // Network session for better control
    private let session: URLSession
    
    private init() {
        // Configure URLSession with better caching and timeout settings
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        configuration.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: "articles_cache")
        self.session = URLSession(configuration: configuration)
        
        // Load cached articles from UserDefaults if available
        loadCachedArticles()
    }
    
    func fetchServerStatus(completion: @escaping (ServerStatus?, Error?) -> Void) {
        let urlString = "\(backendBaseURL)/status"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige Server-URL"]))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine Daten vom Server erhalten"]))
                }
                return
            }
            
            do {
                let status = try JSONDecoder().decode(ServerStatus.self, from: data)
                self.serverStatus = status
                
                DispatchQueue.main.async {
                    completion(status, nil)
                }
            } catch {
                print("DEBUG: Error decoding server status: \(error)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    func fetchWordPressArticles(completion: @escaping ([WordPressArticle]?, Error?) -> Void) {
        // CACHE VORÜBERGEHEND DEAKTIVIERT
        // Ursprünglicher Code:
        /*
        // Check if cache is valid and not empty
        if let lastUpdate = lastCacheUpdate, 
           Date().timeIntervalSince(lastUpdate) < cacheExpirationInterval,
           !cachedArticles.isEmpty {
            // Return cached articles immediately
            print("DEBUG: Using cached articles. Last update: \(lastUpdate)")
            DispatchQueue.main.async {
                completion(self.cachedArticles, nil)
            }
            
            // Refresh cache in background if it's older than 15 minutes
            if Date().timeIntervalSince(lastUpdate) > 900 {
                refreshCacheInBackground()
            }
            return
        }
        */
        
        // Fetch articles from backend server
        fetchArticlesFromBackend { result in
            switch result {
            case .success(let articles):
                // Update cache
                self.updateCache(with: articles)
                
                DispatchQueue.main.async {
                    completion(articles, nil)
                }
                
            case .failure(let error):
                print("DEBUG: Backend server error: \(error.localizedDescription)")
                
                // CACHE FALLBACK VORÜBERGEHEND DEAKTIVIERT
                // Ursprünglicher Code:
                /*
                // If backend server failed, try to use cached articles if available
                if !self.cachedArticles.isEmpty {
                    print("DEBUG: Using cached articles as fallback after server failure")
                    DispatchQueue.main.async {
                        completion(self.cachedArticles, nil)
                    }
                } else {
                */
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                //}
            }
        }
    }
    
    private func refreshCacheInBackground() {
        fetchArticlesFromBackend { result in
            if case .success(let articles) = result {
                self.updateCache(with: articles)
                print("DEBUG: Background cache refresh completed with \(articles.count) articles")
            }
        }
    }
    
    private func updateCache(with articles: [WordPressArticle]) {
        self.cachedArticles = articles
        self.lastCacheUpdate = Date()
        self.saveCachedArticles()
    }
    
    private func fetchArticlesFromBackend(completion: @escaping (Result<[WordPressArticle], Error>) -> Void) {
        let urlString = "\(backendBaseURL)/articles"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige Backend-URL"])))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            // Handle network errors
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check for HTTP status code
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(NSError(domain: "NetworkManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP-Fehler: \(httpResponse.statusCode)"])))
                return
            }
            
            // Check for valid data
            guard let data = data else {
                completion(.failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine Daten vom Backend erhalten"])))
                return
            }
            
            // Parse data
            do {
                let apiResponse = try JSONDecoder().decode(ApiResponse<[WordPressArticle]>.self, from: data)
                
                if apiResponse.success, let articles = apiResponse.data {
                    completion(.success(articles))
                } else {
                    let errorMessage = apiResponse.message
                    completion(.failure(NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                }
            } catch {
                print("DEBUG: JSON decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func fetchArticleById(id: Int, completion: @escaping (WordPressArticle?, Error?) -> Void) {
        let urlString = "\(backendBaseURL)/articles/\(id)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige Artikel-URL"]))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine Daten vom Server erhalten"]))
                }
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(ApiResponse<WordPressArticle>.self, from: data)
                
                if apiResponse.success, let article = apiResponse.data {
                    DispatchQueue.main.async {
                        completion(article, nil)
                    }
                } else {
                    let errorMessage = apiResponse.message
                    DispatchQueue.main.async {
                        completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                    }
                }
            } catch {
                print("DEBUG: Error decoding article: \(error)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    func fetchImage(for article: WordPressArticle, completion: @escaping (Data?, Error?) -> Void) {
        // BILD-CACHE VORÜBERGEHEND DEAKTIVIERT
        // Ursprünglicher Code:
        /*
        // First check if we have a cached image locally
        if let cachedImageData = getCachedImage(for: article.id) {
            completion(cachedImageData, nil)
            return
        }
        */
        
        // If no cached image, try to fetch from server
        if let cachedImagePath = article.cachedImagePath {
            fetchImageFromBackend(path: cachedImagePath, articleId: article.id, completion: completion)
        } else if let featuredMediaURL = article.featuredMediaURL {
            // Fallback to direct URL if available
            downloadImage(from: featuredMediaURL) { data, error in
                if let data = data {
                    // CACHE-SPEICHERUNG VORÜBERGEHEND DEAKTIVIERT
                    // self.saveImageToCache(data: data, for: article.id)
                }
                completion(data, error)
            }
        } else {
            completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Kein Bild verfügbar"]))
        }
    }
    
    private func fetchImageFromBackend(path: String, articleId: Int, completion: @escaping (Data?, Error?) -> Void) {
        // Construct full URL to the image
        let urlString: String
        if path.starts(with: "/") {
            // If path starts with /, it's a relative path to the backend base URL
            urlString = backendBaseURL + path
        } else {
            // Otherwise, it's a full URL
            urlString = path
        }
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige Bild-URL"]))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine Bilddaten erhalten"]))
                    return
                }
                
                // CACHE-SPEICHERUNG VORÜBERGEHEND DEAKTIVIERT
                // Cache the image data locally
                // self.saveImageToCache(data: data, for: articleId)
                
                completion(data, nil)
            }
        }
        
        task.resume()
    }
    
    private func downloadImage(from urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige Bild-URL"]))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine Bilddaten erhalten"]))
                    return
                }
                
                completion(data, nil)
            }
        }
        
        task.resume()
    }
    
    // MARK: - Local Caching
    
    private func loadCachedArticles() {
        if let data = UserDefaults.standard.data(forKey: "cachedArticles") {
            do {
                cachedArticles = try JSONDecoder().decode([WordPressArticle].self, from: data)
                lastCacheUpdate = UserDefaults.standard.object(forKey: "lastCacheUpdate") as? Date
                print("DEBUG: Loaded \(cachedArticles.count) articles from local cache")
            } catch {
                print("DEBUG: Error loading cached articles: \(error)")
            }
        }
    }
    
    private func saveCachedArticles() {
        do {
            let data = try JSONEncoder().encode(cachedArticles)
            UserDefaults.standard.set(data, forKey: "cachedArticles")
            UserDefaults.standard.set(lastCacheUpdate, forKey: "lastCacheUpdate")
        } catch {
            print("DEBUG: Error saving articles to cache: \(error)")
        }
    }
    
    private func saveImageToCache(data: Data, for articleId: Int) {
        let fileManager = FileManager.default
        
        // Get the documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        // Create images directory if it doesn't exist
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                print("DEBUG: Error creating images directory: \(error)")
                return
            }
        }
        
        // Save the image
        let imagePath = imagesDirectory.appendingPathComponent("article_\(articleId).jpg")
        do {
            try data.write(to: imagePath)
        } catch {
            print("DEBUG: Error saving image to cache: \(error)")
        }
    }
    
    func getCachedImage(for articleId: Int) -> Data? {
        let fileManager = FileManager.default
        
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let imagePath = documentsDirectory.appendingPathComponent("images/article_\(articleId).jpg")
        
        return try? Data(contentsOf: imagePath)
    }
    
    func isUsingBackend() -> Bool {
        return true // Always true now since we only use the backend
    }
    
    // MARK: - Student ID Pass
    
    func fetchPass(completion: @escaping (Data?, Error?) -> Void) {
        let urlString = "\(backendBaseURL)/studentpass"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ungültige Pass-URL"]))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "NetworkManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Keine Pass-Daten erhalten"]))
                    return
                }
                
                completion(data, nil)
            }
        }
        
        task.resume()
    }
} 
