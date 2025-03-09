# Nextcloud Selenium Test

Dieses Programm extrahiert Benutzerdaten aus Nextcloud mithilfe von Selenium WebDriver. Es läuft im Headless-Modus und kann auf einem Linux-Server ausgeführt werden.

## Voraussetzungen

- Java 11 oder höher
- Google Chrome
- ChromeDriver (passend zur Chrome-Version)

## Ausführung auf einem Linux-Server

### Automatische Installation und Ausführung

1. Führe das Programm einmal auf deinem lokalen Computer aus, um die `run_on_linux.sh` Datei zu generieren
2. Übertrage die folgenden Dateien auf deinen Linux-Server:
   - `NextcloudSeleniumTest.jar` (kompilierte JAR-Datei)
   - `run_on_linux.sh` (generiertes Shell-Skript)
3. Mache das Shell-Skript ausführbar:
   ```
   chmod +x run_on_linux.sh
   ```
4. Führe das Shell-Skript aus:
   ```
   ./run_on_linux.sh
   ```
   Das Skript installiert automatisch Chrome und ChromeDriver, falls diese nicht vorhanden sind, und führt dann das Programm aus.

### Manuelle Installation

Falls du die Abhängigkeiten manuell installieren möchtest:

1. Installiere Google Chrome:
   ```
   wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
   echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
   sudo apt-get update
   sudo apt-get install -y google-chrome-stable
   ```

2. Installiere ChromeDriver:
   ```
   CHROME_VERSION=$(google-chrome --version | cut -d ' ' -f 3 | cut -d '.' -f 1)
   CHROMEDRIVER_VERSION=$(curl -s "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROME_VERSION}")
   wget -q "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip"
   unzip -q chromedriver_linux64.zip
   sudo mv chromedriver /usr/bin/chromedriver
   sudo chown root:root /usr/bin/chromedriver
   sudo chmod +x /usr/bin/chromedriver
   ```

3. Führe das Programm aus:
   ```
   java -Dwebdriver.chrome.driver=/usr/bin/chromedriver -jar NextcloudSeleniumTest.jar
   ```

## Ausgabe

Das Programm extrahiert folgende Benutzerdaten aus Nextcloud:
- Vollständiger Name
- Vorname
- Nachname
- E-Mail-Adresse
- WebDAV-URL
- Benutzername
- Klasse/Gruppe

Die extrahierten Daten werden in der Datei `user_data.json` gespeichert.

## Fehlerbehebung

Falls Probleme auftreten:

1. Überprüfe, ob Chrome und ChromeDriver installiert sind:
   ```
   google-chrome --version
   chromedriver --version
   ```

2. Stelle sicher, dass die Versionen von Chrome und ChromeDriver kompatibel sind

3. Überprüfe die Screenshots im `screenshots`-Verzeichnis, um zu sehen, was während der Ausführung passiert ist

4. Prüfe die Konsolenausgabe auf Fehlermeldungen 