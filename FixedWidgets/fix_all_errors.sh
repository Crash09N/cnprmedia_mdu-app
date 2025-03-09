#!/bin/bash

# Skript zur Behebung aller Klammerungsfehler in ContentView.swift

# Pfad zur ContentView.swift-Datei
FILE="../MdU App/ContentView.swift"

# Erstelle ein Backup der Originaldatei
BACKUP_FILE="${FILE}.backup_all_$(date +%Y%m%d_%H%M%S)"
cp "$FILE" "$BACKUP_FILE"
echo "Backup erstellt: $BACKUP_FILE"

# 1. Behebe den Fehler in NextLessonWidget (Zeilen 854-856)
sed -i '' '856s/)//' "$FILE"
echo "Fehler in NextLessonWidget (Zeile 856) behoben"

# 2. Behebe den Fehler in SchoolContactWidget (Zeilen 1249-1251)
sed -i '' '1251s/)//' "$FILE"
echo "Fehler in SchoolContactWidget (Zeile 1251) behoben"

# 3. Behebe den Fehler in TransportLinksWidget (Zeilen 1382-1384)
sed -i '' '1384s/)//' "$FILE"
echo "Fehler in TransportLinksWidget (Zeile 1384) behoben"

# 4. Behebe den Fehler in LessonSearchResultRow (Zeile 1600)
# Hier müssen wir die Klammerstruktur korrigieren
sed -i '' '1598,1603c\
                .padding(.vertical, 12)\
            }\
            .padding(.horizontal, 12)\
        .padding(.horizontal, 16)\
        .padding(.bottom, 8)' "$FILE"
echo "Fehler in LessonSearchResultRow (Zeile 1600) behoben"

# 5. Behebe den Fehler in Zeile 1491-1498
# Hier kommentieren wir die problematische Zeile aus und fügen die korrekte Struktur ein
sed -i '' '1493s/^/\/\/ /' "$FILE"
sed -i '' '1494s/^/        .background(/' "$FILE"
echo "Fehler in Zeile 1491-1498 behoben"

echo "Alle Fehler wurden behoben! Bitte kompiliere die App, um zu überprüfen, ob die Fehler behoben wurden."
echo "Falls weiterhin Probleme auftreten, verwende die korrigierten Widget-Komponenten aus dem FixedWidgets-Verzeichnis."

# Anleitung zur Wiederherstellung des Backups
echo ""
echo "Falls du das Original wiederherstellen möchtest, führe folgenden Befehl aus:"
echo "cp \"$BACKUP_FILE\" \"$FILE\"" 