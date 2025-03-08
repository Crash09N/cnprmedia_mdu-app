package de.marienschule.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.web.bind.annotation.*;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.SocketTimeoutException;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@RestController
@EnableScheduling
@RequestMapping("/api")
public class WordPressService {

    private static final String WORDPRESS_API_URL = "https://marienschule-bielefeld.de/wp-json/wp/v2/posts?_embed&per_page=20";
    private static final String CACHE_DIRECTORY = "cache";
    private static final String ARTICLES_CACHE_FILE = CACHE_DIRECTORY + "/articles.json";
    private static final String ARTICLES_DIRECTORY = CACHE_DIRECTORY + "/articles";
    private static final String IMAGES_DIRECTORY = CACHE_DIRECTORY + "/images";
    private static final String SERVER_STATUS_FILE = CACHE_DIRECTORY + "/server_status.json";
    private static final int CACHE_EXPIRATION_HOURS = 1;
    private static final int CONNECTION_TIMEOUT = 10000; // 10 seconds
    private static final int READ_TIMEOUT = 30000; // 30 seconds
    
    private final ObjectMapper objectMapper;
    private final Map<Integer, Article> articlesCache = new ConcurrentHashMap<>();
    private LocalDateTime lastCacheUpdate = LocalDateTime.now().minusDays(1);
    private ServerStatus serverStatus = new ServerStatus();
    
    public WordPressService() {
        objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        objectMapper.registerModule(new JavaTimeModule());
        
        // Create cache directories if they don't exist
        try {
            Files.createDirectories(Paths.get(CACHE_DIRECTORY));
            Files.createDirectories(Paths.get(ARTICLES_DIRECTORY));
            Files.createDirectories(Paths.get(IMAGES_DIRECTORY));
            loadCachedArticles();
            loadServerStatus();
        } catch (IOException e) {
            System.err.println("Error creating cache directories: " + e.getMessage());
            serverStatus.setStatus(ServerStatus.Status.ERROR);
            serverStatus.setMessage("Fehler beim Initialisieren des Caches: " + e.getMessage());
            saveServerStatus();
        }
    }
    
    @GetMapping("/status")
    public ResponseEntity<ServerStatus> getServerStatus() {
        // Update the last update time
        serverStatus.setLastUpdate(LocalDateTime.now());
        return ResponseEntity.ok(serverStatus);
    }
    
    @GetMapping("/articles")
    public ResponseEntity<ApiResponse<List<Article>>> getArticles() {
        try {
            // Check if cache needs to be refreshed
            if (isCacheExpired()) {
                try {
                    refreshCache();
                } catch (Exception e) {
                    // If refresh fails but we have cached articles, continue with cached data
                    if (articlesCache.isEmpty()) {
                        throw e; // Re-throw if we don't have cached data
                    }
                    // Otherwise, log the error but continue with cached data
                    System.err.println("Warning: Using cached articles because refresh failed: " + e.getMessage());
                }
            }
            
            if (articlesCache.isEmpty()) {
                return ResponseEntity.ok(new ApiResponse<>(
                    false, 
                    "Keine Artikel verfügbar. Die Schul-Website könnte offline sein.",
                    null
                ));
            }
            
            List<Article> articles = new ArrayList<>(articlesCache.values());
            articles.sort((a1, a2) -> a2.getDate().compareTo(a1.getDate())); // Sort by date, newest first
            
            return ResponseEntity.ok(new ApiResponse<>(true, "Artikel erfolgreich geladen", articles));
        } catch (Exception e) {
            System.err.println("Error retrieving articles: " + e.getMessage());
            e.printStackTrace();
            
            // Return a proper error response
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiResponse<>(
                    false, 
                    "Fehler beim Laden der Artikel: " + e.getMessage(),
                    null
                ));
        }
    }
    
    @GetMapping("/articles/{id}")
    public ResponseEntity<ApiResponse<Article>> getArticleById(@PathVariable int id) {
        try {
            // Versuche zuerst, den Artikel aus dem Cache zu holen
            Article article = articlesCache.get(id);
            
            // Wenn der Artikel nicht im Cache ist, versuche ihn direkt aus der Datei zu laden
            if (article == null) {
                Path articleFile = Paths.get(ARTICLES_DIRECTORY, "article_" + id + ".json");
                if (Files.exists(articleFile)) {
                    try {
                        String articleJson = new String(Files.readAllBytes(articleFile));
                        article = objectMapper.readValue(articleJson, Article.class);
                        // Füge den Artikel zum Cache hinzu
                        articlesCache.put(id, article);
                    } catch (Exception e) {
                        System.err.println("Error loading article from file: " + e.getMessage());
                    }
                }
            }
            
            // Wenn der Artikel immer noch nicht gefunden wurde und der Cache abgelaufen ist, aktualisiere den Cache
            if (article == null && isCacheExpired()) {
                try {
                    refreshCache();
                    // Versuche erneut, den Artikel aus dem Cache zu holen
                    article = articlesCache.get(id);
                } catch (Exception e) {
                    System.err.println("Warning: Cache refresh failed: " + e.getMessage());
                }
            }
            
            if (article != null) {
                return ResponseEntity.ok(new ApiResponse<>(true, "Artikel erfolgreich geladen", article));
            } else {
                return ResponseEntity
                    .status(HttpStatus.NOT_FOUND)
                    .body(new ApiResponse<>(false, "Artikel nicht gefunden", null));
            }
        } catch (Exception e) {
            System.err.println("Error retrieving article: " + e.getMessage());
            e.printStackTrace();
            
            return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiResponse<>(
                    false, 
                    "Fehler beim Laden des Artikels: " + e.getMessage(),
                    null
                ));
        }
    }
    
    @GetMapping(value = "/images/{filename}", produces = MediaType.IMAGE_JPEG_VALUE)
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
            serverStatus.setStatus(ServerStatus.Status.ONLINE);
            serverStatus.setMessage("Server online, letzte Aktualisierung: " + 
                DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss").format(lastCacheUpdate));
            serverStatus.setLastUpdate(lastCacheUpdate);
            saveServerStatus();
        } catch (Exception e) {
            System.err.println("Scheduled cache refresh failed: " + e.getMessage());
            e.printStackTrace();
            
            // Update server status to indicate the WordPress site is offline
            if (e instanceof SocketTimeoutException || e.getMessage().contains("Connection")) {
                serverStatus.setStatus(ServerStatus.Status.WORDPRESS_OFFLINE);
                serverStatus.setMessage("Die Schul-Website ist nicht erreichbar. Verwende zwischengespeicherte Daten.");
            } else {
                serverStatus.setStatus(ServerStatus.Status.ERROR);
                serverStatus.setMessage("Fehler beim Aktualisieren der Daten: " + e.getMessage());
            }
            saveServerStatus();
        }
    }
    
    private boolean isCacheExpired() {
        return LocalDateTime.now().isAfter(lastCacheUpdate.plusHours(CACHE_EXPIRATION_HOURS));
    }
    
    private synchronized void refreshCache() throws IOException {
        System.out.println("Refreshing articles cache...");
        
        try {
            // Fetch articles from WordPress API
            String jsonResponse = fetchDataFromWordPress(WORDPRESS_API_URL);
            Article[] articles = objectMapper.readValue(jsonResponse, Article[].class);
            
            if (articles.length == 0) {
                System.out.println("Warning: WordPress API returned 0 articles");
                return; // Don't clear the cache if we got 0 articles
            }
            
            // Clear existing cache
            articlesCache.clear();
            
            // Process and cache each article
            for (Article article : articles) {
                // Reformatiere den Artikel
                reformatArticle(article);
                
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
                
                // Speichere jeden Artikel in einer eigenen Datei
                saveArticleToFile(article);
            }
            
            // Speichere auch die Artikelliste für Kompatibilität
            saveArticlesList();
            
            // Update last cache refresh time
            lastCacheUpdate = LocalDateTime.now();
            System.out.println("Cache refreshed successfully. Cached " + articles.length + " articles.");
            
            // Update server status
            serverStatus.setStatus(ServerStatus.Status.ONLINE);
            serverStatus.setMessage("Server online, letzte Aktualisierung: " + 
                DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm:ss").format(lastCacheUpdate));
            serverStatus.setLastUpdate(lastCacheUpdate);
            saveServerStatus();
        } catch (Exception e) {
            System.err.println("Error refreshing cache: " + e.getMessage());
            e.printStackTrace();
            
            // Update server status
            if (e instanceof SocketTimeoutException || e.getMessage().contains("Connection")) {
                serverStatus.setStatus(ServerStatus.Status.WORDPRESS_OFFLINE);
                serverStatus.setMessage("Die Schul-Website ist nicht erreichbar. Verwende zwischengespeicherte Daten.");
            } else {
                serverStatus.setStatus(ServerStatus.Status.ERROR);
                serverStatus.setMessage("Fehler beim Aktualisieren der Daten: " + e.getMessage());
            }
            saveServerStatus();
            
            throw e; // Re-throw to let the caller handle it
        }
    }
    
    private void loadCachedArticles() {
        try {
            // Zuerst versuchen, Artikel aus einzelnen Dateien zu laden
            Path articlesDir = Paths.get(ARTICLES_DIRECTORY);
            if (Files.exists(articlesDir)) {
                Files.list(articlesDir)
                    .filter(path -> path.toString().endsWith(".json"))
                    .forEach(path -> {
                        try {
                            String articleJson = new String(Files.readAllBytes(path));
                            Article article = objectMapper.readValue(articleJson, Article.class);
                            articlesCache.put(article.getId(), article);
                        } catch (Exception e) {
                            System.err.println("Error loading article from " + path + ": " + e.getMessage());
                        }
                    });
                
                if (!articlesCache.isEmpty()) {
                    System.out.println("Loaded " + articlesCache.size() + " articles from individual files.");
                    return;
                }
            }
            
            // Fallback: Versuche, Artikel aus der alten Cache-Datei zu laden
            Path cacheFile = Paths.get(ARTICLES_CACHE_FILE);
            if (Files.exists(cacheFile)) {
                String cachedJson = new String(Files.readAllBytes(cacheFile));
                Article[] articles = objectMapper.readValue(cachedJson, Article[].class);
                
                for (Article article : articles) {
                    articlesCache.put(article.getId(), article);
                    // Speichere den Artikel auch in einer eigenen Datei für zukünftige Verwendung
                    saveArticleToFile(article);
                }
                
                System.out.println("Loaded " + articlesCache.size() + " articles from legacy cache file.");
            }
        } catch (Exception e) {
            System.err.println("Error loading cached articles: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void saveArticleToFile(Article article) {
        try {
            String filename = "article_" + article.getId() + ".json";
            Path filePath = Paths.get(ARTICLES_DIRECTORY, filename);
            String json = objectMapper.writeValueAsString(article);
            Files.write(filePath, json.getBytes());
        } catch (Exception e) {
            System.err.println("Error saving article " + article.getId() + " to file: " + e.getMessage());
        }
    }
    
    private void saveArticlesList() {
        try {
            List<Article> articles = new ArrayList<>(articlesCache.values());
            String json = objectMapper.writeValueAsString(articles);
            Files.write(Paths.get(ARTICLES_CACHE_FILE), json.getBytes());
        } catch (Exception e) {
            System.err.println("Error saving articles list to cache: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void saveArticlesToCache() {
        // Speichere jeden Artikel in einer eigenen Datei
        for (Article article : articlesCache.values()) {
            saveArticleToFile(article);
        }
        
        // Speichere auch die Artikelliste für Kompatibilität
        saveArticlesList();
    }
    
    private void loadServerStatus() {
        try {
            Path statusFile = Paths.get(SERVER_STATUS_FILE);
            if (Files.exists(statusFile)) {
                String statusJson = new String(Files.readAllBytes(statusFile));
                serverStatus = objectMapper.readValue(statusJson, ServerStatus.class);
                System.out.println("Loaded server status from cache.");
            } else {
                // Initialize with default values
                serverStatus.setStatus(ServerStatus.Status.STARTING);
                serverStatus.setMessage("Server wird gestartet...");
                serverStatus.setLastUpdate(LocalDateTime.now());
                saveServerStatus();
            }
        } catch (Exception e) {
            System.err.println("Error loading server status: " + e.getMessage());
            e.printStackTrace();
            
            // Initialize with default values
            serverStatus.setStatus(ServerStatus.Status.ERROR);
            serverStatus.setMessage("Fehler beim Laden des Server-Status: " + e.getMessage());
            serverStatus.setLastUpdate(LocalDateTime.now());
            saveServerStatus();
        }
    }
    
    private void saveServerStatus() {
        try {
            String json = objectMapper.writeValueAsString(serverStatus);
            Files.write(Paths.get(SERVER_STATUS_FILE), json.getBytes());
        } catch (Exception e) {
            System.err.println("Error saving server status: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private String fetchDataFromWordPress(String apiUrl) throws IOException {
        URL url = new URL(apiUrl);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod("GET");
        connection.setConnectTimeout(CONNECTION_TIMEOUT);
        connection.setReadTimeout(READ_TIMEOUT);
        
        int responseCode = connection.getResponseCode();
        if (responseCode != HttpURLConnection.HTTP_OK) {
            throw new IOException("HTTP error code: " + responseCode);
        }
        
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(connection.getInputStream()))) {
            return reader.lines().collect(Collectors.joining());
        } finally {
            connection.disconnect();
        }
    }
    
    private void downloadImage(String imageUrl, Path destination) {
        try {
            URL url = new URL(imageUrl);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setConnectTimeout(CONNECTION_TIMEOUT);
            connection.setReadTimeout(READ_TIMEOUT);
            
            try (InputStream in = connection.getInputStream()) {
                Files.copy(in, destination, StandardCopyOption.REPLACE_EXISTING);
            } finally {
                connection.disconnect();
            }
        } catch (Exception e) {
            System.err.println("Error downloading image from " + imageUrl + ": " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    // Helper method to process WordPress content
    private String processWordPressContent(String content) {
        if (content == null) return "";
        
        // Remove any truncation markers that WordPress might add
        String processedContent = content;
        
        // Replace any "[&hellip;]" or similar truncation markers
        processedContent = processedContent.replaceAll("\\[&hellip;\\]", "");
        processedContent = processedContent.replaceAll("\\[…\\]", "");
        processedContent = processedContent.replaceAll("\\[&#8230;\\]", "");
        
        // Fix any incomplete HTML tags
        if (!processedContent.contains("</p>") && processedContent.contains("<p>")) {
            processedContent += "</p>";
        }
        
        // Fix WordPress "read more" links
        processedContent = processedContent.replaceAll("<a class=\"more-link\"[^>]*>.*?</a>", "");
        
        // Fix WordPress protected content placeholders
        processedContent = processedContent.replaceAll("\\(Passwortgeschützer Inhalt\\)", "");
        
        // Fix WordPress excerpt ellipsis
        processedContent = processedContent.replaceAll("&hellip;", "...");
        
        // Remove any WordPress shortcodes that might be causing issues
        processedContent = processedContent.replaceAll("\\[\\/?[^\\]]+\\]", "");
        
        // Fix abrupt ending with ellipsis
        if (processedContent.endsWith("...") || processedContent.endsWith("…")) {
            processedContent = processedContent.replaceAll("\\.\\.$", "");
            processedContent = processedContent.replaceAll("…$", "");
        }
        
        return processedContent;
    }
    
    /**
     * Reformatiert einen Artikel, um die Darstellung zu verbessern.
     * - Bereinigt HTML-Inhalte
     * - Verbessert die Lesbarkeit
     * - Entfernt unnötige Elemente
     */
    private void reformatArticle(Article article) {
        // Verarbeite den Inhalt
        if (article.getContent() != null) {
            String processedContent = processWordPressContent(article.getContent().getRendered());
            article.getContent().setRendered(processedContent);
        }
        
        // Verarbeite den Auszug
        if (article.getExcerpt() != null) {
            String processedExcerpt = processWordPressContent(article.getExcerpt().getRendered());
            article.getExcerpt().setRendered(processedExcerpt);
        }
        
        // Verarbeite den Titel (entferne HTML-Tags)
        if (article.getTitle() != null) {
            String title = article.getTitle().getRendered();
            title = title.replaceAll("<[^>]+>", ""); // Entferne HTML-Tags
            article.getTitle().setRendered(title);
        }
        
        // Formatiere das Datum
        if (article.getDate() != null) {
            try {
                // WordPress-Datum ist im ISO-8601-Format (z.B. "2023-03-08T12:34:56")
                String isoDate = article.getDate();
                // Behalte das ISO-Format bei, aber entferne Millisekunden und Zeitzonen, falls vorhanden
                if (isoDate.contains(".")) {
                    isoDate = isoDate.substring(0, isoDate.indexOf(".")) + "Z";
                }
                article.setDate(isoDate);
            } catch (Exception e) {
                System.err.println("Error formatting date for article " + article.getId() + ": " + e.getMessage());
            }
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
    
    public static class RenderedContent {
        private String rendered;
        
        public String getRendered() { return rendered; }
        public void setRendered(String rendered) { this.rendered = rendered; }
    }
    
    public static class ServerStatus {
        public enum Status {
            ONLINE,
            OFFLINE,
            WORDPRESS_OFFLINE,
            STARTING,
            ERROR
        }
        
        private Status status = Status.STARTING;
        private String message = "Server wird gestartet...";
        private LocalDateTime lastUpdate = LocalDateTime.now();
        
        public Status getStatus() { return status; }
        public void setStatus(Status status) { this.status = status; }
        
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        
        public LocalDateTime getLastUpdate() { return lastUpdate; }
        public void setLastUpdate(LocalDateTime lastUpdate) { this.lastUpdate = lastUpdate; }
        
        // Hilfsmethode für die JSON-Serialisierung
        public String getLastUpdateFormatted() {
            if (lastUpdate == null) return "";
            return lastUpdate.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        }
    }
    
    public static class ApiResponse<T> {
        private boolean success;
        private String message;
        private T data;
        
        public ApiResponse(boolean success, String message, T data) {
            this.success = success;
            this.message = message;
            this.data = data;
        }
        
        public boolean isSuccess() { return success; }
        public void setSuccess(boolean success) { this.success = success; }
        
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        
        public T getData() { return data; }
        public void setData(T data) { this.data = data; }
    }
} 