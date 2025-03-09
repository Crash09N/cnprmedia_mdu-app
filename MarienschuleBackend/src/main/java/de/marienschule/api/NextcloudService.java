package de.marienschule.api;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import javax.annotation.PostConstruct;

import org.jsoup.Connection.Method;
import org.jsoup.Connection.Response;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Service für die Interaktion mit Nextcloud
 * Extrahiert Benutzerdaten und speichert sie in JSON-Dateien
 */
@Service
public class NextcloudService {
    
    @Value("${app.data.directory:./data}")
    private String dataDirectory;
    
    private static final String USERS_FILE = "users.json";
    private static final String NEXTCLOUD_LOGIN_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/index.php/login";
    private static final String NEXTCLOUD_USER_SETTINGS_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/index.php/settings/user";
    private static final String NEXTCLOUD_FILES_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/index.php/apps/files/files";
    
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final AtomicInteger idCounter = new AtomicInteger(1);
    
    /**
     * Initialisiert das Datenverzeichnis und lädt die aktuelle ID
     */
    @PostConstruct
    public void init() {
        try {
            // Erstelle das Datenverzeichnis, falls es nicht existiert
            File directory = new File(dataDirectory);
            if (!directory.exists()) {
                directory.mkdirs();
            }
            
            // Initialisiere die ID-Zähler basierend auf vorhandenen Daten
            File usersFile = new File(directory, USERS_FILE);
            if (usersFile.exists()) {
                List<Map<String, Object>> users = objectMapper.readValue(
                    usersFile, 
                    new TypeReference<List<Map<String, Object>>>() {}
                );
                
                // Finde die höchste ID
                int maxId = 0;
                for (Map<String, Object> user : users) {
                    int userId = (int) user.get("user_id");
                    if (userId > maxId) {
                        maxId = userId;
                    }
                }
                
                // Setze den ID-Zähler auf die nächste verfügbare ID
                idCounter.set(maxId + 1);
            }
        } catch (IOException e) {
            // Fehler beim Initialisieren des Datenverzeichnisses
            e.printStackTrace();
        }
    }
    
    /**
     * Extrahiert Benutzerdaten aus Nextcloud und speichert sie in JSON-Dateien
     * 
     * @param username Benutzername für Nextcloud
     * @param password Passwort für Nextcloud
     * @return Map mit extrahierten Benutzerdaten und Status
     */
    public Map<String, Object> extractUserDataFromNextcloud(String username, String password) {
        Map<String, Object> result = new HashMap<>();
        Map<String, String> cookies = new HashMap<>();
        
        try {
            // Schritt 1: Anmeldung bei Nextcloud
            Response loginResponse = loginToNextcloud(username, password, cookies);
            
            if (loginResponse.statusCode() != 200 && loginResponse.statusCode() != 302) {
                result.put("success", false);
                result.put("message", "Anmeldung fehlgeschlagen. Bitte überprüfen Sie Ihre Anmeldedaten.");
                return result;
            }
            
            // Cookies aus der Antwort extrahieren und speichern
            cookies.putAll(loginResponse.cookies());
            
            // Schritt 2: Benutzereinstellungen abrufen
            Document userSettingsDoc = Jsoup.connect(NEXTCLOUD_USER_SETTINGS_URL)
                    .cookies(cookies)
                    .get();
            
            // Extrahiere Vor- und Nachname
            String fullName = "";
            Elements nameElements = userSettingsDoc.select("[data-v-55600bf5]");
            if (!nameElements.isEmpty()) {
                fullName = nameElements.text().trim();
            }
            
            // Teile den vollständigen Namen in Vor- und Nachname
            String firstName = "";
            String lastName = "";
            if (!fullName.isEmpty()) {
                String[] nameParts = fullName.split(" ");
                if (nameParts.length > 1) {
                    lastName = nameParts[nameParts.length - 1];
                    firstName = fullName.substring(0, fullName.length() - lastName.length()).trim();
                } else {
                    firstName = fullName;
                }
            }
            
            // Extrahiere E-Mail-Adresse
            String email = "";
            Elements emailElements = userSettingsDoc.select("[data-v-3670cfbc]");
            if (!emailElements.isEmpty()) {
                email = emailElements.text().trim();
            }
            
            // Extrahiere Klasse
            String schoolClass = "";
            Elements classElements = userSettingsDoc.select("[data-v-29a613a4]");
            if (!classElements.isEmpty()) {
                String classText = classElements.text().trim();
                int commaIndex = classText.indexOf(',');
                if (commaIndex > 0) {
                    schoolClass = classText.substring(0, commaIndex).trim();
                }
            }
            
            // Schritt 3: WebDAV-URL abrufen
            Document filesDoc = Jsoup.connect(NEXTCLOUD_FILES_URL)
                    .cookies(cookies)
                    .get();
            
            // Klicke auf den Einstellungsbutton
            Element settingsButton = filesDoc.selectFirst("[data-cy-files-navigation-settings-button]");
            String webdavUrl = "";
            
            if (settingsButton != null) {
                // Simuliere einen Klick auf den Einstellungsbutton und lade die Seite neu
                Document settingsDoc = Jsoup.connect(NEXTCLOUD_FILES_URL)
                        .cookies(cookies)
                        .data("settings", "true")
                        .post();
                
                // Extrahiere WebDAV-URL
                Element webdavInput = settingsDoc.selectFirst("#webdav-url-input");
                if (webdavInput != null) {
                    webdavUrl = webdavInput.val();
                }
            }
            
            // Schritt 4: Daten in JSON-Datei speichern
            int userId = saveUserToJsonFile(username, firstName, lastName, email, schoolClass, webdavUrl);
            
            // Ergebnis zusammenstellen
            result.put("success", true);
            result.put("user_id", userId);
            result.put("username", username);
            result.put("first_name", firstName);
            result.put("last_name", lastName);
            result.put("email", email);
            result.put("school_class", schoolClass);
            result.put("webdav_url", webdavUrl);
            
        } catch (IOException e) {
            result.put("success", false);
            result.put("message", "Fehler beim Verbinden mit Nextcloud: " + e.getMessage());
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", "Unerwarteter Fehler: " + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Anmeldung bei Nextcloud
     */
    private Response loginToNextcloud(String username, String password, Map<String, String> cookies) throws IOException {
        // Zuerst die Login-Seite abrufen, um CSRF-Token zu erhalten
        Response initialResponse = Jsoup.connect(NEXTCLOUD_LOGIN_URL)
                .method(Method.GET)
                .execute();
        
        cookies.putAll(initialResponse.cookies());
        
        Document loginDoc = initialResponse.parse();
        String requesttoken = "";
        Element tokenInput = loginDoc.selectFirst("input[name=requesttoken]");
        if (tokenInput != null) {
            requesttoken = tokenInput.val();
        }
        
        // Anmeldung durchführen
        return Jsoup.connect(NEXTCLOUD_LOGIN_URL)
                .cookies(cookies)
                .data("user", username)
                .data("password", password)
                .data("requesttoken", requesttoken)
                .method(Method.POST)
                .followRedirects(true)
                .execute();
    }
    
    /**
     * Speichert Benutzerdaten in einer JSON-Datei
     */
    private int saveUserToJsonFile(String username, String firstName, String lastName, 
                                  String email, String schoolClass, String webdavUrl) throws IOException {
        int userId = -1;
        
        // Erstelle das Datenverzeichnis, falls es nicht existiert
        File directory = new File(dataDirectory);
        if (!directory.exists()) {
            directory.mkdirs();
        }
        
        File usersFile = new File(directory, USERS_FILE);
        List<Map<String, Object>> users = new ArrayList<>();
        
        // Lade vorhandene Benutzer, falls die Datei existiert
        if (usersFile.exists()) {
            users = objectMapper.readValue(
                usersFile, 
                new TypeReference<List<Map<String, Object>>>() {}
            );
        }
        
        // Prüfe, ob der Benutzer bereits existiert
        boolean userExists = false;
        for (Map<String, Object> user : users) {
            if (username.equals(user.get("username"))) {
                // Benutzer existiert bereits, aktualisiere die Daten
                userId = (int) user.get("user_id");
                user.put("first_name", firstName);
                user.put("last_name", lastName);
                user.put("email", email);
                user.put("school_class", schoolClass);
                user.put("webdav_url", webdavUrl);
                userExists = true;
                break;
            }
        }
        
        if (!userExists) {
            // Neuer Benutzer, füge ihn hinzu
            userId = idCounter.getAndIncrement();
            Map<String, Object> newUser = new HashMap<>();
            newUser.put("user_id", userId);
            newUser.put("username", username);
            newUser.put("first_name", firstName);
            newUser.put("last_name", lastName);
            newUser.put("email", email);
            newUser.put("school_class", schoolClass);
            newUser.put("webdav_url", webdavUrl);
            users.add(newUser);
        }
        
        // Speichere die aktualisierte Benutzerliste
        objectMapper.writerWithDefaultPrettyPrinter().writeValue(usersFile, users);
        
        return userId;
    }
    
    /**
     * Ruft Benutzerdaten aus der JSON-Datei ab
     */
    public Map<String, Object> getUserDataFromJsonFile(String username) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            File usersFile = new File(dataDirectory, USERS_FILE);
            if (!usersFile.exists()) {
                result.put("success", false);
                result.put("message", "Keine Benutzerdaten gefunden");
                return result;
            }
            
            List<Map<String, Object>> users = objectMapper.readValue(
                usersFile, 
                new TypeReference<List<Map<String, Object>>>() {}
            );
            
            // Suche nach dem Benutzer
            for (Map<String, Object> user : users) {
                if (username.equals(user.get("username"))) {
                    result.put("success", true);
                    result.put("user_id", user.get("user_id"));
                    result.put("username", user.get("username"));
                    result.put("first_name", user.get("first_name"));
                    result.put("last_name", user.get("last_name"));
                    result.put("email", user.get("email"));
                    result.put("school_class", user.get("school_class"));
                    result.put("webdav_url", user.get("webdav_url"));
                    return result;
                }
            }
            
            // Benutzer nicht gefunden
            result.put("success", false);
            result.put("message", "Benutzer nicht gefunden");
            
        } catch (IOException e) {
            result.put("success", false);
            result.put("message", "Fehler beim Lesen der Benutzerdaten: " + e.getMessage());
        }
        
        return result;
    }
}

/**
 * REST-Controller für die Nextcloud-Integration
 */
@RestController
class NextcloudController {
    
    private final NextcloudService nextcloudService;
    private final ObjectMapper objectMapper;
    
    public NextcloudController(NextcloudService nextcloudService) {
        this.nextcloudService = nextcloudService;
        this.objectMapper = new ObjectMapper();
    }
    
    /**
     * Endpunkt für die Anmeldung bei Nextcloud
     */
    @PostMapping("/api/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> credentials) {
        String username = credentials.get("username");
        String password = credentials.get("password");
        
        if (username == null || password == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Benutzername und Passwort sind erforderlich");
            return ResponseEntity.badRequest().body(response);
        }
        
        Map<String, Object> result = nextcloudService.extractUserDataFromNextcloud(username, password);
        
        if ((Boolean) result.get("success")) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
    }
    
    /**
     * Endpunkt zum Aktualisieren der Benutzerdaten
     */
    @PostMapping("/api/refresh")
    public ResponseEntity<Map<String, Object>> refreshUserData(@RequestBody Map<String, String> credentials) {
        String username = credentials.get("username");
        String password = credentials.get("password");
        
        if (username == null || password == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Benutzername und Passwort sind erforderlich");
            return ResponseEntity.badRequest().body(response);
        }
        
        Map<String, Object> result = nextcloudService.extractUserDataFromNextcloud(username, password);
        
        if ((Boolean) result.get("success")) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
    }
    
    /**
     * Endpunkt zum Abrufen von Benutzerdaten aus der JSON-Datei
     */
    @PostMapping("/api/user")
    public ResponseEntity<Map<String, Object>> getUserData(@RequestBody Map<String, String> request) {
        String username = request.get("username");
        
        if (username == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Benutzername ist erforderlich");
            return ResponseEntity.badRequest().body(response);
        }
        
        Map<String, Object> result = nextcloudService.getUserDataFromJsonFile(username);
        
        if ((Boolean) result.get("success")) {
            return ResponseEntity.ok(result);
        } else {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(result);
        }
    }
} 