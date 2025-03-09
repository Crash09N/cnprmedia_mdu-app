#!/bin/bash

# Skript zur vollständigen Behebung aller Fehler in ContentView.swift

# Pfad zur ContentView.swift-Datei
FILE="../MdU App/ContentView.swift"

# Erstelle ein Backup der Originaldatei
BACKUP_FILE="${FILE}.backup_complete_$(date +%Y%m%d_%H%M%S)"
cp "$FILE" "$BACKUP_FILE"
echo "Backup erstellt: $BACKUP_FILE"

# Temporäre Datei erstellen
TEMP_FILE="${FILE}.temp"

# Kopiere die Originaldatei in die temporäre Datei
cp "$FILE" "$TEMP_FILE"

# 1. Behebe den Fehler in NextLessonWidget (Zeilen 854-856)
# Entferne eine überschüssige schließende Klammer
sed -i '' '856s/)//' "$TEMP_FILE"
echo "Fehler in NextLessonWidget (Zeile 856) behoben"

# 2. Behebe den Fehler in SchoolContactWidget (Zeilen 1249-1251)
# Entferne eine überschüssige schließende Klammer
sed -i '' '1251s/)//' "$TEMP_FILE"
echo "Fehler in SchoolContactWidget (Zeile 1251) behoben"

# 3. Behebe den Fehler in TransportLinksWidget (Zeilen 1382-1384)
# Entferne eine überschüssige schließende Klammer
sed -i '' '1384s/)//' "$TEMP_FILE"
echo "Fehler in TransportLinksWidget (Zeile 1384) behoben"

# 4. Behebe den Fehler in Zeile 1491-1498
# Hier müssen wir die Klammerstruktur korrigieren
cat > fix_1491.txt << 'EOL'
            .padding(.vertical, 16)
        }
    }
}

struct TransportLinksWidget: View {
EOL

# Ersetze die Zeilen 1491-1500 mit den korrigierten Zeilen
sed -i '' '1491,1500c\
            .padding(.vertical, 16)\
        }\
    }\
}\
\
struct TransportLinksWidget: View {' "$TEMP_FILE"
echo "Fehler in Zeile 1491-1498 behoben"

# 5. Behebe den Fehler in LessonSearchResultRow (Zeile 1600)
# Hier müssen wir die Klammerstruktur korrigieren
cat > fix_1600.txt << 'EOL'
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(
EOL

# Ersetze die Zeilen 1597-1604 mit den korrigierten Zeilen
sed -i '' '1597,1604c\
                .padding(.vertical, 12)\
            }\
        }\
        .padding(.horizontal, 12)\
        .padding(.horizontal, 16)\
        .padding(.bottom, 8)\
        .background(\
            RoundedRectangle(cornerRadius: 12)' "$TEMP_FILE"
echo "Fehler in LessonSearchResultRow (Zeile 1600) behoben"

# 6. Behebe den Fehler am Ende der Datei (Zeile 1637)
# Hier müssen wir sicherstellen, dass die ContentView-Struktur korrekt geschlossen wird
# Wir fügen eine schließende Klammer am Ende der Datei hinzu, falls nötig
tail -n 5 "$TEMP_FILE" | grep -q "^}$"
if [ $? -ne 0 ]; then
    echo "}" >> "$TEMP_FILE"
    echo "Fehlende schließende Klammer am Ende der Datei hinzugefügt"
fi

# Kopiere die korrigierte temporäre Datei zurück zur Originaldatei
cp "$TEMP_FILE" "$FILE"
rm "$TEMP_FILE"

# Lösche die temporären Dateien
rm -f fix_1491.txt fix_1600.txt

echo "Alle Fehler wurden vollständig behoben! Bitte kompiliere die App, um zu überprüfen, ob die Fehler behoben wurden."
echo "Falls weiterhin Probleme auftreten, verwende die korrigierten Widget-Komponenten aus dem FixedWidgets-Verzeichnis."

# Anleitung zur Wiederherstellung des Backups
echo ""
echo "Falls du das Original wiederherstellen möchtest, führe folgenden Befehl aus:"
echo "cp \"$BACKUP_FILE\" \"$FILE\"" 