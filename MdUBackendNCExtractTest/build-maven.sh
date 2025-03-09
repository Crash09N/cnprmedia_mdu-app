#!/bin/bash

# Überprüfen, ob ChromeDriver bereits vorhanden ist
if [ -f "chromedriver" ]; then
    echo "Lösche vorhandenen ChromeDriver..."
    rm chromedriver
fi

echo "ChromeDriver wird heruntergeladen..."

# Ermitteln des Betriebssystems
OS="$(uname -s)"
case "${OS}" in
    Linux*)     CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/133.0.6943.0/linux64/chromedriver-linux64.zip";;
    Darwin*)    CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/133.0.6943.0/mac-arm64/chromedriver-mac-arm64.zip";;
    MINGW*|MSYS*) CHROMEDRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/133.0.6943.0/win64/chromedriver-win64.zip";;
    *)          echo "Nicht unterstütztes Betriebssystem: ${OS}"; exit 1;;
esac

# ChromeDriver herunterladen und entpacken
echo "Lade ChromeDriver von $CHROMEDRIVER_URL herunter..."
curl -L -o chromedriver.zip "$CHROMEDRIVER_URL"

# Entpacken und Berechtigungen setzen
if [[ "$OS" == "Darwin"* ]]; then
    unzip chromedriver.zip
    mv chromedriver-mac-arm64/chromedriver .
    rm -rf chromedriver-mac-arm64
elif [[ "$OS" == "Linux"* ]]; then
    unzip chromedriver.zip
    mv chromedriver-linux64/chromedriver .
    rm -rf chromedriver-linux64
elif [[ "$OS" == "MINGW"* || "$OS" == "MSYS"* ]]; then
    unzip chromedriver.zip
    mv chromedriver-win64/chromedriver.exe .
    rm -rf chromedriver-win64
fi

rm chromedriver.zip
chmod +x chromedriver
echo "ChromeDriver wurde installiert."

# Überprüfen, ob Maven installiert ist
if ! command -v mvn &> /dev/null; then
    echo "Maven ist nicht installiert. Bitte installieren Sie Maven, um fortzufahren."
    exit 1
fi

# Maven-Projekt kompilieren
echo "Kompiliere das Maven-Projekt..."
mvn clean compile assembly:single

# Prüfen, ob die Kompilierung erfolgreich war
if [ $? -eq 0 ]; then
    echo "Kompilierung erfolgreich. Programm wird ausgeführt..."
    java -jar target/nextcloud-selenium-test-1.0-SNAPSHOT-jar-with-dependencies.jar
else
    echo "Kompilierung fehlgeschlagen."
    exit 1
fi 