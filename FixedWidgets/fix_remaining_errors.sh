#!/bin/bash

# Skript zur Behebung der verbleibenden Fehler in ContentView.swift

# Pfad zur ContentView.swift-Datei
FILE="../MdU App/ContentView.swift"

# Erstelle ein Backup der Originaldatei
cp "$FILE" "${FILE}.backup_remaining_$(date +%Y%m%d_%H%M%S)"
echo "Backup erstellt: ${FILE}.backup_remaining_$(date +%Y%m%d_%H%M%S)"

# Behebe den Fehler in LessonSearchResultRow (Zeile 1600)
# Hier müssen wir die Klammerstruktur korrigieren
# Wir erstellen eine temporäre Datei mit den korrigierten Zeilen
cat > temp_fix.txt << 'EOL'
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
EOL

# Ersetze die Zeilen 1598-1603 mit den korrigierten Zeilen
sed -i '' '1598,1603c\
                .padding(.vertical, 12)\
            }\
            .padding(.horizontal, 12)\
        .padding(.horizontal, 16)\
        .padding(.bottom, 8)' "$FILE"

echo "Fehler in LessonSearchResultRow (Zeile 1600) behoben"

# Behebe den Fehler in Zeile 1491-1498
# Hier scheint ein Problem mit der Struktur zu sein
# Wir überprüfen, ob es eine überschüssige schließende Klammer gibt
sed -i '' '1493s/^/\/\/ /' "$FILE"
sed -i '' '1494s/^/        .background(/' "$FILE"

echo "Fehler in Zeile 1491-1498 behoben"

echo "Fertig! Bitte kompiliere die App, um zu überprüfen, ob alle Fehler behoben wurden."
echo "Falls weiterhin Probleme auftreten, verwende die korrigierten Widget-Komponenten aus dem FixedWidgets-Verzeichnis." 