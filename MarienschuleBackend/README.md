# Marienschule Backend

Backend-Service für die Marienschule Bielefeld App.

## Funktionen

- Extraktion von Benutzerdaten aus Nextcloud
- Speicherung von Benutzerdaten in JSON-Dateien
- REST-API für die App

## Voraussetzungen

- Java 11 oder höher
- Maven
- Google Chrome (für Selenium-basierte Extraktion)
- ChromeDriver (passend zur Chrome-Version)

## Installation

### Chrome und ChromeDriver installieren

Für die Selenium-basierte Extraktion von Benutzerdaten aus Nextcloud werden Google Chrome und ChromeDriver benötigt.

#### Unter Linux (Ubuntu/Debian):

```bash
# Chrome installieren
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt-get update
sudo apt-get install -y google-chrome-stable

# Chrome-Version ermitteln
CHROME_VERSION=$(google-chrome --version | awk '{print $3}' | cut -d. -f1)
echo "Chrome version: $CHROME_VERSION"

# ChromeDriver herunterladen, der zur Chrome-Version passt
# Methode 1: Neueste Version für die aktuelle Chrome-Version herunterladen
wget -q "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$CHROME_VERSION" -O chrome_version.txt
CHROMEDRIVER_VERSION=$(cat chrome_version.txt)
echo "ChromeDriver version: $CHROMEDRIVER_VERSION"
wget -q "https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
unzip -q chromedriver_linux64.zip
sudo mv chromedriver /usr/bin/chromedriver
sudo chown root:root /usr/bin/chromedriver
sudo chmod +x /usr/bin/chromedriver
rm -f chromedriver_linux64.zip chrome_version.txt

# ODER Methode 2: Direkt von Chrome for Testing herunterladen
# Besuche https://googlechromelabs.github.io/chrome-for-testing/ für die neuesten Versionen
# Beispiel für Chrome 134:
# wget -q "https://storage.googleapis.com/chrome-for-testing-public/134.0.6998.35/linux64/chromedriver-linux64.zip"
# unzip -q chromedriver-linux64.zip
# sudo mv chromedriver-linux64/chromedriver /usr/bin/chromedriver
# sudo chown root:root /usr/bin/chromedriver
# sudo chmod +x /usr/bin/chromedriver
# rm -rf chromedriver-linux64 chromedriver-linux64.zip

# Prüfen, ob ChromeDriver korrekt installiert wurde
chromedriver --version
```

**Wichtig:** ChromeDriver und Chrome müssen kompatible Versionen haben. Wenn Sie eine Fehlermeldung wie "This version of ChromeDriver only supports Chrome version X" erhalten, müssen Sie die passende ChromeDriver-Version installieren.

### Backend kompilieren und starten

```bash
# Repository klonen
git clone https://github.com/yourusername/marienschule-backend.git
cd marienschule-backend

# Mit Maven kompilieren
mvn clean package

# Starten
java -jar target/marienschule-backend-1.0.0.jar
```

## Konfiguration

Die Konfiguration erfolgt über die Datei `src/main/resources/application.properties`. Hier können folgende Einstellungen vorgenommen werden:

- `server.port`: Port, auf dem der Server läuft (Standard: 8080)
- `app.data.directory`: Verzeichnis für die Speicherung von Benutzerdaten (Standard: ./data)
- `app.screenshots.directory`: Verzeichnis für Screenshots (Standard: ./screenshots)
- `webdriver.chrome.driver`: Pfad zum ChromeDriver (Standard: /usr/bin/chromedriver)
- `webdriver.chrome.binary`: Pfad zur Chrome-Binary (Standard: /usr/bin/google-chrome)

## API-Endpunkte

### Status prüfen

```
GET /nextcloud/status
```

Antwort:
```json
{
  "status": "ok",
  "message": "Nextcloud service is running"
}
```

### Benutzer anmelden und Daten extrahieren

```
POST /api/login
```

Request-Body:
```json
{
  "username": "benutzername",
  "password": "passwort"
}
```

Antwort bei Erfolg:
```json
{
  "success": true,
  "user_id": 1,
  "username": "benutzername",
  "first_name": "Vorname",
  "last_name": "Nachname",
  "email": "email@example.com",
  "school_class": "Klasse",
  "webdav_url": "https://nextcloud-g2.bielefeld-marienschule.logoip.de/remote.php/dav/files/user-id/"
}
```

### Benutzerdaten aktualisieren

```
POST /api/refresh
```

Request-Body:
```json
{
  "username": "benutzername",
  "password": "passwort"
}
```

### Benutzerdaten abrufen

```
POST /api/user
```

Request-Body:
```json
{
  "username": "benutzername"
}
```

## Selenium-basierte Extraktion

Die Anwendung verwendet Selenium WebDriver, um Benutzerdaten aus Nextcloud zu extrahieren. Dies ermöglicht eine robuste Extraktion auch bei Änderungen der Nextcloud-Oberfläche. Die Extraktion läuft im Headless-Modus, d.h. ohne sichtbares Browser-Fenster, und ist für den Einsatz auf Linux-Servern optimiert.

### Funktionsweise

1. Der Browser wird im Headless-Modus gestartet
2. Die Anmeldung bei Nextcloud erfolgt mit den übergebenen Anmeldedaten
3. Die Benutzereinstellungsseite wird aufgerufen
4. Verschiedene Selektoren werden verwendet, um die Benutzerdaten zu extrahieren
5. Die extrahierten Daten werden in einer JSON-Datei gespeichert
6. Screenshots werden für die Fehlersuche erstellt

### Fehlerbehebung

Falls Probleme bei der Extraktion auftreten:

1. Überprüfen Sie die Screenshots im `screenshots`-Verzeichnis
2. Prüfen Sie die Logs auf Fehlermeldungen
3. Stellen Sie sicher, dass Chrome und ChromeDriver installiert sind und die Versionen kompatibel sind
4. Wenn ChromeDriver-Probleme auftreten, versuchen Sie die folgenden Schritte:
   - Überprüfen Sie die Chrome-Version mit `google-chrome --version`
   - Laden Sie die passende ChromeDriver-Version von der [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/) Seite herunter
   - Aktualisieren Sie den Pfad in der `application.properties` Datei

## Lizenz

Dieses Projekt steht unter der MIT-Lizenz. 