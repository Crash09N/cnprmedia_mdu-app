# Marienschule Bielefeld Backend

This is a Java Spring Boot backend service for the Marienschule Bielefeld app. It fetches WordPress articles from the school's website, caches them locally, and provides them to the app via a REST API.

## Features

- Fetches the latest 20 articles from the Marienschule Bielefeld WordPress site
- Caches articles and images locally for offline access
- Provides a REST API for the app to retrieve articles and images
- Automatically refreshes the cache every hour
- Ensures stability by decoupling the app from direct WordPress API calls

## Requirements

- Java 11 or higher
- Maven 3.6 or higher

## Setup and Running

1. Clone this repository
2. Navigate to the project directory
3. Build the project:
   ```
   mvn clean package
   ```
4. Run the application:
   ```
   java -jar target/marienschule-backend-1.0.0.jar
   ```
   
The server will start on port 8080 by default.

## API Endpoints

- `GET /api/articles` - Get all cached articles (up to 20)
- `GET /api/articles/{id}` - Get a specific article by ID
- `GET /api/images/{filename}` - Get a cached image by filename

## Cache

The application caches data in the following locations:
- Articles: `cache/articles.json`
- Images: `cache/images/`

The cache is refreshed automatically every hour or when it expires (after 1 hour of inactivity).

## Integration with the iOS App

To integrate this backend with your iOS app, update your NetworkManager to point to this backend service instead of directly accessing the WordPress API.

Example Swift code:

```swift
func fetchWordPressArticles(completion: @escaping ([WordPressArticle]?, Error?) -> Void) {
    let urlString = "http://your-server-address:8080/api/articles"
    
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
        return
    }
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        // Process response...
    }
    
    task.resume()
}
``` 