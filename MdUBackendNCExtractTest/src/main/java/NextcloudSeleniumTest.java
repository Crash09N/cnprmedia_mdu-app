import org.openqa.selenium.By;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class NextcloudSeleniumTest {
    // Nextcloud URLs
    private static final String NEXTCLOUD_LOGIN_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/login";
    private static final String NEXTCLOUD_SETTINGS_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/index.php/settings/user";
    private static final String NEXTCLOUD_FILES_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/index.php/apps/files/";
    
    // Path to ChromeDriver - can be overridden by system property
    private static final String DEFAULT_CHROMEDRIVER_PATH = "/usr/bin/chromedriver";

    public static void main(String[] args) {
        // Read username and password from console
        Scanner scanner = new Scanner(System.in);
        System.out.print("Benutzername: ");
        String username = scanner.nextLine();
        System.out.print("Passwort: ");
        String password = scanner.nextLine();
        scanner.close();

        // Set ChromeDriver path if not already set
        String chromeDriverPath = System.getProperty("webdriver.chrome.driver");
        if (chromeDriverPath == null || chromeDriverPath.isEmpty()) {
            System.setProperty("webdriver.chrome.driver", DEFAULT_CHROMEDRIVER_PATH);
            System.out.println("Using default ChromeDriver path: " + DEFAULT_CHROMEDRIVER_PATH);
        } else {
            System.out.println("Using configured ChromeDriver path: " + chromeDriverPath);
        }

        // Set up Chrome options
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--headless=new"); // Use the new headless mode
        options.addArguments("--disable-gpu");
        options.addArguments("--window-size=1920,1080");
        options.addArguments("--no-sandbox");
        options.addArguments("--disable-dev-shm-usage");
        options.addArguments("--disable-extensions");
        options.addArguments("--disable-infobars");
        options.addArguments("--remote-allow-origins=*");
        
        // Add Linux-specific options
        String osName = System.getProperty("os.name").toLowerCase();
        if (osName.contains("linux")) {
            System.out.println("Running on Linux, adding Linux-specific options");
            options.addArguments("--disable-setuid-sandbox");
            options.addArguments("--single-process");
            options.setBinary("/usr/bin/google-chrome"); // Default Linux Chrome path
        }

        WebDriver driver = null;
        try {
            driver = new ChromeDriver(options);
            System.out.println("WebDriver initialized successfully");
            extractUserData(driver, username, password);
        } catch (Exception e) {
            System.err.println("Fehler beim Extrahieren der Benutzerdaten: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (driver != null) {
                try {
                    driver.quit();
                    System.out.println("WebDriver closed successfully");
                } catch (Exception e) {
                    System.err.println("Fehler beim Schließen des WebDrivers: " + e.getMessage());
                }
            }
        }
        
        // Create a shell script for running on Linux server
        createLinuxRunScript();
    }

    private static void takeScreenshot(WebDriver driver, String fileName) {
        try {
            // Create screenshots directory if it doesn't exist
            File screenshotsDir = new File("screenshots");
            if (!screenshotsDir.exists()) {
                screenshotsDir.mkdirs();
                System.out.println("Created screenshots directory");
            }
            
            // Save screenshot to the screenshots directory
            File screenshot = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
            File destination = new File(screenshotsDir, fileName);
            Files.copy(screenshot.toPath(), destination.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            System.out.println("Screenshot gespeichert: " + destination.getPath());
        } catch (IOException e) {
            System.err.println("Fehler beim Speichern des Screenshots: " + e.getMessage());
        }
    }

    private static void extractUserData(WebDriver driver, String username, String password) {
        try {
            System.out.println("Schritt 1: Bei Nextcloud anmelden...");
            driver.get(NEXTCLOUD_LOGIN_URL);
            
            // Take a screenshot of the login page
            takeScreenshot(driver, "login_page.png");
            
            // Print page source for debugging
            System.out.println("Login-Seite HTML-Struktur:");
            String pageSource = driver.getPageSource();
            System.out.println(pageSource.substring(0, Math.min(1000, pageSource.length())) + "...");
            
            // Print all input elements on the login page
            System.out.println("Input-Elemente auf der Login-Seite:");
            List<WebElement> inputElements = driver.findElements(By.tagName("input"));
            for (WebElement element : inputElements) {
                String id = element.getAttribute("id");
                String name = element.getAttribute("name");
                String type = element.getAttribute("type");
                System.out.println("  Input: id=" + id + ", name=" + name + ", type=" + type);
            }
            
            // Try to find login form elements by different selectors
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
            
            // Try to find username field by different selectors
            WebElement usernameField = null;
            try {
                usernameField = driver.findElement(By.id("username"));
                System.out.println("Benutzername-Feld gefunden mit ID 'username'");
            } catch (Exception e) {
                System.out.println("Benutzername-Feld nicht gefunden mit ID 'username'");
                try {
                    usernameField = driver.findElement(By.name("username"));
                    System.out.println("Benutzername-Feld gefunden mit Name 'username'");
                } catch (Exception e2) {
                    System.out.println("Benutzername-Feld nicht gefunden mit Name 'username'");
                    try {
                        usernameField = driver.findElement(By.cssSelector("input[type='text']"));
                        System.out.println("Benutzername-Feld gefunden mit CSS-Selektor 'input[type=\"text\"]'");
                    } catch (Exception e3) {
                        System.out.println("Benutzername-Feld nicht gefunden mit CSS-Selektor 'input[type=\"text\"]'");
                    }
                }
            }
            
            if (usernameField == null) {
                System.err.println("Konnte das Benutzername-Feld nicht finden. Abbruch.");
                return;
            }
            
            // Enter username
            usernameField.sendKeys(username);
            
            // Try to find password field
            WebElement passwordField = null;
            try {
                passwordField = driver.findElement(By.id("password"));
                System.out.println("Passwort-Feld gefunden mit ID 'password'");
            } catch (Exception e) {
                System.out.println("Passwort-Feld nicht gefunden mit ID 'password'");
                try {
                    passwordField = driver.findElement(By.name("password"));
                    System.out.println("Passwort-Feld gefunden mit Name 'password'");
                } catch (Exception e2) {
                    System.out.println("Passwort-Feld nicht gefunden mit Name 'password'");
                    try {
                        passwordField = driver.findElement(By.cssSelector("input[type='password']"));
                        System.out.println("Passwort-Feld gefunden mit CSS-Selektor 'input[type=\"password\"]'");
                    } catch (Exception e3) {
                        System.out.println("Passwort-Feld nicht gefunden mit CSS-Selektor 'input[type=\"password\"]'");
                    }
                }
            }
            
            if (passwordField == null) {
                System.err.println("Konnte das Passwort-Feld nicht finden. Abbruch.");
                return;
            }
            
            // Enter password
            passwordField.sendKeys(password);
            
            // Try to find login button
            WebElement loginButton = null;
            try {
                loginButton = driver.findElement(By.id("kc-login"));
                System.out.println("Login-Button gefunden mit ID 'kc-login'");
            } catch (Exception e) {
                System.out.println("Login-Button nicht gefunden mit ID 'kc-login'");
                try {
                    loginButton = driver.findElement(By.cssSelector("button[type='submit']"));
                    System.out.println("Login-Button gefunden mit CSS-Selektor 'button[type=\"submit\"]'");
                } catch (Exception e2) {
                    System.out.println("Login-Button nicht gefunden mit CSS-Selektor 'button[type=\"submit\"]'");
                    try {
                        loginButton = driver.findElement(By.cssSelector("input[type='submit']"));
                        System.out.println("Login-Button gefunden mit CSS-Selektor 'input[type=\"submit\"]'");
                    } catch (Exception e3) {
                        System.out.println("Login-Button nicht gefunden mit CSS-Selektor 'input[type=\"submit\"]'");
                    }
                }
            }
            
            if (loginButton == null) {
                System.err.println("Konnte den Login-Button nicht finden. Abbruch.");
                return;
            }
            
            // Take screenshot before clicking login button
            takeScreenshot(driver, "before_login.png");
            
            // Click login button
            loginButton.click();
            
            // Warte kurz, um sicherzustellen, dass die Seite geladen wird
            try {
                Thread.sleep(3000); // 3 Sekunden warten
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            
            // Extrahiere Benutzerdaten
            JSONObject userData = new JSONObject();
            userData.put("username", username);
            
            // Direkt zur Einstellungsseite navigieren
            System.out.println("Navigiere zur Einstellungsseite...");
            driver.get(NEXTCLOUD_SETTINGS_URL);
            
            // Warte auf die Einstellungsseite
            try {
                wait.until(ExpectedConditions.or(
                    ExpectedConditions.titleContains("Einstellungen"),
                    ExpectedConditions.titleContains("Settings"),
                    ExpectedConditions.titleContains("Persönliche Informationen")
                ));
                System.out.println("Einstellungsseite geladen. Titel: " + driver.getTitle());
                takeScreenshot(driver, "settings_page.png");
            } catch (Exception e) {
                System.err.println("Fehler beim Warten auf Einstellungsseite: " + e.getMessage());
                takeScreenshot(driver, "settings_error.png");
                return;
            }
            
            // Speichere den Screenshot der Einstellungsseite für die Analyse
            takeScreenshot(driver, "settings_page_detailed.png");
            
            // Drucke die HTML-Struktur der Einstellungsseite für die Analyse
            System.out.println("Einstellungsseite HTML-Struktur:");
            pageSource = driver.getPageSource();
            System.out.println(pageSource.substring(0, Math.min(2000, pageSource.length())) + "...");
            
            // Versuche, die Eingabefelder für Vor- und Nachname zu finden
            System.out.println("Suche nach Eingabefeldern für persönliche Daten...");
            
            // Finde alle Input-Elemente auf der Einstellungsseite
            System.out.println("Input-Elemente auf der Einstellungsseite:");
            inputElements = driver.findElements(By.tagName("input"));
            for (WebElement element : inputElements) {
                String id = element.getAttribute("id");
                String name = element.getAttribute("name");
                String type = element.getAttribute("type");
                String value = element.getAttribute("value");
                System.out.println("  Input: id=" + id + ", name=" + name + ", type=" + type + ", value=" + value);
            }
            
            // Finde alle Span-Elemente, die möglicherweise den Namen enthalten
            System.out.println("Span-Elemente auf der Einstellungsseite:");
            List<WebElement> spanElements = driver.findElements(By.tagName("span"));
            for (WebElement element : spanElements) {
                String text = element.getText();
                if (text != null && !text.trim().isEmpty()) {
                    System.out.println("  Span: text=" + text);
                }
            }
            
            // Finde alle Div-Elemente mit bestimmten Klassen, die möglicherweise Benutzerdaten enthalten
            System.out.println("Div-Elemente mit relevanten Klassen:");
            List<WebElement> divElements = driver.findElements(By.cssSelector("div.user-settings-info, div.personal-info, div.personal-settings"));
            for (WebElement element : divElements) {
                String text = element.getText();
                if (text != null && !text.trim().isEmpty()) {
                    System.out.println("  Div: text=" + text);
                }
            }
            
            // Versuche, den vollständigen Namen zu extrahieren
            boolean nameFound = false;
            try {
                // Versuche, den vollständigen Namen aus dem span-Element mit data-v-55600bf5 zu extrahieren
                WebElement nameSpan = driver.findElement(By.cssSelector("span[data-v-55600bf5]"));
                if (nameSpan != null) {
                    String fullName = nameSpan.getText().trim();
                    System.out.println("Vollständiger Name (aus span[data-v-55600bf5]): " + fullName);
                    userData.put("fullName", fullName);
                    
                    // Versuche, Vor- und Nachname zu extrahieren
                    String[] nameParts = fullName.split(" ");
                    if (nameParts.length >= 2) {
                        // Nehme das letzte Wort als Nachname
                        String lastName = nameParts[nameParts.length - 1];
                        // Nehme alle Wörter außer dem letzten als Vorname
                        String firstName = String.join(" ", java.util.Arrays.copyOfRange(nameParts, 0, nameParts.length - 1));
                        System.out.println("Vorname: " + firstName);
                        System.out.println("Nachname: " + lastName);
                        userData.put("firstName", firstName);
                        userData.put("lastName", lastName);
                        nameFound = true;
                    }
                }
            } catch (Exception e) {
                System.out.println("Konnte das span-Element für den vollständigen Namen nicht finden: " + e.getMessage());
                
                // Alternative Methode: Suche nach dem Namen in der Seitenstruktur
                try {
                    WebElement userMenuButton = driver.findElement(By.cssSelector("div#settings div.user-info__header-full-name"));
                    if (userMenuButton != null) {
                        String fullName = userMenuButton.getText().trim();
                        System.out.println("Vollständiger Name (aus Menü): " + fullName);
                        userData.put("fullName", fullName);
                        
                        // Versuche, Vor- und Nachname zu extrahieren
                        String[] nameParts = fullName.split(" ");
                        if (nameParts.length >= 2) {
                            // Nehme das letzte Wort als Nachname
                            String lastName = nameParts[nameParts.length - 1];
                            // Nehme alle Wörter außer dem letzten als Vorname
                            String firstName = String.join(" ", java.util.Arrays.copyOfRange(nameParts, 0, nameParts.length - 1));
                            System.out.println("Vorname: " + firstName);
                            System.out.println("Nachname: " + lastName);
                            userData.put("firstName", firstName);
                            userData.put("lastName", lastName);
                            nameFound = true;
                        }
                    }
                } catch (Exception e2) {
                    System.out.println("Konnte den Namen nicht im Benutzermenü finden: " + e2.getMessage());
                    
                    // Versuche, den Namen aus dem Seitenquelltext zu extrahieren
                    Pattern namePattern = Pattern.compile("\"displayName\":\\s*\"([^\"]+)\"");
                    Matcher nameMatcher = namePattern.matcher(pageSource);
                    if (nameMatcher.find()) {
                        String fullName = nameMatcher.group(1);
                        System.out.println("Vollständiger Name (aus Quellcode): " + fullName);
                        userData.put("fullName", fullName);
                        
                        // Versuche, Vor- und Nachname zu extrahieren
                        String[] nameParts = fullName.split(" ");
                        if (nameParts.length >= 2) {
                            // Nehme das letzte Wort als Nachname
                            String lastName = nameParts[nameParts.length - 1];
                            // Nehme alle Wörter außer dem letzten als Vorname
                            String firstName = String.join(" ", java.util.Arrays.copyOfRange(nameParts, 0, nameParts.length - 1));
                            System.out.println("Vorname: " + firstName);
                            System.out.println("Nachname: " + lastName);
                            userData.put("firstName", firstName);
                            userData.put("lastName", lastName);
                            nameFound = true;
                        }
                    }
                }
            }
            
            // Wenn der Name nicht gefunden wurde, gib eine Warnung aus
            if (!nameFound) {
                System.out.println("WARNUNG: Konnte den Namen nicht extrahieren!");
            }
            
            // Versuche, die E-Mail-Adresse zu extrahieren
            boolean emailFound = false;
            try {
                // Versuche, die E-Mail-Adresse aus dem span-Element mit data-v-3670cfbc zu extrahieren
                WebElement emailSpan = driver.findElement(By.cssSelector("span[data-v-3670cfbc]"));
                if (emailSpan != null) {
                    String email = emailSpan.getText().trim();
                    System.out.println("E-Mail (aus span[data-v-3670cfbc]): " + email);
                    userData.put("email", email);
                    emailFound = true;
                }
            } catch (Exception e) {
                System.out.println("Konnte das span-Element für die E-Mail-Adresse nicht finden: " + e.getMessage());
                
                // Fallback: Versuche, die E-Mail-Adresse aus dem Eingabefeld zu extrahieren
                try {
                    WebElement emailElement = driver.findElement(By.id("email"));
                    if (emailElement != null) {
                        String email = emailElement.getAttribute("value");
                        System.out.println("E-Mail (aus Eingabefeld): " + email);
                        userData.put("email", email);
                        emailFound = true;
                    }
                } catch (Exception e1) {
                    System.out.println("Konnte das Eingabefeld für die E-Mail-Adresse nicht finden: " + e1.getMessage());
                    
                    // Weitere Fallback-Methoden...
                    // ... (bestehender Code für die E-Mail-Extraktion) ...
                }
            }
            
            // Wenn die E-Mail-Adresse nicht gefunden wurde, gib eine Warnung aus
            if (!emailFound) {
                System.out.println("WARNUNG: Konnte die E-Mail-Adresse nicht extrahieren!");
            }
            
            // Versuche, die Klasse/Gruppe zu extrahieren
            boolean groupsFound = false;
            try {
                // Versuche, die Gruppen aus dem span-Element mit data-v-29a613a4 und der Klasse details__groups-list zu extrahieren
                WebElement groupsSpan = driver.findElement(By.cssSelector("span[data-v-29a613a4].details__groups-list"));
                if (groupsSpan != null) {
                    String groupsText = groupsSpan.getText().trim();
                    System.out.println("Gruppen (aus span[data-v-29a613a4].details__groups-list): " + groupsText);
                    
                    // Teile den Text in einzelne Gruppen auf
                    String[] groupsArray = groupsText.split(",");
                    
                    // Extrahiere die Klasse als erste Gruppe vor dem ersten Komma
                    if (groupsArray.length > 0) {
                        String firstGroup = groupsArray[0].trim();
                        System.out.println("Erste Gruppe (Klasse): " + firstGroup);
                        userData.put("class", firstGroup);
                    }
                    
                    groupsFound = true;
                }
            } catch (Exception e) {
                System.out.println("Konnte das span-Element für die Gruppen nicht finden: " + e.getMessage());
                
                // Versuche alternative Selektoren
                try {
                    // Versuche, die Gruppen mit einem anderen Selektor zu finden
                    WebElement groupsElement = driver.findElement(By.cssSelector(".details__groups-list"));
                    if (groupsElement != null) {
                        String groupsText = groupsElement.getText().trim();
                        System.out.println("Gruppen (aus .details__groups-list): " + groupsText);
                        
                        // Teile den Text in einzelne Gruppen auf
                        String[] groupsArray = groupsText.split(",");
                        
                        // Extrahiere die Klasse als erste Gruppe vor dem ersten Komma
                        if (groupsArray.length > 0) {
                            String firstGroup = groupsArray[0].trim();
                            System.out.println("Erste Gruppe (Klasse): " + firstGroup);
                            userData.put("class", firstGroup);
                        }
                        
                        groupsFound = true;
                    }
                } catch (Exception e2) {
                    System.out.println("Konnte das Element mit der Klasse details__groups-list nicht finden: " + e2.getMessage());
                    
                    // Versuche einen weiteren alternativen Selektor
                    try {
                        WebElement groupsElement = driver.findElement(By.cssSelector("span[data-v-29a613a4]"));
                        if (groupsElement != null) {
                            String groupsText = groupsElement.getText().trim();
                            System.out.println("Gruppen (aus span[data-v-29a613a4]): " + groupsText);
                            
                            // Teile den Text in einzelne Gruppen auf
                            String[] groupsArray = groupsText.split(",");
                            
                            // Extrahiere die Klasse als erste Gruppe vor dem ersten Komma
                            if (groupsArray.length > 0) {
                                String firstGroup = groupsArray[0].trim();
                                System.out.println("Erste Gruppe (Klasse): " + firstGroup);
                                userData.put("class", firstGroup);
                            }
                            
                            groupsFound = true;
                        }
                    } catch (Exception e3) {
                        System.out.println("Konnte das span-Element mit data-v-29a613a4 nicht finden: " + e3.getMessage());
                    }
                }
            }
            
            // Wenn keine Gruppen gefunden wurden, gib eine Warnung aus
            if (!groupsFound) {
                System.out.println("WARNUNG: Konnte keine Gruppen extrahieren!");
            }
            
            // Versuche, die Avatar-ID zu extrahieren, um die WebDAV-URL zu konstruieren
            try {
                // Finde das Avatar-Bild mit dem Attribut data-v-9ce7ef1d
                WebElement avatarImg = driver.findElement(By.cssSelector("img[data-v-9ce7ef1d]"));
                if (avatarImg != null) {
                    // Extrahiere die src des Avatar-Bildes
                    String avatarSrc = avatarImg.getAttribute("src");
                    System.out.println("Avatar-Bild src: " + avatarSrc);
                    
                    // Extrahiere die ID aus der src
                    // Format: /index.php/avatar/a25e9d84-1ee2-4431-9ea1-f19b5c86386c/64/dark?v=2
                    Pattern avatarIdPattern = Pattern.compile("/avatar/([^/]+)/");
                    Matcher avatarIdMatcher = avatarIdPattern.matcher(avatarSrc);
                    
                    if (avatarIdMatcher.find()) {
                        String avatarId = avatarIdMatcher.group(1);
                        System.out.println("Avatar-ID: " + avatarId);
                        
                        // Konstruiere die WebDAV-URL mit der Avatar-ID
                        String webdavUrl = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/remote.php/dav/files/" + avatarId + "/";
                        System.out.println("WebDAV-URL (aus Avatar-ID): " + webdavUrl);
                        userData.put("webdavUrl", webdavUrl);
                    } else {
                        System.out.println("Konnte die Avatar-ID nicht aus der src extrahieren: " + avatarSrc);
                    }
                }
            } catch (Exception e) {
                System.out.println("Konnte das Avatar-Bild nicht finden: " + e.getMessage());
                
                // Versuche alternative Selektoren
                try {
                    // Versuche, alle Bilder zu durchsuchen
                    List<WebElement> allImages = driver.findElements(By.tagName("img"));
                    boolean found = false;
                    for (WebElement img : allImages) {
                        String src = img.getAttribute("src");
                        if (src != null && src.contains("/avatar/")) {
                            System.out.println("Avatar-Bild gefunden: " + src);
                            
                            // Extrahiere die ID aus der src
                            Pattern avatarIdPattern = Pattern.compile("/avatar/([^/]+)/");
                            Matcher avatarIdMatcher = avatarIdPattern.matcher(src);
                            
                            if (avatarIdMatcher.find()) {
                                String avatarId = avatarIdMatcher.group(1);
                                System.out.println("Avatar-ID: " + avatarId);
                                
                                // Konstruiere die WebDAV-URL mit der Avatar-ID
                                String webdavUrl = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/remote.php/dav/files/" + avatarId + "/";
                                System.out.println("WebDAV-URL (aus Avatar-ID): " + webdavUrl);
                                userData.put("webdavUrl", webdavUrl);
                                found = true;
                                break;
                            }
                        }
                    }
                    
                    if (!found) {
                        System.out.println("Konnte kein Avatar-Bild mit einer ID finden.");
                    }
                } catch (Exception e2) {
                    System.out.println("Fehler beim Durchsuchen der Bilder: " + e2.getMessage());
                }
            }
            
            // Speichere die Benutzerdaten in einer JSON-Datei
            System.out.println("\nExtrahierte Benutzerdaten:");
            System.out.println("firstName: " + userData.optString("firstName", ""));
            System.out.println("lastName: " + userData.optString("lastName", ""));
            System.out.println("webdavUrl: " + userData.optString("webdavUrl", ""));
            System.out.println("fullName: " + userData.optString("fullName", ""));
            System.out.println("email: " + userData.optString("email", ""));
            System.out.println("username: " + userData.optString("username", ""));
            System.out.println("class: " + userData.optString("class", ""));
            
            // Speichere die Benutzerdaten in einer JSON-Datei
            try (FileWriter file = new FileWriter("user_data.json")) {
                file.write(userData.toString(2));
                System.out.println("Benutzerdaten wurden in user_data.json gespeichert.");
            } catch (IOException e) {
                System.err.println("Fehler beim Speichern der Benutzerdaten: " + e.getMessage());
            }
            
        } catch (Exception e) {
            System.err.println("Fehler beim Extrahieren der Benutzerdaten: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Creates a shell script for running the application on a Linux server
     */
    private static void createLinuxRunScript() {
        String scriptContent = "#!/bin/bash\n\n" +
                "# Script to run NextcloudSeleniumTest on a Linux server\n\n" +
                "# Check if Chrome is installed\n" +
                "if ! command -v google-chrome &> /dev/null; then\n" +
                "    echo \"Google Chrome is not installed. Installing...\"\n" +
                "    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -\n" +
                "    echo \"deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main\" | sudo tee /etc/apt/sources.list.d/google-chrome.list\n" +
                "    sudo apt-get update\n" +
                "    sudo apt-get install -y google-chrome-stable\n" +
                "fi\n\n" +
                "# Check if ChromeDriver is installed\n" +
                "if [ ! -f \"/usr/bin/chromedriver\" ]; then\n" +
                "    echo \"ChromeDriver is not installed. Installing...\"\n" +
                "    CHROME_VERSION=$(google-chrome --version | cut -d ' ' -f 3 | cut -d '.' -f 1)\n" +
                "    CHROMEDRIVER_VERSION=$(curl -s \"https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}\")\n" +
                "    wget -q \"https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip\"\n" +
                "    unzip -q chromedriver_linux64.zip\n" +
                "    sudo mv chromedriver /usr/bin/chromedriver\n" +
                "    sudo chown root:root /usr/bin/chromedriver\n" +
                "    sudo chmod +x /usr/bin/chromedriver\n" +
                "    rm chromedriver_linux64.zip\n" +
                "fi\n\n" +
                "# Run the Java application\n" +
                "java -Dwebdriver.chrome.driver=/usr/bin/chromedriver -jar NextcloudSeleniumTest.jar\n";
        
        try (FileWriter writer = new FileWriter("run_on_linux.sh")) {
            writer.write(scriptContent);
            System.out.println("Shell script 'run_on_linux.sh' created for running on Linux server");
            
            // Make the script executable
            File scriptFile = new File("run_on_linux.sh");
            scriptFile.setExecutable(true);
            System.out.println("Script made executable");
        } catch (IOException e) {
            System.err.println("Fehler beim Erstellen des Shell-Scripts: " + e.getMessage());
        }
    }
} 