#!/bin/bash

# Skript zur präzisen Behebung der Klammerungsfehler in ContentView.swift

# Pfad zur ContentView.swift-Datei
FILE="../MdU App/ContentView.swift"

# Erstelle ein Backup der Originaldatei
BACKUP_FILE="${FILE}.backup_precise_$(date +%Y%m%d_%H%M%S)"
cp "$FILE" "$BACKUP_FILE"
echo "Backup erstellt: $BACKUP_FILE"

# 1. Behebe den Fehler in NextLessonWidget (Zeilen 854-856)
# Entferne eine überschüssige schließende Klammer
sed -i '' '856s/)//' "$FILE"
echo "Fehler in NextLessonWidget (Zeile 856) behoben"

# 2. Behebe den Fehler in SchoolContactWidget (Zeilen 1249-1251)
# Entferne eine überschüssige schließende Klammer
sed -i '' '1251s/)//' "$FILE"
echo "Fehler in SchoolContactWidget (Zeile 1251) behoben"

# 3. Behebe den Fehler in TransportLinksWidget (Zeilen 1382-1384)
# Entferne eine überschüssige schließende Klammer
sed -i '' '1384s/)//' "$FILE"
echo "Fehler in TransportLinksWidget (Zeile 1384) behoben"

# 4. Behebe den Fehler in LessonSearchResultRow (Zeile 1600)
# Hier müssen wir die Klammerstruktur korrigieren
# Wir erstellen eine temporäre Datei mit den korrigierten Zeilen
cat > temp_fix_1600.txt << 'EOL'
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(
EOL

# Ersetze die Zeilen 1598-1604 mit den korrigierten Zeilen
sed -i '' '1598,1604c\
                .padding(.vertical, 12)\
            }\
            .padding(.horizontal, 12)\
        .padding(.horizontal, 16)\
        .padding(.bottom, 8)\
        .background(' "$FILE"
echo "Fehler in LessonSearchResultRow (Zeile 1600) behoben"

# 5. Behebe den Fehler in Zeile 1491-1498
# Hier müssen wir die Klammerstruktur korrigieren
cat > temp_fix_1491.txt << 'EOL'
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
EOL

# Ersetze die Zeilen 1491-1494 mit den korrigierten Zeilen
sed -i '' '1491,1494c\
            .padding(.vertical, 16)\
        }\
        .background(\
            RoundedRectangle(cornerRadius: 16)' "$FILE"
echo "Fehler in Zeile 1491-1498 behoben"

# Lösche die temporären Dateien
rm -f temp_fix_1600.txt temp_fix_1491.txt

echo "Alle Fehler wurden präzise behoben! Bitte kompiliere die App, um zu überprüfen, ob die Fehler behoben wurden."
echo "Falls weiterhin Probleme auftreten, verwende die korrigierten Widget-Komponenten aus dem FixedWidgets-Verzeichnis."

# Anleitung zur Wiederherstellung des Backups
echo ""
echo "Falls du das Original wiederherstellen möchtest, führe folgenden Befehl aus:"
echo "cp \"$BACKUP_FILE\" \"$FILE\"" 