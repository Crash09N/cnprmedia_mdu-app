#!/bin/bash

# Verzeichnis für Bibliotheken erstellen
mkdir -p lib

# ChromeDriver herunterladen und installieren
if [ ! -f "chromedriver" ]; then
    echo "ChromeDriver wird heruntergeladen..."
    
    # Betriebssystem erkennen
    OS=$(uname -s)
    case "${OS}" in
        Linux*)     CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/122.0.6261.94/linux64/chromedriver-linux64.zip";;
        Darwin*)    CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/122.0.6261.94/mac-x64/chromedriver-mac-x64.zip";;
        MINGW*|MSYS*) CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/122.0.6261.94/win64/chromedriver-win64.zip";;
        *)          echo "Nicht unterstütztes Betriebssystem: ${OS}"; exit 1;;
    esac
    
    # ChromeDriver herunterladen und entpacken
    curl -L -o chromedriver.zip "${CHROMEDRIVER_URL}"
    
    if [[ "${OS}" == "Darwin"* ]]; then
        # macOS
        unzip chromedriver.zip
        mv chromedriver-mac-x64/chromedriver .
        rm -rf chromedriver-mac-x64
    elif [[ "${OS}" == "Linux"* ]]; then
        # Linux
        unzip chromedriver.zip
        mv chromedriver-linux64/chromedriver .
        rm -rf chromedriver-linux64
    else
        # Windows
        unzip chromedriver.zip
        mv chromedriver-win64/chromedriver.exe chromedriver
        rm -rf chromedriver-win64
    fi
    
    rm chromedriver.zip
    chmod +x chromedriver
    echo "ChromeDriver wurde installiert."
fi

# Selenium-Abhängigkeiten herunterladen
echo "Selenium-Abhängigkeiten werden heruntergeladen..."

# Selenium JAR-Dateien herunterladen
SELENIUM_VERSION="4.18.1"

# Selenium-Standalone-JAR herunterladen
if [ ! -f "lib/selenium-server-standalone.jar" ]; then
    echo "Selenium Standalone JAR wird heruntergeladen..."
    curl -L -o "lib/selenium-server-standalone.jar" "https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar"
fi

echo "Selenium-Abhängigkeiten wurden heruntergeladen."

# Java-Programm kompilieren
echo "Java-Programm wird kompiliert..."
javac -cp ".:lib/*" NextcloudSeleniumTest.java

# Java-Programm ausführen
if [ -f "NextcloudSeleniumTest.class" ]; then
    echo "Java-Programm wird ausgeführt..."
    java -cp ".:lib/*" NextcloudSeleniumTest
else
    echo "Kompilierung fehlgeschlagen. Programm wird nicht ausgeführt."
fi 