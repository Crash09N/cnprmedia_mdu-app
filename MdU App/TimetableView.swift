//
//  TimetableView.swift
//  MdU App
//
//  Created by Mats Kahmann on 24.02.25.
//

import SwiftUI

// Struktur für einen Unterrichtstermin
struct Lesson: Identifiable {
    let id: UUID
    let subject: String
    let room: String
    let teacher: String
    let timeSlot: String
    let color: Color
    let startTime: Date
    let endTime: Date
    let isSchoolEvent: Bool
    let targetGroups: [String]
    var notes: String
    
    init(subject: String, room: String = "", teacher: String = "", timeSlot: String, color: Color = .gray, startTime: Date, endTime: Date, isSchoolEvent: Bool = false, targetGroups: [String] = [], notes: String = "") {
        self.id = UUID()
        self.subject = subject
        self.room = room
        self.teacher = teacher
        self.timeSlot = timeSlot
        self.color = color
        self.startTime = startTime
        self.endTime = endTime
        self.isSchoolEvent = isSchoolEvent
        self.targetGroups = targetGroups
        self.notes = notes
    }
}

struct TimetableView: View {
    @State private var selectedDate = Date()
    @State private var today = Date()
    @State private var showDatePicker = false
    @Environment(\.colorScheme) var colorScheme
    @State private var weekOffset: Int = 0
    @State private var lessons: [Lesson] = []
    @State private var isLoading = false
    @State private var selectedLesson: Lesson? = nil
    @State private var showLessonDetail = false
    
    // Speicher für Notizen (in einer echten App würde man CoreData oder UserDefaults verwenden)
    @State private var savedNotes: [UUID: String] = [:]

    private let calendar = Calendar.current
    private let daysToShow = 7
    
    // Initialisierung mit optionalem Startdatum
    init(initialDate: Date = Date()) {
        _selectedDate = State(initialValue: initialDate)
        _today = State(initialValue: Date())
    }

    private func formattedDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    private func startOfWeek(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let offset = weekday == 1 ? -6 : -(weekday - 2)
        return calendar.date(byAdding: .day, value: offset, to: date)!
    }

    private func daysInWeek(for date: Date) -> [Date] {
        let start = startOfWeek(for: date)
        return (0..<daysToShow).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func loadLessons() {
        guard !isLoading else { return }
        isLoading = true
        
        // Prüfe, ob ein Benutzer angemeldet ist und einen Jahrgang hat
        if let user = CoreDataManager.shared.getCurrentUser(), let schoolClass = user.schoolClass {
            print("Benutzer gefunden mit Jahrgang: \(schoolClass)")
            
            // Prüfe, ob für diesen Jahrgang Stundenpläne existieren
            if TimetableService.timetableExists(for: schoolClass) {
                print("Stundenpläne existieren für Jahrgang: \(schoolClass)")
                
                // Bestimme den Wochentag
                let weekday = calendar.component(.weekday, from: selectedDate)
                let weekdayString = TimetableService.weekdayString(for: weekday)
                print("Wochentag: \(weekdayString) (Index: \(weekday))")
                
                // Bestimme, ob es eine grüne oder rote Woche ist
                let isGreenWeek = TimetableService.isGreenWeek(for: selectedDate)
                print("Grüne Woche: \(isGreenWeek)")
                
                // Lade den Stundenplan
                if let lessonData = TimetableService.loadTimetable(for: schoolClass, weekday: weekdayString, isGreenWeek: isGreenWeek) {
                    print("Stundenplan geladen mit \(lessonData.count) Terminen")
                    
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
                    
                    DispatchQueue.main.async {
                        self.lessons = loadedLessons
                        self.isLoading = false
                    }
                    return
                } else {
                    // Keine Daten für diesen Tag gefunden
                    print("Keine Daten für \(weekdayString) (\(isGreenWeek ? "Grüne" : "Rote") Woche) gefunden")
                    DispatchQueue.main.async {
                        self.lessons = []
                        self.isLoading = false
                    }
                    return
                }
            } else {
                print("Keine Stundenpläne für Jahrgang: \(schoolClass) gefunden")
            }
        } else {
            print("Kein Benutzer angemeldet oder kein Jahrgang gesetzt")
        }
        
        // Fallback auf leere Liste, wenn keine JSON-Daten geladen werden konnten
        DispatchQueue.main.async {
            self.lessons = []
            self.isLoading = false
        }
    }

    private func lessonsForDay() -> [Lesson] {
        // Nur Termine für Schultage (Montag bis Freitag) anzeigen
        let weekday = calendar.component(.weekday, from: selectedDate)
        if weekday == 1 || weekday == 7 { // Sonntag oder Samstag
            return []
        }
        
        return lessons
    }
    
    // Bestimmt, ob der aktuelle Benutzer einen Stundenplan hat
    private func userHasTimetable() -> Bool {
        if let user = CoreDataManager.shared.getCurrentUser(), let schoolClass = user.schoolClass {
            return TimetableService.timetableExists(for: schoolClass)
        }
        return false
    }
    
    // Gibt den Jahrgang des aktuellen Benutzers zurück
    private func currentUserClass() -> String? {
        return CoreDataManager.shared.getCurrentUser()?.schoolClass
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Minimalistischer Header mit Datum und Buttons
                HStack {
                    // Datumsanzeige mit Picker-Button
                    Button(action: { showDatePicker = true }) {
                        HStack(spacing: 6) {
                            Text(formattedDate(selectedDate, format: "d. MMMM yyyy"))
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Spacer()
                    
                    // Wochentyp-Anzeige (minimalistisch)
                    let isGreenWeek = TimetableService.isGreenWeek(for: selectedDate)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(isGreenWeek ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(isGreenWeek ? "Grüne Woche" : "Rote Woche")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Heute-Button
                    Button(action: { 
                        withAnimation(.spring()) {
                            weekOffset = 0
                            selectedDate = today 
                        }
                    }) {
                        Text("Heute")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Minimalistischere Wochenansicht
                HStack(spacing: 0) {
                    ForEach(daysInWeek(for: selectedDate), id: \.self) { date in
                        VStack(spacing: 4) {
                            // Wochentag (Mo, Di, etc.)
                            Text(formattedDate(date, format: "E"))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.top, 4)

                            // Tag des Monats
                            Button(action: {
                                withAnimation(.spring()) {
                                    selectedDate = date
                                }
                            }) {
                                Text(formattedDate(date, format: "d"))
                                    .font(.system(size: 16, weight: calendar.isDate(date, inSameDayAs: selectedDate) ? .semibold : .regular))
                                    .frame(width: 32, height: 32)
                                    .background(
                                        ZStack {
                                            if calendar.isDate(date, inSameDayAs: selectedDate) {
                                                Circle()
                                                    .fill(Color.blue)
                                            } else if calendar.isDate(date, inSameDayAs: today) {
                                                Circle()
                                                    .stroke(Color.blue, lineWidth: 1)
                                            }
                                        }
                                    )
                                    .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : (colorScheme == .dark ? .white : .black))
                            }
                            
                            // Indikator für Termine
                            if hasLessonsForDate(date) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 4, height: 4)
                                    .padding(.bottom, 4)
                            } else {
                                Spacer()
                                    .frame(height: 8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 4)
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .bottom
                )
                .animation(.spring(), value: weekOffset)

                // Navigationspfeile für Wochen
                HStack {
                    Button(action: {
                        withAnimation(.spring()) {
                            weekOffset -= 1
                            selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                    
                    Spacer()
                    
                    // Klassenanzeige
                    if let schoolClass = currentUserClass(), userHasTimetable() {
                        Text("Klasse \(schoolClass)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            weekOffset += 1
                            selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

                // Terminliste
                ScrollView {
                    VStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .padding(.top, 50)
                        } else {
                            let todaysLessons = lessonsForDay()
                            let hasLessons = !todaysLessons.isEmpty
                            
                            if !hasLessons {
                                // Tag ohne Termine (minimalistisch)
                                VStack(spacing: 8) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 36))
                                        .foregroundColor(.gray.opacity(0.7))
                                        .padding(.top, 40)
                                    
                                    if let schoolClass = currentUserClass(), userHasTimetable() {
                                        Text("Keine Termine für \(schoolClass)")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    } else {
                                        Text("Keine Termine")
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                // Termine anzeigen (minimalistisch)
                                ForEach(todaysLessons, id: \.id) { lesson in
                                    MinimalistLessonCard(lesson: lesson, savedNotes: savedNotes[lesson.id])
                                        .onTapGesture {
                                            selectedLesson = lesson
                                            DispatchQueue.main.async {
                                                showLessonDetail = true
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .onAppear {
                    loadLessons()
                }
                .onChange(of: selectedDate) { _ in
                    loadLessons()
                }
                .sheet(isPresented: $showDatePicker) {
                    DatePickerView(selectedDate: $selectedDate, showDatePicker: $showDatePicker)
                }
                .sheet(isPresented: $showLessonDetail, onDismiss: {
                    selectedLesson = nil
                }) {
                    if let lesson = selectedLesson {
                        LessonDetailView(
                            lesson: lesson,
                            onSaveNotes: { notes in
                                if let id = selectedLesson?.id {
                                    savedNotes[id] = notes
                                }
                            }
                        )
                        .interactiveDismissDisabled()
                    }
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
        }
    }
    
    // Prüft, ob für ein bestimmtes Datum Termine vorhanden sind
    private func hasLessonsForDate(_ date: Date) -> Bool {
        // Nur Termine für Schultage (Montag bis Freitag) anzeigen
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 { // Sonntag oder Samstag
            return false
        }
        
        // Hier könnte eine Logik implementiert werden, um zu prüfen, ob für diesen Tag Termine existieren
        // Für dieses Beispiel nehmen wir an, dass an Wochentagen immer Termine existieren
        return true
    }
}

// Minimalistischere Karte für einen Termin
struct MinimalistLessonCard: View {
    let lesson: Lesson
    let savedNotes: String?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Farbiger Indikator
            Rectangle()
                .fill(lesson.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            // Zeit
            VStack(alignment: .leading, spacing: 0) {
                Text(lesson.timeSlot.components(separatedBy: " - ")[0])
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                if lesson.timeSlot.contains(" - ") {
                    Text(lesson.timeSlot.components(separatedBy: " - ")[1])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 50)
            
            // Inhalt
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.subject)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    if !lesson.room.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text(lesson.room)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !lesson.teacher.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text(lesson.teacher)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Notizindikator
            if let notes = savedNotes, !notes.isEmpty {
                Image(systemName: "note.text")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Pfeil für Details
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.7) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Minimalistischere Datumsauswahl-View
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var tempDate: Date
    
    init(selectedDate: Binding<Date>, showDatePicker: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._showDatePicker = showDatePicker
        self._tempDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Wochentyp-Anzeige (minimalistisch)
                let isGreenWeek = TimetableService.isGreenWeek(for: tempDate)
                HStack {
                    Circle()
                        .fill(isGreenWeek ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(isGreenWeek ? "Grüne Woche" : "Rote Woche")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
                
                // Minimalistischer DatePicker
                DatePicker(
                    "Datum auswählen",
                    selection: $tempDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding(.horizontal)
                
                // Schnellauswahl-Buttons (minimalistisch)
                HStack(spacing: 12) {
                    MinimalistQuickSelectButton(title: "Heute", action: {
                        tempDate = Date()
                    })
                    
                    MinimalistQuickSelectButton(title: "Morgen", action: {
                        tempDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                    })
                    
                    MinimalistQuickSelectButton(title: "Nächste Woche", action: {
                        tempDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
                    })
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitle("Datum auswählen", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Abbrechen") {
                    showDatePicker = false
                },
                trailing: Button("Fertig") {
                    selectedDate = tempDate
                    showDatePicker = false
                }
            )
        }
    }
}

// Minimalistischer Schnellauswahl-Button
struct MinimalistQuickSelectButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
                .foregroundColor(.blue)
        }
    }
}

// Detailansicht für Termine
struct LessonDetailView: View {
    let lesson: Lesson
    var onSaveNotes: (String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var notes: String
    
    init(lesson: Lesson, onSaveNotes: @escaping (String) -> Void) {
        self.lesson = lesson
        self.onSaveNotes = onSaveNotes
        _notes = State(initialValue: lesson.notes)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Moderner Header mit farbigem Fachnamen
                    VStack(spacing: 0) {
                        // Farbiger Balken oben
                        Rectangle()
                            .fill(lesson.color)
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        // Fachname in der Mitte mit Farbakzent
                        Text(lesson.subject)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(lesson.color)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(lesson.color.opacity(0.1))
                            )
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(lesson.color.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    // Länglicher Termin in der Mitte
                    HStack {
                        Spacer()
                        
                        Text(formattedWeekday(for: lesson.startTime))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                        
                        Spacer()
                    }
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    )
                    .padding(.horizontal, 40)
                    
                    // Informationsbereich mit modernem Design
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Informationen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            // Zeit als Teil der Informationen
                            InfoCard(
                                icon: "clock",
                                title: "Zeit",
                                content: lesson.timeSlot,
                                color: lesson.color
                            )
                            
                            if !lesson.room.isEmpty {
                                InfoCard(
                                    icon: "mappin",
                                    title: "Raum",
                                    content: lesson.room,
                                    color: lesson.color
                                )
                            }
                            
                            if !lesson.teacher.isEmpty {
                                InfoCard(
                                    icon: "person",
                                    title: "Lehrer",
                                    content: lesson.teacher,
                                    color: lesson.color
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Notizen mit modernem Design
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notizen")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(Color.clear)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 30)
                }
                .padding(.vertical, 16)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Zurück")
                    }
                    .foregroundColor(.blue)
                },
                trailing: Button(action: {
                    onSaveNotes(notes)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Speichern")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
            )
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
        }
    }
    
    // Formatiert den Wochentag für das angegebene Datum
    private func formattedWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: date)
    }
}

// Moderne Infokarte für die Detailansicht
struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
            }
            
            // Inhalt
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Hilfsstruct für Informationsabschnitte
struct InfoSection: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.body)
                .padding(.leading, 26)
        }
        .padding(.vertical, 8)
    }
}
