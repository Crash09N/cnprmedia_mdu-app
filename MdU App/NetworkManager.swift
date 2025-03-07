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
    
    // For _links decoding when using direct WordPress API
    struct Links: Codable {
        let featuredMedia: [FeaturedMedia]?
        
        enum CodingKeys: String, CodingKey {
            case featuredMedia = "wp:featuredmedia"
        }
        
        struct FeaturedMedia: Codable {
            let href: String
        }
    }
}

// Media model for featured images
struct WordPressMedia: Codable {
    let id: Int
    let sourceUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case sourceUrl = "source_url"
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    
    // Backend server URL - replace with your actual server address when deployed
    private let backendBaseURL = "http://localhost:8080/api"
    
    // Direct WordPress API URL as fallback
    private let wordpressAPIURL = "https://marienschule-bielefeld.de/wp-json/wp/v2/posts?_embed=true&per_page=20&context=view"
    
    // Local cache for articles
    private var cachedArticles: [WordPressArticle] = []
    private var lastCacheUpdate: Date? = nil
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    
    // Flag to track if we're using the backend or direct API
    private var usingBackend = true
    
    private init() {
        // Load cached articles from UserDefaults if available
        loadCachedArticles()
    }
    
    func fetchWordPressArticles(completion: @escaping ([WordPressArticle]?, Error?) -> Void) {
        // Check if cache is valid
        if let lastUpdate = lastCacheUpdate, 
           Date().timeIntervalSince(lastUpdate) < cacheExpirationInterval,
           !cachedArticles.isEmpty {
            // Return cached articles
            print("DEBUG: Using cached articles. Last update: \(lastUpdate)")
            completion(cachedArticles, nil)
            return
        }
        
        // Try to fetch from backend first
        fetchFromBackend { [weak self] articles, error in
            guard let self = self else { return }
            
            if let articles = articles {
                // Backend successful
                self.usingBackend = true
                print("DEBUG: Successfully fetched articles from backend server")
                completion(articles, nil)
            } else {
                // Backend failed, try direct WordPress API
                print("DEBUG: Backend server not available. Falling back to direct WordPress API")
                self.usingBackend = false
                self.fetchDirectFromWordPress(completion: completion)
            }
        }
    }
    
    private func fetchFromBackend(completion: @escaping ([WordPressArticle]?, Error?) -> Void) {
        let urlString = "\(backendBaseURL)/articles"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }
        
        // Create a URLRequest with a timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0 // 5 second timeout to quickly detect if backend is offline
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Check for timeout or connection error
            if let error = error {
                print("DEBUG: Backend connection failed: \(error.localizedDescription)")
                self.usingBackend = false
                completion(nil, error)
                return
            }
            
            // Check for HTTP status code
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("DEBUG: Backend returned error status code: \(httpResponse.statusCode)")
                self.usingBackend = false
                completion(nil, NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil))
                return
            }
            
            guard let data = data else {
                print("DEBUG: No data received from backend")
                self.usingBackend = false
                completion(nil, NSError(domain: "No data received", code: 0, userInfo: nil))
                return
            }
            
            do {
                let articles = try JSONDecoder().decode([WordPressArticle].self, from: data)
                
                // Update cache
                self.cachedArticles = articles
                self.lastCacheUpdate = Date()
                self.saveCachedArticles()
                
                // Backend is working
                self.usingBackend = true
                
                DispatchQueue.main.async {
                    completion(articles, nil)
                }
            } catch {
                print("DEBUG: Error decoding backend response: \(error)")
                self.usingBackend = false
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    private func fetchDirectFromWordPress(completion: @escaping ([WordPressArticle]?, Error?) -> Void) {
        // Add parameters to ensure we get full content without any filtering
        let fullContentURL = wordpressAPIURL + "&_fields=id,date,title,content,excerpt,link,featured_media,_links,_embedded"
        
        guard let url = URL(string: fullContentURL) else {
            completion(nil, NSError(domain: "Invalid WordPress API URL", code: 0, userInfo: nil))
            return
        }
        
        // Create a request with increased timeout for potentially large content
        var request = URLRequest(url: url)
        request.timeoutInterval = 120.0 // 2 minutes to allow for very large content
        request.cachePolicy = .reloadIgnoringLocalCacheData // Force fresh content
        
        print("DEBUG: Fetching WordPress content from URL: \(fullContentURL)")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("DEBUG: Error fetching WordPress content: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // If network error, try to use cached articles if available
                    if !self.cachedArticles.isEmpty {
                        print("DEBUG: Network error, using cached articles")
                        completion(self.cachedArticles, nil)
                    } else {
                        completion(nil, error)
                    }
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: WordPress API response status code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("DEBUG: No data received from WordPress API")
                DispatchQueue.main.async {
                    if !self.cachedArticles.isEmpty {
                        completion(self.cachedArticles, nil)
                    } else {
                        completion(nil, NSError(domain: "No data received", code: 0, userInfo: nil))
                    }
                }
                return
            }
            
            // Print the raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("DEBUG: First 500 chars of WordPress response: \(String(responseString.prefix(500)))")
            }
            
            do {
                // Parse the WordPress API response
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                
                var articles: [WordPressArticle] = []
                
                for articleJson in jsonObject ?? [] {
                    if let id = articleJson["id"] as? Int,
                       let date = articleJson["date"] as? String,
                       let titleDict = articleJson["title"] as? [String: Any],
                       let titleRendered = titleDict["rendered"] as? String,
                       let contentDict = articleJson["content"] as? [String: Any],
                       let contentRendered = contentDict["rendered"] as? String,
                       let excerptDict = articleJson["excerpt"] as? [String: Any],
                       let excerptRendered = excerptDict["rendered"] as? String,
                       let link = articleJson["link"] as? String {
                        
                        let featuredMedia = articleJson["featured_media"] as? Int
                        
                        // Extract featured media URL from _embedded data
                        var featuredMediaURL: String? = nil
                        if let embedded = articleJson["_embedded"] as? [String: Any],
                           let mediaArray = embedded["wp:featuredmedia"] as? [[String: Any]],
                           let firstMedia = mediaArray.first,
                           let sourceURL = firstMedia["source_url"] as? String {
                            featuredMediaURL = sourceURL
                        }
                        
                        // Process the content to ensure it's complete
                        let processedContent = self.processWordPressContent(contentRendered)
                        
                        print("DEBUG: Article ID \(id) content length: \(processedContent.count) characters")
                        
                        let title = WordPressArticle.RenderedContent(rendered: titleRendered)
                        let content = WordPressArticle.RenderedContent(rendered: processedContent)
                        let excerpt = WordPressArticle.RenderedContent(rendered: excerptRendered)
                        
                        let article = WordPressArticle(
                            id: id,
                            date: date,
                            title: title,
                            content: content,
                            excerpt: excerpt,
                            link: link,
                            featuredMedia: featuredMedia,
                            cachedImagePath: nil,
                            featuredMediaURL: featuredMediaURL
                        )
                        
                        articles.append(article)
                    }
                }
                
                // Update cache
                self.cachedArticles = articles
                self.lastCacheUpdate = Date()
                self.saveCachedArticles()
                
                DispatchQueue.main.async {
                    completion(articles, nil)
                }
            } catch {
                print("DEBUG: Error parsing WordPress API response: \(error)")
                DispatchQueue.main.async {
                    if !self.cachedArticles.isEmpty {
                        completion(self.cachedArticles, nil)
                    } else {
                        completion(nil, error)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    // Helper method to process WordPress content
    private func processWordPressContent(_ content: String) -> String {
        // Remove any truncation markers that WordPress might add
        var processedContent = content
        
        // Replace any "[&hellip;]" or similar truncation markers
        processedContent = processedContent.replacingOccurrences(of: "\\[&hellip;\\]", with: "", options: .regularExpression)
        
        // Fix any incomplete HTML tags
        if !processedContent.contains("</p>") && processedContent.contains("<p>") {
            processedContent += "</p>"
        }
        
        // Fix WordPress "read more" links
        processedContent = processedContent.replacingOccurrences(
            of: "<a class=\"more-link\"[^>]*>.*?</a>",
            with: "",
            options: .regularExpression
        )
        
        // Fix WordPress protected content placeholders
        processedContent = processedContent.replacingOccurrences(
            of: "\\(Passwortgeschützer Inhalt\\)",
            with: "",
            options: .regularExpression
        )
        
        // Fix WordPress excerpt ellipsis
        processedContent = processedContent.replacingOccurrences(
            of: "&hellip;",
            with: "...",
            options: .regularExpression
        )
        
        // Remove any WordPress shortcodes that might be causing issues
        processedContent = processedContent.replacingOccurrences(
            of: "\\[\\/?[^\\]]+\\]",
            with: "",
            options: .regularExpression
        )
        
        // Fix WordPress "Continue reading" links
        processedContent = processedContent.replacingOccurrences(
            of: "<span id=\"more-[0-9]+\"></span>",
            with: "",
            options: .regularExpression
        )
        
        // Fix WordPress pagination
        processedContent = processedContent.replacingOccurrences(
            of: "<!--nextpage-->",
            with: "",
            options: .regularExpression
        )
        
        // Fix WordPress image sizing issues
        processedContent = processedContent.replacingOccurrences(
            of: "width=\"[0-9]+\"",
            with: "width=\"100%\"",
            options: .regularExpression
        )
        
        processedContent = processedContent.replacingOccurrences(
            of: "height=\"[0-9]+\"",
            with: "height=\"auto\"",
            options: .regularExpression
        )
        
        // Fix WordPress iframes
        processedContent = processedContent.replacingOccurrences(
            of: "<iframe([^>]+)>",
            with: "<iframe$1 width=\"100%\" frameborder=\"0\" allowfullscreen>",
            options: .regularExpression
        )
        
        return processedContent
    }
    
    func fetchImage(for article: WordPressArticle, completion: @escaping (Data?, Error?) -> Void) {
        // First check if we have a cached image locally
        if let cachedImageData = getCachedImage(for: article.id) {
            completion(cachedImageData, nil)
            return
        }
        
        if usingBackend {
            // Using backend - fetch from backend API
            fetchImageFromBackend(for: article, completion: completion)
        } else {
            // Using direct API - fetch from WordPress
            fetchImageDirectFromWordPress(for: article, completion: completion)
        }
    }
    
    private func fetchImageFromBackend(for article: WordPressArticle, completion: @escaping (Data?, Error?) -> Void) {
        guard let imagePath = article.cachedImagePath else {
            completion(nil, NSError(domain: "No image path available", code: 0, userInfo: nil))
            return
        }
        
        // Construct full URL to the image
        let urlString = backendBaseURL + imagePath
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid image URL", code: 0, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "No image data received", code: 0, userInfo: nil))
                    return
                }
                
                // Cache the image data locally
                self.saveImageToCache(data: data, for: article.id)
                
                completion(data, nil)
            }
        }
        
        task.resume()
    }
    
    private func fetchImageDirectFromWordPress(for article: WordPressArticle, completion: @escaping (Data?, Error?) -> Void) {
        // Try to get the featured media URL
        guard let imageURL = article.featuredMediaURL else {
            // If no direct URL, try to fetch it using the media ID
            if let mediaId = article.featuredMedia, mediaId > 0 {
                fetchFeaturedMediaURL(for: mediaId) { [weak self] url, error in
                    guard let self = self else { return }
                    
                    if let url = url {
                        self.downloadImage(from: url) { data, error in
                            if let data = data {
                                self.saveImageToCache(data: data, for: article.id)
                            }
                            completion(data, error)
                        }
                    } else {
                        completion(nil, error ?? NSError(domain: "Failed to get media URL", code: 0, userInfo: nil))
                    }
                }
            } else {
                completion(nil, NSError(domain: "No featured media available", code: 0, userInfo: nil))
            }
            return
        }
        
        // If we have a direct URL, download the image
        downloadImage(from: imageURL) { [weak self] data, error in
            guard let self = self else { return }
            
            if let data = data {
                self.saveImageToCache(data: data, for: article.id)
            }
            completion(data, error)
        }
    }
    
    private func fetchFeaturedMediaURL(for mediaId: Int, completion: @escaping (String?, Error?) -> Void) {
        let urlString = "https://marienschule-bielefeld.de/wp-json/wp/v2/media/\(mediaId)"
        
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid media URL", code: 0, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "No media data received", code: 0, userInfo: nil))
                }
                return
            }
            
            do {
                let media = try JSONDecoder().decode(WordPressMedia.self, from: data)
                DispatchQueue.main.async {
                    completion(media.sourceUrl, nil)
                }
            } catch {
                print("DEBUG: Error decoding media: \(error)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    private func downloadImage(from urlString: String, completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid image URL", code: 0, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "No image data received", code: 0, userInfo: nil))
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
        return usingBackend
    }
    
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