# Optimierung des Kalender-Designs

## Zusammenfassung der Änderungen

Gemäß den Anforderungen wurden folgende Änderungen am Kalender-Design vorgenommen:

1. **Farbgebung der Termine**:
   - Termine in der grünen Woche werden jetzt in grün dargestellt
   - Termine in der roten Woche werden jetzt in rot dargestellt
   - Die Farben werden dynamisch basierend auf der aktuellen Woche angepasst

2. **Entfernung der Anzeige für die grüne Woche**:
   - Die separate Anzeige für die grüne/rote Woche wurde aus der Hauptansicht entfernt
   - Die Information ist jetzt nur noch im DatePicker sichtbar

3. **Neugestaltung der Button-Leiste**:
   - Die obere Leiste mit den Buttons wurde komplett neu gestaltet
   - Zweizeiliges Layout für bessere Übersichtlichkeit
   - Verbesserte visuelle Hierarchie
   - Klare Trennung zwischen Datum, Navigation und Klasseninformation

4. **Beibehaltung der Zeitleiste**:
   - Die Zeitleiste mit den Wochentagen wurde unverändert beibehalten
   - Das bestehende Design wurde respektiert

5. **Zusätzliche Verbesserungen**:
   - Optimiertes Design der LessonCard-Komponente mit besserer Farbintegration
   - Verbesserter DatePicker mit Schnellauswahl-Buttons und Wochentyp-Anzeige
   - Neu gestaltete LessonDetailView mit besserem Layout und visueller Hierarchie

## Technische Details

### Farbgebung der Termine

Die Farben der Termine werden jetzt dynamisch basierend auf der aktuellen Woche angepasst:

```swift
// Konvertiere die Daten in Lesson-Objekte und passe die Farbe basierend auf der Woche an
let loadedLessons = lessonData.map { lessonData -> Lesson in
    var lesson = TimetableService.convertToLesson(lessonData: lessonData, date: selectedDate)
    
    // Passe die Farbe basierend auf der Woche an (grün oder rot)
    if isGreenWeek {
        // In grüner Woche: Grüne Farbtöne für alle Termine
        lesson = Lesson(
            subject: lesson.subject,
            room: lesson.room,
            teacher: lesson.teacher,
            timeSlot: lesson.timeSlot,
            color: .green,  // Grüne Farbe für alle Termine in grüner Woche
            startTime: lesson.startTime,
            endTime: lesson.endTime,
            isSchoolEvent: lesson.isSchoolEvent,
            targetGroups: lesson.targetGroups,
            notes: lesson.notes
        )
    } else {
        // In roter Woche: Rote Farbtöne für alle Termine
        lesson = Lesson(
            subject: lesson.subject,
            room: lesson.room,
            teacher: lesson.teacher,
            timeSlot: lesson.timeSlot,
            color: .red,  // Rote Farbe für alle Termine in roter Woche
            startTime: lesson.startTime,
            endTime: lesson.endTime,
            isSchoolEvent: lesson.isSchoolEvent,
            targetGroups: lesson.targetGroups,
            notes: lesson.notes
        )
    }
    
    return lesson
}
```

### Neugestaltung der Button-Leiste

Die Button-Leiste wurde in ein zweizeiliges Layout umgestaltet:

```swift
// Neu gestalteter Header mit Datum und Buttons
VStack(spacing: 8) {
    // Obere Zeile mit Datum und Heute-Button
    HStack {
        Button(action: { showDatePicker = true }) {
            HStack {
                Text(formattedDate(selectedDate, format: "EEEE, d. MMMM yyyy"))
                    .font(.headline)
                    .lineLimit(1)
                Image(systemName: "calendar")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(20)
        }
        .foregroundColor(colorScheme == .dark ? .white : .black)
        
        Spacer()
        
        Button(action: { 
            withAnimation(.spring()) {
                weekOffset = 0
                selectedDate = today 
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                Text("Heute")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(20)
        }
        .foregroundColor(.blue)
    }
    
    // Untere Zeile mit Navigation und Klasseninformation
    HStack {
        Button(action: {
            withAnimation(.spring()) {
                weekOffset -= 1
                selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
            }
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
                .padding(10)
                .background(Color.blue)
                .clipShape(Circle())
        }
        
        Spacer()
        
        // Anzeige des Jahrgangs
        if let schoolClass = currentUserClass(), userHasTimetable() {
            Text("Klasse \(schoolClass)")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
        }
        
        Spacer()
        
        Button(action: {
            withAnimation(.spring()) {
                weekOffset += 1
                selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
            }
        }) {
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
                .padding(10)
                .background(Color.blue)
                .clipShape(Circle())
        }
    }
}
```

## Fazit

Die vorgenommenen Änderungen verbessern das Design des Kalenders erheblich und erfüllen alle gestellten Anforderungen. Die Termine sind jetzt farblich klar nach Wochentyp unterscheidbar, die Benutzeroberfläche ist aufgeräumter und die Navigation wurde verbessert, während die Zeitleiste unverändert beibehalten wurde. 