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
import java.util.Optional;
import java.util.stream.Collectors;

import javax.annotation.PostConstruct;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.CookieStore;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.protocol.HttpClientContext;
import org.apache.http.impl.client.BasicCookieStore;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;
import org.jsoup.Connection.Method;
import org.jsoup.Connection.Response;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.net.URL;
import java.io.InputStream;
import java.io.ByteArrayInputStream;
import java.util.Collections;
import org.jsoup.Connection;
import java.io.BufferedInputStream;
import org.apache.http.HttpHost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.cookie.Cookie;
import org.apache.http.protocol.HttpCoreContext;
import java.net.URI;
import java.net.URISyntaxException;
import org.apache.http.Header;
import com.fasterxml.jackson.databind.JsonNode;
import org.apache.http.impl.cookie.BasicClientCookie;
import java.net.URLDecoder;
import java.net.MalformedURLException;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.utils.URIBuilder;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.OutputType;
import org.openqa.selenium.TakesScreenshot;
import java.time.Duration;
import org.json.JSONObject;
import java.nio.file.StandardCopyOption;

/**
 * Service für die Interaktion mit Nextcloud
 * Extrahiert Benutzerdaten und speichert sie in JSON-Dateien
 */
@Service
public class NextcloudService {
    
    private static final Logger logger = LoggerFactory.getLogger(NextcloudService.class);
    
    @Value("${app.data.directory:./data}")
    private String dataDirectory;
    
    // Path to ChromeDriver - can be overridden by system property
    @Value("${webdriver.chrome.driver:/usr/bin/chromedriver}")
    private String chromeDriverPath;
    
    // Directory for screenshots
    @Value("${app.screenshots.directory:./screenshots}")
    private String screenshotsDirectory;
    
    private static final String USERS_FILE = "users.json";
    private static final String NEXTCLOUD_LOGIN_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/login";
    private static final String NEXTCLOUD_USER_SETTINGS_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/index.php/settings/user";
    private static final String NEXTCLOUD_FILES_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de/index.php/apps/files/files";
    
    // Add these constants for the Nextcloud API endpoints
    private static final String NEXTCLOUD_API_BASE_URL = "https://nextcloud-g2.bielefeld-marienschule.logoip.de";
    private static final String NEXTCLOUD_OCS_API_URL = NEXTCLOUD_API_BASE_URL + "/ocs/v1.php";
    private static final String NEXTCLOUD_USER_API_URL = NEXTCLOUD_OCS_API_URL + "/cloud/user";
    private static final String NEXTCLOUD_WEBDAV_URL = NEXTCLOUD_API_BASE_URL + "/remote.php/dav/files/";
    
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
        
        logger.trace("Starting extraction of user data from Nextcloud for user: {}", username);
        logger.debug("Attempting to log in to Nextcloud at: {}", NEXTCLOUD_LOGIN_URL);
        
        try {
            // Schritt 1: Anmeldung bei Nextcloud
            Response loginResponse = loginToNextcloud(username, password, cookies);
            
            // More detailed status checking
            int statusCode = loginResponse.statusCode();
            logger.debug("Login response status code: {}", statusCode);
            
            if (statusCode != 200 && statusCode != 302) {
                logger.warn("Login failed with status code: {}", statusCode);
                result.put("success", false);
                result.put("message", "Authentication failed. Status code: " + statusCode);
                return result;
            }
            
            // Schritt 2: Extrahiere Benutzerdaten über die Nextcloud API
            Map<String, String> userInfo = fetchUserInfoFromApi(username, loginResponse.cookies());
            
            // Extrahiere die Daten aus der API-Antwort
            String firstName = userInfo.getOrDefault("firstName", "");
            String lastName = userInfo.getOrDefault("lastName", "");
            String email = userInfo.getOrDefault("email", "");
            String schoolClass = userInfo.getOrDefault("schoolClass", "");
            String webdavUrl = userInfo.getOrDefault("webdavUrl", "");
            
            // Speichere die Benutzerdaten in der JSON-Datei
            int userId = saveUserToJsonFile(username, firstName, lastName, email, schoolClass, webdavUrl);
            
            // Bereite das Ergebnis vor
            result.put("success", true);
            result.put("user_id", userId);
            result.put("username", username);
            result.put("first_name", firstName);
            result.put("last_name", lastName);
            result.put("email", email);
            result.put("school_class", schoolClass);
            result.put("webdav_url", webdavUrl);
            
        } catch (Exception e) {
            logger.error("Comprehensive login error", e);
            result.put("success", false);
            result.put("message", "Login failed: " + e.getMessage());
            return result;
        }
        
        return result;
    }
    
    /**
     * Anmeldung bei Nextcloud
     */
    private Response loginToNextcloud(String username, String password, Map<String, String> cookies) throws IOException {
        logger.debug("Starting Nextcloud login process for user: {}", username);
        
        // Create a cookie store to maintain session across requests
        BasicCookieStore cookieStore = new BasicCookieStore();
        
        // Configure request with timeouts and redirect handling
        RequestConfig requestConfig = RequestConfig.custom()
            .setConnectTimeout(10000)
            .setSocketTimeout(10000)
            .setRedirectsEnabled(true)
            .setAuthenticationEnabled(false) // Disable automatic authentication to handle empty auth headers
            .build();
        
        // Create a custom HttpClientContext to maintain state between requests
        HttpClientContext context = HttpClientContext.create();
        context.setCookieStore(cookieStore);
        
        // Variables to store response data outside the try-with-resources block
        int statusCodeLogin = 0;
        String responseBodyLogin = "";
        Map<String, String> finalCookies = new HashMap<>(cookies);
        
        // Create HTTP client with cookie support
        CloseableHttpClient httpClient = null;
        try {
            httpClient = HttpClients.custom()
            .setDefaultRequestConfig(requestConfig)
                .setDefaultCookieStore(cookieStore)
                .disableAuthCaching() // Disable auth caching to prevent issues with empty auth headers
                .build();
            
            // Add any existing cookies to the cookie store
            for (Map.Entry<String, String> cookie : cookies.entrySet()) {
                BasicClientCookie clientCookie = new BasicClientCookie(cookie.getKey(), cookie.getValue());
                clientCookie.setDomain("nextcloud-g2.bielefeld-marienschule.logoip.de");
                clientCookie.setPath("/");
                cookieStore.addCookie(clientCookie);
            }
            
            // Step 1: Request Nextcloud login page to get redirected to Keycloak
            logger.debug("Step 1: Requesting Nextcloud login page");
            HttpGet initialRequest = new HttpGet(NEXTCLOUD_LOGIN_URL);
            
            // Add common headers to mimic a browser
            initialRequest.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
            initialRequest.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
            initialRequest.addHeader("Accept-Language", "en-US,en;q=0.5");
            
            CloseableHttpResponse initialResponse = null;
            try {
                // Execute with context to maintain state
                initialResponse = httpClient.execute(initialRequest, context);
            logger.debug("Initial response status: {}", initialResponse.getStatusLine());
            
                // Ensure the entity is fully consumed
                HttpEntity initialEntity = initialResponse.getEntity();
                if (initialEntity != null) {
                    EntityUtils.consume(initialEntity);
                }
            } finally {
                if (initialResponse != null) {
                    initialResponse.close();
                }
            }
            
            // Update cookies after initial request
            for (Cookie cookie : cookieStore.getCookies()) {
                finalCookies.put(cookie.getName(), cookie.getValue());
                logger.debug("Initial cookie: {} = {}", cookie.getName(), cookie.getValue());
            }
            
            // Step 2: Find the login form in the redirected page
            HttpGet loginPageRequest = new HttpGet(NEXTCLOUD_LOGIN_URL);
            
            // Add the same headers
            loginPageRequest.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
            loginPageRequest.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
            loginPageRequest.addHeader("Accept-Language", "en-US,en;q=0.5");
            
            CloseableHttpResponse loginPageResponse = null;
            String loginPageContent = "";
            
            try {
                // Execute with context to maintain state
                loginPageResponse = httpClient.execute(loginPageRequest, context);
                HttpEntity loginPageEntity = loginPageResponse.getEntity();
                if (loginPageEntity != null) {
                    loginPageContent = EntityUtils.toString(loginPageEntity);
                    EntityUtils.consume(loginPageEntity);
                }
            } finally {
                if (loginPageResponse != null) {
                    loginPageResponse.close();
                }
            }
            
            // Update cookies after login page request
            for (Cookie cookie : cookieStore.getCookies()) {
                finalCookies.put(cookie.getName(), cookie.getValue());
                logger.debug("Login page cookie: {} = {}", cookie.getName(), cookie.getValue());
            }
            
            // Parse the login page to find the form
            Document loginPageDoc = Jsoup.parse(loginPageContent);
            Element loginForm = loginPageDoc.selectFirst("form");
            
            if (loginForm != null) {
                String loginAction = loginForm.attr("action");
                logger.debug("Found login form with action URL: {}", loginAction);
                
                // Extract parameters from the login form action URL
                URI loginActionUri = new URI(loginAction);
                String queryString = loginActionUri.getQuery();
                
                if (queryString != null) {
                    // Extract parameters like session_code, execution, client_id, tab_id
                    String[] params = queryString.split("&");
                    for (String param : params) {
                        String[] keyValue = param.split("=");
                        if (keyValue.length == 2) {
                            String key = URLDecoder.decode(keyValue[0], StandardCharsets.UTF_8.name());
                            String value = URLDecoder.decode(keyValue[1], StandardCharsets.UTF_8.name());
                            logger.debug("Extracted parameter - {}: {}", key, value);
                        }
                    }
                }
                
                // Step 3: Submit login credentials to Keycloak
            logger.debug("Step 3: Submitting login credentials to Keycloak");
                HttpPost loginRequest = new HttpPost(loginAction);
                
                // Add the same headers plus content type
                loginRequest.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
                loginRequest.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
                loginRequest.addHeader("Accept-Language", "en-US,en;q=0.5");
                loginRequest.addHeader("Content-Type", "application/x-www-form-urlencoded");
                loginRequest.addHeader("Origin", "https://idp.bielefeld-marienschule.logoip.de");
                loginRequest.addHeader("Referer", loginAction);
                
                // Add login parameters
            List<NameValuePair> loginParams = new ArrayList<>();
            loginParams.add(new BasicNameValuePair("username", username));
            loginParams.add(new BasicNameValuePair("password", password));
            
            logger.debug("LOGIN PARAMETERS:");
            for (NameValuePair param : loginParams) {
                    if (param.getName().equals("password")) {
                        logger.debug("Param - Name: '{}', Value: '***MASKED***'", param.getName());
                    } else {
                        logger.debug("Param - Name: '{}', Value: '{}'", param.getName(), param.getValue());
                    }
                }
                
                loginRequest.setEntity(new UrlEncodedFormEntity(loginParams));
                
                CloseableHttpResponse loginResponse = null;
                try {
                    // Execute with context to maintain state
                    loginResponse = httpClient.execute(loginRequest, context);
                    statusCodeLogin = loginResponse.getStatusLine().getStatusCode();
            logger.debug("Login response status: {}", loginResponse.getStatusLine());

                    // Log response headers for debugging
            logger.debug("RAW RESPONSE HEADERS:");
                    for (Header header : loginResponse.getAllHeaders()) {
                logger.debug("{}: {}", header.getName(), header.getValue());
            }
            
                    // Get the final URL after login
                    HttpUriRequest currentReq = (HttpUriRequest) context.getAttribute(HttpCoreContext.HTTP_REQUEST);
                    HttpHost currentHost = (HttpHost) context.getAttribute(HttpCoreContext.HTTP_TARGET_HOST);
                    String finalUrlAfterLogin = (currentReq != null && currentReq.getURI().isAbsolute()) 
                        ? currentReq.getURI().toString() 
                        : (currentHost != null ? currentHost.toURI() + (currentReq != null ? currentReq.getURI() : "") : loginRequest.getURI().toString());
            
            logger.debug("Final URL after login: {}", finalUrlAfterLogin);
            
                    // Update cookies from the response
            for (Cookie cookie : cookieStore.getCookies()) {
                        finalCookies.put(cookie.getName(), cookie.getValue());
                logger.debug("Cookie: {} = {}", cookie.getName(), cookie.getValue());
                    }
                    
                    // Read the response content
                    HttpEntity loginEntity = loginResponse.getEntity();
                    if (loginEntity != null) {
                        responseBodyLogin = EntityUtils.toString(loginEntity);
                        EntityUtils.consume(loginEntity);
                    }
                    
                    // Parse the login response
                    Document loginDoc = Jsoup.parse(responseBodyLogin);
                    
                    // Check if we have a form that needs to be submitted (OIDC authorization)
                    Element oidcForm = loginDoc.selectFirst("form");
                    if (oidcForm != null && oidcForm.attr("action").contains("openid-connect")) {
                        String oidcAction = oidcForm.attr("action");
                        logger.debug("Found OIDC form with action: {}", oidcAction);
                        
                        // Submit the OIDC form to complete the flow
                        HttpPost oidcRequest = new HttpPost(oidcAction);
                        
                        // Add the same headers
                        oidcRequest.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
                        oidcRequest.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
                        oidcRequest.addHeader("Accept-Language", "en-US,en;q=0.5");
                        oidcRequest.addHeader("Content-Type", "application/x-www-form-urlencoded");
                        oidcRequest.addHeader("Origin", "https://idp.bielefeld-marienschule.logoip.de");
                        oidcRequest.addHeader("Referer", oidcAction);
                        
                        List<NameValuePair> oidcParams = new ArrayList<>();
                        // Add any hidden fields from the form
                        for (Element input : oidcForm.select("input[type=hidden]")) {
                            oidcParams.add(new BasicNameValuePair(input.attr("name"), input.attr("value")));
                        }
                        oidcRequest.setEntity(new UrlEncodedFormEntity(oidcParams));
                        
                        CloseableHttpResponse oidcResponse = null;
                        try {
                            // Execute with context to maintain state
                            oidcResponse = httpClient.execute(oidcRequest, context);
                            logger.debug("OIDC response status: {}", oidcResponse.getStatusLine());
                            
                            // Check if we need to follow another redirect
                            if (oidcResponse.getStatusLine().getStatusCode() >= 300 && oidcResponse.getStatusLine().getStatusCode() < 400) {
                                Header locationHeader = oidcResponse.getFirstHeader("Location");
                                if (locationHeader != null) {
                                    String redirectUrl = locationHeader.getValue();
                                    logger.debug("Following OIDC redirect to: {}", redirectUrl);
                                    
                                    HttpGet redirectRequest = new HttpGet(redirectUrl);
                                    // Add the same headers
                                    redirectRequest.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
                                    redirectRequest.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
                                    redirectRequest.addHeader("Accept-Language", "en-US,en;q=0.5");
                                    
                                    CloseableHttpResponse redirectResponse = null;
                                    try {
                                        redirectResponse = httpClient.execute(redirectRequest, context);
                                        logger.debug("Redirect response status: {}", redirectResponse.getStatusLine());
                                        
                                        // Ensure the entity is fully consumed
                                        HttpEntity redirectEntity = redirectResponse.getEntity();
                                        if (redirectEntity != null) {
                                            EntityUtils.consume(redirectEntity);
                                        }
                                    } finally {
                                        if (redirectResponse != null) {
                                            redirectResponse.close();
                                        }
                                    }
                                }
                            }
                            
                            // Update cookies after OIDC flow
                            for (Cookie cookie : cookieStore.getCookies()) {
                                finalCookies.put(cookie.getName(), cookie.getValue());
                                logger.debug("Final cookie: {} = {}", cookie.getName(), cookie.getValue());
                            }
                            
                            // Ensure the entity is fully consumed
                            HttpEntity oidcEntity = oidcResponse.getEntity();
                            if (oidcEntity != null) {
                                EntityUtils.consume(oidcEntity);
                            }
                        } finally {
                            if (oidcResponse != null) {
                                oidcResponse.close();
                            }
                        }
                    }
                    
                    // Make a final request to Nextcloud to verify the session
                    HttpGet verifyRequest = new HttpGet(NEXTCLOUD_USER_SETTINGS_URL);
                    
                    // Add the same headers
                    verifyRequest.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
                    verifyRequest.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
                    verifyRequest.addHeader("Accept-Language", "en-US,en;q=0.5");
                    
                    CloseableHttpResponse verifyResponse = null;
                    try {
                        verifyResponse = httpClient.execute(verifyRequest, context);
                        logger.debug("Verification response status: {}", verifyResponse.getStatusLine());
                        
                        // Update cookies after verification
                        for (Cookie cookie : cookieStore.getCookies()) {
                            finalCookies.put(cookie.getName(), cookie.getValue());
                            logger.debug("Verification cookie: {} = {}", cookie.getName(), cookie.getValue());
                        }
                        
                        // Ensure the entity is fully consumed
                        HttpEntity verifyEntity = verifyResponse.getEntity();
                        if (verifyEntity != null) {
                            EntityUtils.consume(verifyEntity);
                        }
                    } finally {
                        if (verifyResponse != null) {
                            verifyResponse.close();
                        }
                    }
                } finally {
                    if (loginResponse != null) {
                        loginResponse.close();
                    }
                }
                
                // Check if login was successful by looking for session cookies
                boolean hasSessionCookie = finalCookies.containsKey("oc_sessionPassphrase");
                logger.debug("Login successful, got valid session cookies: {}", hasSessionCookie);
            
            // Create a mock Jsoup Response to maintain compatibility with existing code
                final int finalStatusCode = statusCodeLogin;
                final String finalResponseBody = responseBodyLogin;
                final Map<String, String> finalResponseCookies = new HashMap<>(finalCookies);
                
                // Create a mock Jsoup Response
            return new Connection.Response() {
                    private final int responseCode = finalStatusCode;
                    private final String responseBody = finalResponseBody;
                private final Map<String, String> responseHeaders = new HashMap<>();
                    private final Map<String, String> responseCookies = finalResponseCookies;
                
                @Override
                public int statusCode() {
                        return responseCode;
                }
                
                @Override
                public String statusMessage() {
                        return "";
                }
                
                @Override
                public String charset() {
                    return "UTF-8";
                }
                
                @Override
                public Connection.Response charset(String charset) {
                    return this;
                }
                
                @Override
                public Map<String, String> cookies() {
                    return responseCookies;
                }
                
                @Override
                public boolean hasCookie(String name) {
                    return responseCookies.containsKey(name);
                }
                
                @Override
                public String cookie(String name) {
                    return responseCookies.get(name);
                }
                
                @Override
                public Connection.Response cookie(String name, String value) {
                    responseCookies.put(name, value);
                    return this;
                }
                
                @Override
                public Connection.Method method() {
                        return Connection.Method.GET;
                }
                
                @Override
                public Connection.Response method(Connection.Method method) {
                    return this;
                }
                
                @Override
                public Document parse() throws IOException {
                    return Jsoup.parse(responseBody);
                }

                @Override
                public String body() {
                    return responseBody;
                }

                @Override
                public byte[] bodyAsBytes() {
                    return responseBody.getBytes(StandardCharsets.UTF_8);
                }
                
                @Override
                public java.io.BufferedInputStream bodyStream() {
                        return new java.io.BufferedInputStream(
                                new java.io.ByteArrayInputStream(bodyAsBytes()));
                }

                @Override
                public Connection.Response bufferUp() {
                    return this;
                }

                @Override
                public String contentType() {
                    return "text/html";
                }

                @Override
                public String header(String name) {
                    return responseHeaders.get(name);
                }

                @Override
                public Connection.Response header(String name, String value) {
                    responseHeaders.put(name, value);
                    return this;
                }

                @Override
                public Map<String, String> headers() {
                    return responseHeaders;
                }

                @Override
                public boolean hasHeader(String name) {
                    return responseHeaders.containsKey(name);
                }

                @Override
                public boolean hasHeaderWithValue(String name, String value) {
                        return value.equals(responseHeaders.get(name));
                }

                @Override
                public Connection.Response removeHeader(String name) {
                    responseHeaders.remove(name);
                    return this;
                }

                @Override
                public URL url() {
                    try {
                            return new URL(NEXTCLOUD_LOGIN_URL);
                        } catch (MalformedURLException e) {
                        return null;
                    }
                }

                @Override
                public Connection.Response url(URL url) {
                    return this;
                }

                @Override
                public Connection.Response addHeader(String name, String value) {
                    responseHeaders.put(name, value);
                    return this;
                }

                @Override
                public Connection.Response removeCookie(String name) {
                    responseCookies.remove(name);
                    return this;
                }

                @Override
                public Map<String, List<String>> multiHeaders() {
                        Map<String, List<String>> result = new HashMap<>();
                        for (Map.Entry<String, String> entry : responseHeaders.entrySet()) {
                            result.put(entry.getKey(), Collections.singletonList(entry.getValue()));
                        }
                        return result;
                }

                @Override
                public List<String> headers(String name) {
                    String value = responseHeaders.get(name);
                    return value != null ? Collections.singletonList(value) : Collections.emptyList();
                }
            };
            } else {
                logger.error("No login form found in the response");
                throw new IOException("No login form found in the response");
            }
        } catch (Exception e) {
            logger.error("Error during login process", e);
            throw new IOException("Error during login process", e);
        } finally {
            // Properly close the HTTP client
            if (httpClient != null) {
                try {
                    httpClient.close();
                } catch (IOException e) {
                    logger.warn("Error closing HTTP client", e);
                }
            }
        }
    }
    
    /**
     * Fetches user information from the Nextcloud API using the authenticated session
     */
    private Map<String, String> fetchUserInfoFromApi(String username, Map<String, String> cookies) {
        Map<String, String> userInfo = new HashMap<>();
        
        try {
            // Create HTTP client with cookies from the authenticated session
            CookieStore cookieStore = new BasicCookieStore();
            for (Map.Entry<String, String> cookie : cookies.entrySet()) {
                BasicClientCookie clientCookie = new BasicClientCookie(cookie.getKey(), cookie.getValue());
                clientCookie.setDomain("nextcloud-g2.bielefeld-marienschule.logoip.de");
                clientCookie.setPath("/");
                cookieStore.addCookie(clientCookie);
            }
            
            // Create a custom HttpClientContext to maintain state between requests
            HttpClientContext context = HttpClientContext.create();
            context.setCookieStore(cookieStore);
            
            RequestConfig requestConfig = RequestConfig.custom()
                .setConnectTimeout(10000)
                .setSocketTimeout(10000)
                .setRedirectsEnabled(true)
                .build();
            
            try (CloseableHttpClient httpClient = HttpClients.custom()
                .setDefaultRequestConfig(requestConfig)
                .setDefaultCookieStore(cookieStore)
                .build()) {
                
                // First try to get user info from the Nextcloud API
                logger.debug("Fetching user info from Nextcloud API for user: {}", username);
                
                // Try to get user data from the OCS API
                HttpGet userApiGet = new HttpGet(NEXTCLOUD_USER_API_URL);
                userApiGet.addHeader("OCS-APIRequest", "true");
                userApiGet.addHeader("Accept", "application/json");
                userApiGet.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
                
                // Add authorization header if we have a session cookie
                if (cookies.containsKey("oc_sessionPassphrase")) {
                    String sessionId = cookies.get("oc_sessionPassphrase");
                    userApiGet.addHeader("Cookie", "oc_sessionPassphrase=" + sessionId);
                }
                
                try (CloseableHttpResponse response = httpClient.execute(userApiGet, context)) {
                    int statusCode = response.getStatusLine().getStatusCode();
                    logger.debug("API response status: {}", statusCode);
                    
                    // Log all headers for debugging
                    for (Header header : response.getAllHeaders()) {
                        logger.debug("Response header: {} = {}", header.getName(), header.getValue());
                    }
                    
                    // Log all cookies for debugging
                    for (Cookie cookie : cookieStore.getCookies()) {
                        logger.debug("Cookie after API call: {} = {}", cookie.getName(), cookie.getValue());
                    }
                    
                    if (statusCode == 200) {
                        HttpEntity entity = response.getEntity();
                        if (entity != null) {
                            String responseBody = EntityUtils.toString(entity);
                            logger.debug("API response body: {}", responseBody);
                            
                            // Parse JSON response
                            try {
                                JsonNode rootNode = objectMapper.readTree(responseBody);
                                JsonNode dataNode = rootNode.path("ocs").path("data");
                                
                                if (!dataNode.isMissingNode()) {
                                    userInfo.put("email", dataNode.path("email").asText(""));
                                    userInfo.put("displayname", dataNode.path("displayname").asText(""));
                                    userInfo.put("groups", dataNode.path("groups").toString());
                                    logger.debug("Successfully extracted user info from API: {}", userInfo);
                                    return userInfo;
                                }
        } catch (Exception e) {
                                logger.warn("Error parsing API response: {}", e.getMessage());
                            }
                        }
                    } else if (statusCode == 401) {
                        logger.warn("Unauthorized access to Nextcloud API. Session may have expired.");
                        
                        // Try to refresh the session by accessing the user settings page
                        HttpGet settingsGet = new HttpGet(NEXTCLOUD_USER_SETTINGS_URL);
                        settingsGet.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
                        settingsGet.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
                        
                        try (CloseableHttpResponse settingsResponse = httpClient.execute(settingsGet, context)) {
                            logger.debug("Settings page response status: {}", settingsResponse.getStatusLine());
                            
                            // Try the API call again after refreshing the session
                            try (CloseableHttpResponse retryResponse = httpClient.execute(userApiGet, context)) {
                                logger.debug("Retry API response status: {}", retryResponse.getStatusLine());
                                
                                if (retryResponse.getStatusLine().getStatusCode() == 200) {
                                    HttpEntity retryEntity = retryResponse.getEntity();
                                    if (retryEntity != null) {
                                        String retryResponseBody = EntityUtils.toString(retryEntity);
                                        logger.debug("Retry API response body: {}", retryResponseBody);
                                        
                                        // Parse JSON response
                                        try {
                                            JsonNode rootNode = objectMapper.readTree(retryResponseBody);
                                            JsonNode dataNode = rootNode.path("ocs").path("data");
                                            
                                            if (!dataNode.isMissingNode()) {
                                                userInfo.put("email", dataNode.path("email").asText(""));
                                                userInfo.put("displayname", dataNode.path("displayname").asText(""));
                                                userInfo.put("groups", dataNode.path("groups").toString());
                                                logger.debug("Successfully extracted user info from API after retry: {}", userInfo);
                                                return userInfo;
                                            }
                                        } catch (Exception e) {
                                            logger.warn("Error parsing API retry response: {}", e.getMessage());
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // If API call fails, fall back to scraping the user settings page
                logger.debug("API call failed, falling back to scraping user settings page");
                Document userSettingsDoc = fetchUserSettingsPage(httpClient, cookies);
                
                if (userSettingsDoc != null) {
                    // Extract user information from the settings page
                    String fullName = extractFullName(userSettingsDoc);
                    String[] nameParts = extractNameParts(fullName);
                    String firstName = nameParts[0];
                    String lastName = nameParts[1];
                    String email = extractEmail(userSettingsDoc);
                    String schoolClass = extractSchoolClass(userSettingsDoc);
                    
                    userInfo.put("firstName", firstName);
                    userInfo.put("lastName", lastName);
                    userInfo.put("email", email);
                    userInfo.put("schoolClass", schoolClass);
                    
                    logger.debug("Successfully extracted user info from settings page: {}", userInfo);
                }
            }
        } catch (Exception e) {
            logger.error("Error fetching user info from API", e);
        }
        
        return userInfo;
    }
    
    /**
     * Fetches the user settings page using the authenticated session
     */
    private Document fetchUserSettingsPage(CloseableHttpClient httpClient, Map<String, String> cookies) throws IOException {
        logger.debug("Fetching user settings from: {}", NEXTCLOUD_USER_SETTINGS_URL);
        
        try {
            // Create a custom HttpClientContext to maintain state between requests
            HttpClientContext context = HttpClientContext.create();
            
            // Add cookies to the context if not already in the httpClient
            if (!cookies.isEmpty()) {
                CookieStore cookieStore = new BasicCookieStore();
                for (Map.Entry<String, String> cookie : cookies.entrySet()) {
                    BasicClientCookie clientCookie = new BasicClientCookie(cookie.getKey(), cookie.getValue());
                    clientCookie.setDomain("nextcloud-g2.bielefeld-marienschule.logoip.de");
                    clientCookie.setPath("/");
                    cookieStore.addCookie(clientCookie);
                }
                context.setCookieStore(cookieStore);
            }
            
            HttpGet settingsGet = new HttpGet(NEXTCLOUD_USER_SETTINGS_URL);
            
            // Add headers to mimic a browser
            settingsGet.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
            settingsGet.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
            settingsGet.addHeader("Accept-Language", "en-US,en;q=0.5");
            
            // Add cookie header directly if we have a session cookie
            if (cookies.containsKey("oc_sessionPassphrase")) {
                String sessionId = cookies.get("oc_sessionPassphrase");
                settingsGet.addHeader("Cookie", "oc_sessionPassphrase=" + sessionId);
            }
            
            try (CloseableHttpResponse settingsResponse = httpClient.execute(settingsGet, context)) {
                int statusCode = settingsResponse.getStatusLine().getStatusCode();
                logger.debug("Settings page response status: {}", statusCode);
                
                // Log all headers for debugging
                for (Header header : settingsResponse.getAllHeaders()) {
                    logger.debug("Settings response header: {} = {}", header.getName(), header.getValue());
                }
                
                if (statusCode == 200) {
                    HttpEntity entity = settingsResponse.getEntity();
                    if (entity != null) {
                        String settingsBody = EntityUtils.toString(entity, StandardCharsets.UTF_8);
                        return Jsoup.parse(settingsBody);
                    }
                } else {
                    logger.warn("Failed to fetch settings page, status code: {}", statusCode);
                }
            }
            
            // Return an empty document to avoid null pointer exceptions
            return Jsoup.parse("<html><body></body></html>");
        } catch (Exception e) {
            logger.warn("Error fetching user settings: {}", e.getMessage());
            // Return an empty document to avoid null pointer exceptions
            return Jsoup.parse("<html><body></body></html>");
        }
    }
    
    /**
     * Extracts school class information from Nextcloud groups
     */
    private String extractSchoolClassFromGroups(String groupsJson) {
        try {
            JsonNode groupsNode = objectMapper.readTree(groupsJson);
            if (groupsNode.isArray()) {
                for (JsonNode group : groupsNode) {
                    String groupName = group.asText();
                    // Look for groups that match class patterns like "10a", "5b", "Q1", "Q2", etc.
                    if (groupName.matches("\\d+[a-z]") || groupName.matches("Q[12]")) {
                        return groupName;
                    }
                }
            }
        } catch (Exception e) {
            logger.warn("Error parsing groups JSON: {}", e.getMessage());
        }
        return "";
    }
    
    /**
     * Extrahiert den vollständigen Namen aus den Dokumentelementen
     */
    private String extractFullName(Document userSettingsDoc) {
        Elements nameElements = userSettingsDoc.select("[data-v-55600bf5]");
        logger.trace("Found {} name elements", nameElements.size());
        
        if (!nameElements.isEmpty()) {
            String fullName = nameElements.text().trim();
            logger.debug("Full name found: '{}'", fullName);
            return fullName;
        }
        
        logger.warn("No name elements found");
        return "";
    }
    
    /**
     * Teilt den vollständigen Namen in Vor- und Nachname
     */
    private String[] extractNameParts(String fullName) {
        if (fullName.isEmpty()) {
            logger.warn("Full name is empty");
            return new String[]{"", ""};
        }
        
        String[] nameParts = fullName.split(" ");
        logger.trace("Name parts: {}", (Object) nameParts);
        
        if (nameParts.length > 1) {
            String lastName = nameParts[nameParts.length - 1];
            
            // Konstruiere den Vornamen aus allen Teilen außer dem letzten
            StringBuilder firstNameBuilder = new StringBuilder();
            for (int i = 0; i < nameParts.length - 1; i++) {
                if (i > 0) {
                    firstNameBuilder.append(" ");
                }
                firstNameBuilder.append(nameParts[i]);
            }
            
            String firstName = firstNameBuilder.toString();
            logger.debug("Parsed name - First Name: '{}', Last Name: '{}'", firstName, lastName);
            
            return new String[]{firstName, lastName};
        }
        
        // Wenn nur ein Namensteil vorhanden ist
        logger.debug("Only one name part found: '{}'", fullName);
        return new String[]{fullName, ""};
    }
    
    /**
     * Extrahiert die E-Mail-Adresse
     */
    private String extractEmail(Document userSettingsDoc) {
        Elements emailElements = userSettingsDoc.select("[data-v-3670cfbc]");
        if (!emailElements.isEmpty()) {
            String email = emailElements.text().trim();
            logger.debug("Email found: '{}'", email);
            return email;
        }
        
        logger.warn("No email elements found");
        return "";
    }
    
    /**
     * Extrahiert die Schulklasse
     */
    private String extractSchoolClass(Document userSettingsDoc) {
        Elements classElements = userSettingsDoc.select("[data-v-29a613a4]");
        if (!classElements.isEmpty()) {
            String classText = classElements.text().trim();
            logger.trace("Class text: '{}'", classText);
            
            int commaIndex = classText.indexOf(',');
            if (commaIndex > 0) {
                try {
                    String schoolClass = classText.substring(0, commaIndex).trim();
                    logger.debug("School class extracted: '{}'", schoolClass);
                    return schoolClass;
                } catch (Exception e) {
                    logger.warn("Error extracting school class", e);
                    return classText;
                }
            }
            
            logger.debug("No comma found in class text, using full text: '{}'", classText);
            return classText;
        }
        
        logger.warn("No class elements found");
        return "";
    }
    
    /**
     * Extrahiert die WebDAV-URL
     */
    private String extractWebdavUrl(Map<String, String> cookies) throws IOException {
        logger.trace("Attempting to extract WebDAV URL from: {}", NEXTCLOUD_FILES_URL);
        
        // First try the direct WebDAV URL based on the username
        // This is the most reliable method with the API
        try {
            // Try to extract username from cookies or URL
            for (Map.Entry<String, String> cookie : cookies.entrySet()) {
                if (cookie.getKey().equals("nc_username")) {
                    String username = cookie.getValue();
                    if (username != null && !username.isEmpty()) {
                        String webdavUrl = NEXTCLOUD_WEBDAV_URL + username;
                        logger.debug("WebDAV URL constructed from username: '{}'", webdavUrl);
                        return webdavUrl;
                    }
                }
            }
            
            // If username not found in cookies, try to fetch it from the files page
            CookieStore cookieStore = new BasicCookieStore();
            for (Map.Entry<String, String> cookie : cookies.entrySet()) {
                BasicClientCookie clientCookie = new BasicClientCookie(cookie.getKey(), cookie.getValue());
                clientCookie.setDomain("nextcloud-g2.bielefeld-marienschule.logoip.de");
                clientCookie.setPath("/");
                cookieStore.addCookie(clientCookie);
            }
            
            // Create a custom HttpClientContext to maintain state between requests
            HttpClientContext context = HttpClientContext.create();
            context.setCookieStore(cookieStore);
            
            RequestConfig requestConfig = RequestConfig.custom()
                .setConnectTimeout(10000)
                .setSocketTimeout(10000)
                .setRedirectsEnabled(true)
                .build();
            
            try (CloseableHttpClient httpClient = HttpClients.custom()
                .setDefaultRequestConfig(requestConfig)
                .setDefaultCookieStore(cookieStore)
                .build()) {
                
                HttpGet filesGet = new HttpGet(NEXTCLOUD_FILES_URL);
                
                // Add headers to mimic a browser
                filesGet.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
                filesGet.addHeader("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8");
                filesGet.addHeader("Accept-Language", "en-US,en;q=0.5");
                
                // Add cookie header directly if we have a session cookie
                if (cookies.containsKey("oc_sessionPassphrase")) {
                    String sessionId = cookies.get("oc_sessionPassphrase");
                    filesGet.addHeader("Cookie", "oc_sessionPassphrase=" + sessionId);
                }
                
                try (CloseableHttpResponse filesResponse = httpClient.execute(filesGet, context)) {
                    int statusCode = filesResponse.getStatusLine().getStatusCode();
                    logger.debug("Files page response status: {}", statusCode);
                    
                    if (statusCode == 200) {
                        HttpEntity entity = filesResponse.getEntity();
                        if (entity != null) {
                            String filesBody = EntityUtils.toString(entity, StandardCharsets.UTF_8);
                            Document filesDoc = Jsoup.parse(filesBody);
                            
                            // Try to extract username from the page
                            Element userElement = filesDoc.selectFirst("div#settings div.avatardiv");
                            if (userElement != null) {
                                String dataUser = userElement.attr("data-user");
                                if (dataUser != null && !dataUser.isEmpty()) {
                                    String webdavUrl = NEXTCLOUD_WEBDAV_URL + dataUser;
                                    logger.debug("WebDAV URL constructed from page data-user: '{}'", webdavUrl);
                return webdavUrl;
                                }
                            }
                            
                            // Try to extract from script data
                            Pattern pattern = Pattern.compile("OC.currentUser\\s*=\\s*['\"]([^'\"]+)['\"]");
                            Matcher matcher = pattern.matcher(filesBody);
                            if (matcher.find()) {
                                String username = matcher.group(1);
                                String webdavUrl = NEXTCLOUD_WEBDAV_URL + username;
                                logger.debug("WebDAV URL constructed from script data: '{}'", webdavUrl);
                                return webdavUrl;
                            }
                        }
                    }
                }
            }
            
            // If all else fails, return a default URL
            logger.warn("Could not extract WebDAV URL, using default");
            return NEXTCLOUD_WEBDAV_URL + "remote.php/dav/files/";
        } catch (Exception e) {
            logger.error("Error extracting WebDAV URL", e);
            return NEXTCLOUD_WEBDAV_URL;
        }
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

    /**
     * Extrahiert Benutzerdaten aus Nextcloud mit Selenium WebDriver
     * 
     * @param username Benutzername für Nextcloud
     * @param password Passwort für Nextcloud
     * @return Map mit extrahierten Benutzerdaten und Status
     */
    public Map<String, Object> extractUserDataWithSelenium(String username, String password) {
        Map<String, Object> result = new HashMap<>();
        WebDriver driver = null;
        
        logger.info("Starting extraction of user data from Nextcloud using Selenium for user: {}", username);
        
        try {
            // Set ChromeDriver path if not already set
            if (System.getProperty("webdriver.chrome.driver") == null) {
                System.setProperty("webdriver.chrome.driver", chromeDriverPath);
                logger.debug("Set ChromeDriver path to: {}", chromeDriverPath);
            }
            
            // Create screenshots directory if it doesn't exist
            File screenshotsDirFile = new File(screenshotsDirectory);
            if (!screenshotsDirFile.exists()) {
                screenshotsDirFile.mkdirs();
                logger.debug("Created screenshots directory: {}", screenshotsDirectory);
            }

            // Set up Chrome options for headless mode
            ChromeOptions options = new ChromeOptions();
            options.addArguments("--headless=new");
            options.addArguments("--disable-gpu");
            options.addArguments("--window-size=1920,1080");
            options.addArguments("--no-sandbox");
            options.addArguments("--disable-dev-shm-usage");
            options.addArguments("--disable-extensions");
            options.addArguments("--disable-infobars");
            options.addArguments("--remote-allow-origins=*");
            
            // Add Linux-specific options if running on Linux
            String osName = System.getProperty("os.name").toLowerCase();
            if (osName.contains("linux")) {
                logger.debug("Running on Linux, adding Linux-specific options");
                options.addArguments("--disable-setuid-sandbox");
                options.addArguments("--single-process");
                options.setBinary("/usr/bin/google-chrome"); // Default Linux Chrome path
            }

            // Initialize WebDriver
            driver = new ChromeDriver(options);
            logger.debug("WebDriver initialized successfully");
            
            // Extract user data
            JSONObject userData = extractUserDataFromNextcloudWithSelenium(driver, username, password);
            
            // Save user data to JSON file
            String firstName = userData.optString("firstName", "");
            String lastName = userData.optString("lastName", "");
            String email = userData.optString("email", "");
            String schoolClass = userData.optString("class", "");
            String webdavUrl = userData.optString("webdavUrl", "");
            
            // Save to JSON file and get user ID
            int userId = saveUserToJsonFile(username, firstName, lastName, email, schoolClass, webdavUrl);
            
            // Prepare result
            result.put("success", true);
            result.put("user_id", userId);
            result.put("username", username);
            result.put("first_name", firstName);
            result.put("last_name", lastName);
            result.put("email", email);
            result.put("school_class", schoolClass);
            result.put("webdav_url", webdavUrl);
            
        } catch (Exception e) {
            logger.error("Error extracting user data with Selenium", e);
            result.put("success", false);
            result.put("message", "Extraction failed: " + e.getMessage());
        } finally {
            // Close WebDriver
            if (driver != null) {
                try {
                    driver.quit();
                    logger.debug("WebDriver closed successfully");
                } catch (Exception e) {
                    logger.error("Error closing WebDriver", e);
                }
            }
        }
        
        return result;
    }
    
    /**
     * Extrahiert Benutzerdaten aus Nextcloud mit Selenium WebDriver
     */
    private JSONObject extractUserDataFromNextcloudWithSelenium(WebDriver driver, String username, String password) {
        JSONObject userData = new JSONObject();
        userData.put("username", username);
        
        try {
            logger.debug("Step 1: Logging in to Nextcloud...");
            driver.get(NEXTCLOUD_LOGIN_URL);
            
            // Take a screenshot of the login page
            takeScreenshot(driver, "login_page.png");
            
            // Find and interact with login form elements
            WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
            
            // Find username field
            WebElement usernameField = findUsernameField(driver);
            if (usernameField == null) {
                throw new RuntimeException("Could not find username field");
            }
            
            // Enter username
            usernameField.sendKeys(username);
            
            // Find password field
            WebElement passwordField = findPasswordField(driver);
            if (passwordField == null) {
                throw new RuntimeException("Could not find password field");
            }
            
            // Enter password
            passwordField.sendKeys(password);
            
            // Find login button
            WebElement loginButton = findLoginButton(driver);
            if (loginButton == null) {
                throw new RuntimeException("Could not find login button");
            }
            
            // Take screenshot before clicking login button
            takeScreenshot(driver, "before_login.png");
            
            // Click login button
            loginButton.click();
            
            // Wait for page to load
            Thread.sleep(3000);
            
            // Navigate to settings page
            logger.debug("Step 2: Navigating to settings page...");
            driver.get(NEXTCLOUD_USER_SETTINGS_URL);
            
            // Wait for settings page to load
            try {
                wait.until(ExpectedConditions.or(
                    ExpectedConditions.titleContains("Einstellungen"),
                    ExpectedConditions.titleContains("Settings"),
                    ExpectedConditions.titleContains("Persönliche Informationen")
                ));
                logger.debug("Settings page loaded. Title: {}", driver.getTitle());
                takeScreenshot(driver, "settings_page.png");
            } catch (Exception e) {
                logger.error("Error waiting for settings page", e);
                takeScreenshot(driver, "settings_error.png");
                throw new RuntimeException("Could not load settings page", e);
            }
            
            // Extract full name
            extractFullNameWithSelenium(driver, userData);
            
            // Extract email
            extractEmailWithSelenium(driver, userData);
            
            // Extract school class/group
            extractSchoolClassWithSelenium(driver, userData);
            
            // Extract WebDAV URL
            extractWebdavUrlWithSelenium(driver, userData);
            
            logger.info("Extracted user data: {}", userData.toString());
            
        } catch (Exception e) {
            logger.error("Error extracting user data", e);
            throw new RuntimeException("Error extracting user data: " + e.getMessage(), e);
        }
        
        return userData;
    }
    
    /**
     * Find username field using different selectors
     */
    private WebElement findUsernameField(WebDriver driver) {
        try {
            return driver.findElement(By.id("username"));
        } catch (Exception e) {
            logger.debug("Username field not found with ID 'username'");
            try {
                return driver.findElement(By.name("username"));
            } catch (Exception e2) {
                logger.debug("Username field not found with name 'username'");
                try {
                    return driver.findElement(By.cssSelector("input[type='text']"));
                } catch (Exception e3) {
                    logger.debug("Username field not found with CSS selector 'input[type=\"text\"]'");
                    return null;
                }
            }
        }
    }
    
    /**
     * Find password field using different selectors
     */
    private WebElement findPasswordField(WebDriver driver) {
        try {
            return driver.findElement(By.id("password"));
        } catch (Exception e) {
            logger.debug("Password field not found with ID 'password'");
            try {
                return driver.findElement(By.name("password"));
            } catch (Exception e2) {
                logger.debug("Password field not found with name 'password'");
                try {
                    return driver.findElement(By.cssSelector("input[type='password']"));
                } catch (Exception e3) {
                    logger.debug("Password field not found with CSS selector 'input[type=\"password\"]'");
                    return null;
                }
            }
        }
    }
    
    /**
     * Find login button using different selectors
     */
    private WebElement findLoginButton(WebDriver driver) {
        try {
            return driver.findElement(By.id("kc-login"));
        } catch (Exception e) {
            logger.debug("Login button not found with ID 'kc-login'");
            try {
                return driver.findElement(By.cssSelector("button[type='submit']"));
            } catch (Exception e2) {
                logger.debug("Login button not found with CSS selector 'button[type=\"submit\"]'");
                try {
                    return driver.findElement(By.cssSelector("input[type='submit']"));
                } catch (Exception e3) {
                    logger.debug("Login button not found with CSS selector 'input[type=\"submit\"]'");
                    return null;
                }
            }
        }
    }
    
    /**
     * Extract full name from settings page
     */
    private void extractFullNameWithSelenium(WebDriver driver, JSONObject userData) {
        boolean nameFound = false;
        try {
            // Try to extract full name from span element with data-v-55600bf5
            WebElement nameSpan = driver.findElement(By.cssSelector("span[data-v-55600bf5]"));
            if (nameSpan != null) {
                String fullName = nameSpan.getText().trim();
                logger.debug("Full name (from span[data-v-55600bf5]): {}", fullName);
                userData.put("fullName", fullName);
                
                // Try to extract first and last name
                String[] nameParts = extractNameParts(fullName);
                if (nameParts.length == 2) {
                    userData.put("firstName", nameParts[0]);
                    userData.put("lastName", nameParts[1]);
                    nameFound = true;
                }
            }
        } catch (Exception e) {
            logger.debug("Could not find span element for full name: {}", e.getMessage());
            
            // Alternative method: Search for name in page structure
            try {
                WebElement userMenuButton = driver.findElement(By.cssSelector("div#settings div.user-info__header-full-name"));
                if (userMenuButton != null) {
                    String fullName = userMenuButton.getText().trim();
                    logger.debug("Full name (from menu): {}", fullName);
                    userData.put("fullName", fullName);
                    
                    // Try to extract first and last name
                    String[] nameParts = extractNameParts(fullName);
                    if (nameParts.length == 2) {
                        userData.put("firstName", nameParts[0]);
                        userData.put("lastName", nameParts[1]);
                        nameFound = true;
                    }
                }
            } catch (Exception e2) {
                logger.debug("Could not find name in user menu: {}", e2.getMessage());
                
                // Try to extract name from page source
                String pageSource = driver.getPageSource();
                Pattern namePattern = Pattern.compile("\"displayName\":\\s*\"([^\"]+)\"");
                Matcher nameMatcher = namePattern.matcher(pageSource);
                if (nameMatcher.find()) {
                    String fullName = nameMatcher.group(1);
                    logger.debug("Full name (from source code): {}", fullName);
                    userData.put("fullName", fullName);
                    
                    // Try to extract first and last name
                    String[] nameParts = extractNameParts(fullName);
                    if (nameParts.length == 2) {
                        userData.put("firstName", nameParts[0]);
                        userData.put("lastName", nameParts[1]);
                        nameFound = true;
                    }
                }
            }
        }
        
        if (!nameFound) {
            logger.warn("Could not extract name!");
        }
    }
    
    /**
     * Extract email from settings page
     */
    private void extractEmailWithSelenium(WebDriver driver, JSONObject userData) {
        boolean emailFound = false;
        try {
            // Try to extract email from span element with data-v-3670cfbc
            WebElement emailSpan = driver.findElement(By.cssSelector("span[data-v-3670cfbc]"));
            if (emailSpan != null) {
                String email = emailSpan.getText().trim();
                logger.debug("Email (from span[data-v-3670cfbc]): {}", email);
                userData.put("email", email);
                emailFound = true;
            }
        } catch (Exception e) {
            logger.debug("Could not find span element for email: {}", e.getMessage());
            
            // Fallback: Try to extract email from input field
            try {
                WebElement emailElement = driver.findElement(By.id("email"));
                if (emailElement != null) {
                    String email = emailElement.getAttribute("value");
                    logger.debug("Email (from input field): {}", email);
                    userData.put("email", email);
                    emailFound = true;
                }
            } catch (Exception e1) {
                logger.debug("Could not find input field for email: {}", e1.getMessage());
                
                // Try to extract email from page source
                String pageSource = driver.getPageSource();
                Pattern emailPattern = Pattern.compile("\"email\":\\s*\"([^\"]+)\"");
                Matcher emailMatcher = emailPattern.matcher(pageSource);
                if (emailMatcher.find()) {
                    String email = emailMatcher.group(1);
                    logger.debug("Email (from source code): {}", email);
                    userData.put("email", email);
                    emailFound = true;
                }
            }
        }
        
        if (!emailFound) {
            logger.warn("Could not extract email!");
        }
    }
    
    /**
     * Extract school class/group from settings page
     */
    private void extractSchoolClassWithSelenium(WebDriver driver, JSONObject userData) {
        boolean groupsFound = false;
        try {
            // Try to extract groups from span element with data-v-29a613a4 and class details__groups-list
            WebElement groupsSpan = driver.findElement(By.cssSelector("span[data-v-29a613a4].details__groups-list"));
            if (groupsSpan != null) {
                String groupsText = groupsSpan.getText().trim();
                logger.debug("Groups (from span[data-v-29a613a4].details__groups-list): {}", groupsText);
                
                // Split text into individual groups
                String[] groupsArray = groupsText.split(",");
                
                // Extract class as first group before first comma
                if (groupsArray.length > 0) {
                    String firstGroup = groupsArray[0].trim();
                    logger.debug("First group (class): {}", firstGroup);
                    userData.put("class", firstGroup);
                }
                
                groupsFound = true;
            }
        } catch (Exception e) {
            logger.debug("Could not find span element for groups: {}", e.getMessage());
            
            // Try alternative selectors
            try {
                // Try to find groups with another selector
                WebElement groupsElement = driver.findElement(By.cssSelector(".details__groups-list"));
                if (groupsElement != null) {
                    String groupsText = groupsElement.getText().trim();
                    logger.debug("Groups (from .details__groups-list): {}", groupsText);
                    
                    // Split text into individual groups
                    String[] groupsArray = groupsText.split(",");
                    
                    // Extract class as first group before first comma
                    if (groupsArray.length > 0) {
                        String firstGroup = groupsArray[0].trim();
                        logger.debug("First group (class): {}", firstGroup);
                        userData.put("class", firstGroup);
                    }
                    
                    groupsFound = true;
                }
            } catch (Exception e2) {
                logger.debug("Could not find element with class details__groups-list: {}", e2.getMessage());
                
                // Try another alternative selector
                try {
                    WebElement groupsElement = driver.findElement(By.cssSelector("span[data-v-29a613a4]"));
                    if (groupsElement != null) {
                        String groupsText = groupsElement.getText().trim();
                        logger.debug("Groups (from span[data-v-29a613a4]): {}", groupsText);
                        
                        // Split text into individual groups
                        String[] groupsArray = groupsText.split(",");
                        
                        // Extract class as first group before first comma
                        if (groupsArray.length > 0) {
                            String firstGroup = groupsArray[0].trim();
                            logger.debug("First group (class): {}", firstGroup);
                            userData.put("class", firstGroup);
                        }
                        
                        groupsFound = true;
                    }
                } catch (Exception e3) {
                    logger.debug("Could not find span element with data-v-29a613a4: {}", e3.getMessage());
                }
            }
        }
        
        if (!groupsFound) {
            logger.warn("Could not extract groups!");
        }
    }
    
    /**
     * Extract WebDAV URL from avatar image
     */
    private void extractWebdavUrlWithSelenium(WebDriver driver, JSONObject userData) {
        try {
            // Find avatar image with attribute data-v-9ce7ef1d
            WebElement avatarImg = driver.findElement(By.cssSelector("img[data-v-9ce7ef1d]"));
            if (avatarImg != null) {
                // Extract src of avatar image
                String avatarSrc = avatarImg.getAttribute("src");
                logger.debug("Avatar image src: {}", avatarSrc);
                
                // Extract ID from src
                // Format: /index.php/avatar/a25e9d84-1ee2-4431-9ea1-f19b5c86386c/64/dark?v=2
                Pattern avatarIdPattern = Pattern.compile("/avatar/([^/]+)/");
                Matcher avatarIdMatcher = avatarIdPattern.matcher(avatarSrc);
                
                if (avatarIdMatcher.find()) {
                    String avatarId = avatarIdMatcher.group(1);
                    logger.debug("Avatar ID: {}", avatarId);
                    
                    // Construct WebDAV URL with avatar ID
                    String webdavUrl = NEXTCLOUD_WEBDAV_URL + avatarId + "/";
                    logger.debug("WebDAV URL (from avatar ID): {}", webdavUrl);
                    userData.put("webdavUrl", webdavUrl);
                } else {
                    logger.debug("Could not extract avatar ID from src: {}", avatarSrc);
                }
            }
        } catch (Exception e) {
            logger.debug("Could not find avatar image: {}", e.getMessage());
            
            // Try alternative selectors
            try {
                // Try to search all images
                List<WebElement> allImages = driver.findElements(By.tagName("img"));
                boolean found = false;
                for (WebElement img : allImages) {
                    String src = img.getAttribute("src");
                    if (src != null && src.contains("/avatar/")) {
                        logger.debug("Avatar image found: {}", src);
                        
                        // Extract ID from src
                        Pattern avatarIdPattern = Pattern.compile("/avatar/([^/]+)/");
                        Matcher avatarIdMatcher = avatarIdPattern.matcher(src);
                        
                        if (avatarIdMatcher.find()) {
                            String avatarId = avatarIdMatcher.group(1);
                            logger.debug("Avatar ID: {}", avatarId);
                            
                            // Construct WebDAV URL with avatar ID
                            String webdavUrl = NEXTCLOUD_WEBDAV_URL + avatarId + "/";
                            logger.debug("WebDAV URL (from avatar ID): {}", webdavUrl);
                            userData.put("webdavUrl", webdavUrl);
                            found = true;
                            break;
                        }
                    }
                }
                
                if (!found) {
                    logger.debug("Could not find avatar image with ID");
                }
            } catch (Exception e2) {
                logger.error("Error searching images: {}", e2.getMessage());
            }
        }
    }
    
    /**
     * Take a screenshot of the current page
     */
    private void takeScreenshot(WebDriver driver, String fileName) {
        try {
            // Create screenshots directory if it doesn't exist
            File screenshotsDirFile = new File(screenshotsDirectory);
            if (!screenshotsDirFile.exists()) {
                screenshotsDirFile.mkdirs();
                logger.debug("Created screenshots directory: {}", screenshotsDirectory);
            }
            
            // Save screenshot to the screenshots directory
            File screenshot = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
            File destination = new File(screenshotsDirFile, fileName);
            Files.copy(screenshot.toPath(), destination.toPath(), StandardCopyOption.REPLACE_EXISTING);
            logger.debug("Screenshot saved: {}", destination.getPath());
        } catch (IOException e) {
            logger.error("Error saving screenshot: {}", e.getMessage());
        }
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
     * Endpunkt für die Statusabfrage des Servers
     */
    @org.springframework.web.bind.annotation.GetMapping("/nextcloud/status")
    public ResponseEntity<Map<String, Object>> status() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "online");
        response.put("success", true);
        response.put("message", "Server is running");
        return ResponseEntity.ok(response);
    }
    
    /**
     * Endpunkt für die Anmeldung bei Nextcloud
     */
    @PostMapping("/api/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> credentials) {
        String username = credentials.get("username");
        String password = credentials.get("password");
        
        System.out.println("DEBUG: Login request received for username: " + username);
        
        if (username == null || password == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Benutzername und Passwort sind erforderlich");
            System.out.println("DEBUG: Login failed - username or password is null");
            return ResponseEntity.badRequest().body(response);
        }
        
        System.out.println("DEBUG: Attempting to extract user data from Nextcloud for: " + username);
        Map<String, Object> result = nextcloudService.extractUserDataWithSelenium(username, password);
        
        System.out.println("DEBUG: Login result success: " + result.get("success") + ", message: " + result.get("message"));
        
        if ((Boolean) result.get("success")) {
            System.out.println("DEBUG: Login successful for: " + username);
            return ResponseEntity.ok(result);
        } else {
            System.out.println("DEBUG: Login failed for: " + username + " - " + result.get("message"));
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
        
        Map<String, Object> result = nextcloudService.extractUserDataWithSelenium(username, password);
        
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