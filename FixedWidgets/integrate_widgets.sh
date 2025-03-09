#!/bin/bash

# Skript zur Integration der korrigierten Widget-Komponenten in das Projekt

# Pfad zum Projekt
PROJECT_DIR="/Users/matskahmann/Documents/GitHub/cnprmedia_mdu-app"
APP_DIR="$PROJECT_DIR/MdU App"
WIDGETS_DIR="$PROJECT_DIR/FixedWidgets"

# Erstelle ein Backup der ContentView.swift-Datei
BACKUP_FILE="$APP_DIR/ContentView.swift.backup_before_integration_$(date +%Y%m%d_%H%M%S)"
cp "$APP_DIR/ContentView.swift" "$BACKUP_FILE"
echo "Backup erstellt: $BACKUP_FILE"

# Kopiere die korrigierten Widget-Komponenten in das Projekt
cp "$WIDGETS_DIR/NextLessonWidget.swift" "$APP_DIR/"
cp "$WIDGETS_DIR/SchoolContactWidget.swift" "$APP_DIR/"
cp "$WIDGETS_DIR/TransportLinksWidget.swift" "$APP_DIR/"
cp "$WIDGETS_DIR/LessonSearchResultRow.swift" "$APP_DIR/"
cp "$WIDGETS_DIR/Lesson.swift" "$APP_DIR/"
echo "Korrigierte Widget-Komponenten in das Projekt kopiert"

# Entferne die Widget-Definitionen aus der ContentView.swift-Datei
# Erstelle eine temporäre Datei
TEMP_FILE="$APP_DIR/ContentView.swift.temp"

# Kopiere die ContentView.swift-Datei in die temporäre Datei
cp "$APP_DIR/ContentView.swift" "$TEMP_FILE"

# Entferne die NextLessonWidget-Definition
sed -i '' '/^struct NextLessonWidget: View {/,/^}$/d' "$TEMP_FILE"
echo "NextLessonWidget-Definition aus ContentView.swift entfernt"

# Entferne die SchoolContactWidget-Definition
sed -i '' '/^struct SchoolContactWidget: View {/,/^}$/d' "$TEMP_FILE"
sed -i '' '/^struct ContactInfoRow: View {/,/^}$/d' "$TEMP_FILE"
echo "SchoolContactWidget-Definition aus ContentView.swift entfernt"

# Entferne die TransportLinksWidget-Definition
sed -i '' '/^struct TransportLinksWidget: View {/,/^}$/d' "$TEMP_FILE"
echo "TransportLinksWidget-Definition aus ContentView.swift entfernt"

# Entferne die LessonSearchResultRow-Definition
sed -i '' '/^struct LessonSearchResultRow: View {/,/^}$/d' "$TEMP_FILE"
echo "LessonSearchResultRow-Definition aus ContentView.swift entfernt"

# Kopiere die bereinigte temporäre Datei zurück zur ContentView.swift-Datei
cp "$TEMP_FILE" "$APP_DIR/ContentView.swift"
rm "$TEMP_FILE"

# Füge die Import-Anweisungen am Anfang der ContentView.swift-Datei hinzu
sed -i '' '11i\
// Import der korrigierten Widget-Komponenten' "$APP_DIR/ContentView.swift"
echo "Import-Anweisungen zur ContentView.swift-Datei hinzugefügt"

echo "Integration der korrigierten Widget-Komponenten abgeschlossen!"
echo "Bitte kompiliere die App, um zu überprüfen, ob alle Fehler behoben wurden."

# Anleitung zur Wiederherstellung des Backups
echo ""
echo "Falls du das Original wiederherstellen möchtest, führe folgenden Befehl aus:"
echo "cp \"$BACKUP_FILE\" \"$APP_DIR/ContentView.swift\"" 