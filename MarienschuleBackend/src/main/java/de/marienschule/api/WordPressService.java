package de.marienschule.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.DeserializationFeature;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@SpringBootApplication
@RestController
@EnableScheduling
@RequestMapping("/api")
public class WordPressService {

    private static final String WORDPRESS_API_URL = "https://marienschule-bielefeld.de/wp-json/wp/v2/posts?_embed&per_page=20";
    private static final String CACHE_DIRECTORY = "cache";
    private static final String ARTICLES_CACHE_FILE = CACHE_DIRECTORY + "/articles.json";
    private static final String IMAGES_DIRECTORY = CACHE_DIRECTORY + "/images";
    private static final int CACHE_EXPIRATION_HOURS = 1;
    
    private final ObjectMapper objectMapper;
    private final Map<Integer, Article> articlesCache = new ConcurrentHashMap<>();
    private LocalDateTime lastCacheUpdate = LocalDateTime.now().minusDays(1);
    
    public WordPressService() {
        objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        
        // Create cache directories if they don't exist
        try {
            Files.createDirectories(Paths.get(CACHE_DIRECTORY));
            Files.createDirectories(Paths.get(IMAGES_DIRECTORY));
            loadCachedArticles();
        } catch (IOException e) {
            System.err.println("Error creating cache directories: " + e.getMessage());
        }
    }
    
    public static void main(String[] args) {
        SpringApplication.run(WordPressService.class, args);
    }
    
    @GetMapping("/articles")
    public ResponseEntity<List<Article>> getArticles() {
        try {
            // Check if cache needs to be refreshed
            if (isCacheExpired()) {
                refreshCache();
            }
            
            List<Article> articles = new ArrayList<>(articlesCache.values());
            articles.sort((a1, a2) -> a2.getDate().compareTo(a1.getDate())); // Sort by date, newest first
            
            return ResponseEntity.ok(articles);
        } catch (Exception e) {
            System.err.println("Error retrieving articles: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    @GetMapping("/articles/{id}")
    public ResponseEntity<Article> getArticleById(@PathVariable int id) {
        // Check if cache needs to be refreshed
        try {
            if (isCacheExpired()) {
                refreshCache();
            }
            
            Article article = articlesCache.get(id);
            if (article != null) {
                return ResponseEntity.ok(article);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            System.err.println("Error retrieving article: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    @GetMapping("/images/{filename}")
    public ResponseEntity<byte[]> getImage(@PathVariable String filename) {
        try {
            Path imagePath = Paths.get(IMAGES_DIRECTORY, filename);
            if (Files.exists(imagePath)) {
                byte[] imageData = Files.readAllBytes(imagePath);
                return ResponseEntity.ok(imageData);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            System.err.println("Error retrieving image: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    @Scheduled(fixedRate = 3600000) // Refresh cache every hour
    public void scheduledCacheRefresh() {
        try {
            refreshCache();
        } catch (Exception e) {
            System.err.println("Scheduled cache refresh failed: " + e.getMessage());
        }
    }
    
    private boolean isCacheExpired() {
        return LocalDateTime.now().isAfter(lastCacheUpdate.plusHours(CACHE_EXPIRATION_HOURS));
    }
    
    private synchronized void refreshCache() throws IOException {
        System.out.println("Refreshing articles cache...");
        
        // Fetch articles from WordPress API
        String jsonResponse = fetchDataFromWordPress(WORDPRESS_API_URL);
        Article[] articles = objectMapper.readValue(jsonResponse, Article[].class);
        
        // Clear existing cache
        articlesCache.clear();
        
        // Process and cache each article
        for (Article article : articles) {
            // Cache the article
            articlesCache.put(article.getId(), article);
            
            // Download and cache featured image if available
            if (article.getFeaturedMediaUrl() != null) {
                String imageFilename = "image_" + article.getId() + ".jpg";
                article.setCachedImagePath("/api/images/" + imageFilename);
                
                // Download image if it doesn't exist
                Path imagePath = Paths.get(IMAGES_DIRECTORY, imageFilename);
                if (!Files.exists(imagePath)) {
                    downloadImage(article.getFeaturedMediaUrl(), imagePath);
                }
            }
        }
        
        // Save articles to cache file
        saveArticlesToCache();
        
        // Update last cache refresh time
        lastCacheUpdate = LocalDateTime.now();
        System.out.println("Cache refreshed successfully. Cached " + articles.length + " articles.");
    }
    
    private void loadCachedArticles() {
        try {
            Path cacheFile = Paths.get(ARTICLES_CACHE_FILE);
            if (Files.exists(cacheFile)) {
                String cachedJson = new String(Files.readAllBytes(cacheFile));
                Article[] articles = objectMapper.readValue(cachedJson, Article[].class);
                
                for (Article article : articles) {
                    articlesCache.put(article.getId(), article);
                }
                
                System.out.println("Loaded " + articlesCache.size() + " articles from cache.");
            }
        } catch (Exception e) {
            System.err.println("Error loading cached articles: " + e.getMessage());
        }
    }
    
    private void saveArticlesToCache() {
        try {
            List<Article> articles = new ArrayList<>(articlesCache.values());
            String json = objectMapper.writeValueAsString(articles);
            Files.write(Paths.get(ARTICLES_CACHE_FILE), json.getBytes());
        } catch (Exception e) {
            System.err.println("Error saving articles to cache: " + e.getMessage());
        }
    }
    
    private String fetchDataFromWordPress(String apiUrl) throws IOException {
        URL url = new URL(apiUrl);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod("GET");
        
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()))) {
            return reader.lines().collect(Collectors.joining());
        } finally {
            connection.disconnect();
        }
    }
    
    private void downloadImage(String imageUrl, Path destination) {
        try {
            URL url = new URL(imageUrl);
            try (InputStream in = url.openStream()) {
                Files.copy(in, destination, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (Exception e) {
            System.err.println("Error downloading image from " + imageUrl + ": " + e.getMessage());
        }
    }
    
    // Article model class
    public static class Article {
        private int id;
        private String date;
        private RenderedContent title;
        private RenderedContent content;
        private RenderedContent excerpt;
        private String link;
        private int featuredMedia;
        private String featuredMediaUrl;
        private String cachedImagePath;
        
        // Getters and setters
        public int getId() { return id; }
        public void setId(int id) { this.id = id; }
        
        public String getDate() { return date; }
        public void setDate(String date) { this.date = date; }
        
        public RenderedContent getTitle() { return title; }
        public void setTitle(RenderedContent title) { this.title = title; }
        
        public RenderedContent getContent() { return content; }
        public void setContent(RenderedContent content) { this.content = content; }
        
        public RenderedContent getExcerpt() { return excerpt; }
        public void setExcerpt(RenderedContent excerpt) { this.excerpt = excerpt; }
        
        public String getLink() { return link; }
        public void setLink(String link) { this.link = link; }
        
        public int getFeaturedMedia() { return featuredMedia; }
        public void setFeaturedMedia(int featuredMedia) { this.featuredMedia = featuredMedia; }
        
        public String getFeaturedMediaUrl() { return featuredMediaUrl; }
        public void setFeaturedMediaUrl(String featuredMediaUrl) { this.featuredMediaUrl = featuredMediaUrl; }
        
        public String getCachedImagePath() { return cachedImagePath; }
        public void setCachedImagePath(String cachedImagePath) { this.cachedImagePath = cachedImagePath; }
    }
    
    // Rendered content model
    public static class RenderedContent {
        private String rendered;
        
        public String getRendered() { return rendered; }
        public void setRendered(String rendered) { this.rendered = rendered; }
    }
} 