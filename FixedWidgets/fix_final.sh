#!/bin/bash

# Skript zur Behebung der verbleibenden Fehler in ContentView.swift

# Pfad zur ContentView.swift-Datei
FILE="../MdU App/ContentView.swift"

# Erstelle ein Backup der Originaldatei
BACKUP_FILE="${FILE}.backup_final_$(date +%Y%m%d_%H%M%S)"
cp "$FILE" "$BACKUP_FILE"
echo "Backup erstellt: $BACKUP_FILE"

# Füge eine fehlende schließende Klammer am Ende der Datei hinzu
echo "}" >> "$FILE"
echo "Fehlende schließende Klammer am Ende der Datei hinzugefügt"

# Behebe den Fehler in Zeile 1491-1498
# Hier müssen wir die Klammerstruktur korrigieren
sed -i '' '1491,1498c\
            .padding(.vertical, 16)\
        }\
    }\
\
    .background(\
        RoundedRectangle(cornerRadius: 16)\
            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)\
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)\
    )' "$FILE"
echo "Fehler in Zeile 1491-1498 behoben"

# Behebe den Fehler in LessonSearchResultRow (Zeile 1600)
# Hier müssen wir die Klammerstruktur korrigieren
sed -i '' '1597,1604c\
                .padding(.vertical, 12)\
            }\
        }\
        .padding(.horizontal, 12)\
        .padding(.horizontal, 16)\
        .padding(.bottom, 8)\
        .background(\
            RoundedRectangle(cornerRadius: 12)' "$FILE"
echo "Fehler in LessonSearchResultRow (Zeile 1600) behoben"

echo "Alle verbleibenden Fehler wurden behoben! Bitte kompiliere die App, um zu überprüfen, ob die Fehler behoben wurden."
echo "Falls weiterhin Probleme auftreten, verwende die korrigierten Widget-Komponenten aus dem FixedWidgets-Verzeichnis."

# Anleitung zur Wiederherstellung des Backups
echo ""
echo "Falls du das Original wiederherstellen möchtest, führe folgenden Befehl aus:"
echo "cp \"$BACKUP_FILE\" \"$FILE\"" 