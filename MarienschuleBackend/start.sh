#!/bin/bash

# Marienschule Backend Starter Script

echo "Marienschule Backend Starter"
echo "============================"
echo ""

# Prüfe, ob Maven installiert ist
if ! command -v mvn &> /dev/null; then
    echo "Maven ist nicht installiert. Bitte installieren Sie Maven."
    exit 1
fi

# Prüfe, ob Java installiert ist
if ! command -v java &> /dev/null; then
    echo "Java ist nicht installiert. Bitte installieren Sie Java 11 oder höher."
    exit 1
fi

echo "Starte das Marienschule Backend..."
echo ""

# Starte das Backend mit Maven
cd "$(dirname "$0")"
mvn spring-boot:run

# Wenn der Benutzer Strg+C drückt, beende das Skript ordnungsgemäß
trap "echo 'Backend wird beendet...'; exit 0" INT 