#!/bin/bash

# Skript zur automatischen Behebung der Klammerungsfehler in ContentView.swift

# Pfad zur ContentView.swift-Datei
FILE="../MdU App/ContentView.swift"

# Erstelle ein Backup der Originaldatei
cp "$FILE" "${FILE}.backup_$(date +%Y%m%d_%H%M%S)"
echo "Backup erstellt: ${FILE}.backup_$(date +%Y%m%d_%H%M%S)"

# Behebe den Fehler in NextLessonWidget (Zeilen 854-856)
sed -i '' '856s/)//' "$FILE"
echo "Fehler in NextLessonWidget (Zeile 856) behoben"

# Behebe den Fehler in SchoolContactWidget (Zeilen 1249-1251)
sed -i '' '1251s/)//' "$FILE"
echo "Fehler in SchoolContactWidget (Zeile 1251) behoben"

# Behebe den Fehler in TransportLinksWidget (Zeilen 1382-1384)
sed -i '' '1384s/)//' "$FILE"
echo "Fehler in TransportLinksWidget (Zeile 1384) behoben"

# Für den LessonSearchResultRow-Fehler (Zeile 1600) ist eine manuelle Überprüfung erforderlich
echo "Hinweis: Der Fehler in LessonSearchResultRow (Zeile 1600) erfordert möglicherweise eine manuelle Überprüfung."

echo "Fertig! Bitte kompiliere die App, um zu überprüfen, ob alle Fehler behoben wurden."
echo "Falls weiterhin Probleme auftreten, verwende die korrigierten Widget-Komponenten aus dem FixedWidgets-Verzeichnis." 