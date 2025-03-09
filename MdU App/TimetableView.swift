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
                    
                    // Konvertiere die Daten in Lesson-Objekte
                    let loadedLessons = lessonData.map { TimetableService.convertToLesson(lessonData: $0, date: selectedDate) }
                    
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
    
    // Gibt an, ob es sich um eine grüne oder rote Woche handelt
    private func weekTypeString() -> String {
        return TimetableService.isGreenWeek(for: selectedDate) ? "Grüne Woche" : "Rote Woche"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header mit Datum und Buttons
                HStack(spacing: 16) {
                    Button(action: { showDatePicker = true }) {
                        HStack {
                            Text(formattedDate(selectedDate, format: "MMMM yyyy"))
                                .font(.headline)
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
                            weekOffset -= 1
                            selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .frame(width: 35)

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

                    Button(action: {
                        withAnimation(.spring()) {
                            weekOffset += 1
                            selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .frame(width: 35)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Anzeige des Jahrgangs und Wochentyps (rot/grün)
                if let schoolClass = currentUserClass(), userHasTimetable() {
                    HStack {
                        Text("Klasse: \(schoolClass)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(weekTypeString())
                            .font(.subheadline)
                            .foregroundColor(TimetableService.isGreenWeek(for: selectedDate) ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(TimetableService.isGreenWeek(for: selectedDate) ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            )
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                // Wochenansicht
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(daysInWeek(for: selectedDate), id: \.self) { date in
                            VStack(spacing: 6) {
                                Text(formattedDate(date, format: "E"))
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Button(action: {
                                    withAnimation(.spring()) {
                                        selectedDate = date
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    Text(formattedDate(date, format: "d"))
                                        .font(.system(size: 16, weight: .semibold))
                                        .frame(width: 36, height: 36)
                                        .background(
                                            ZStack {
                                                if calendar.isDate(date, inSameDayAs: selectedDate) {
                                                    Circle()
                                                        .fill(Color.blue)
                                                } else if calendar.isDate(date, inSameDayAs: today) {
                                                    Circle()
                                                        .stroke(Color.blue, lineWidth: 2)
                                                }
                                            }
                                        )
                                        .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : (colorScheme == .dark ? .white : .black))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                .animation(.spring(), value: weekOffset)

                // Terminliste
                ScrollView {
                    VStack(spacing: 15) {
                        if isLoading {
                            ProgressView()
                                .padding(.top, 50)
                        } else {
                            let todaysLessons = lessonsForDay()
                            let hasLessons = !todaysLessons.isEmpty
                            
                            if !hasLessons {
                                // Tag ohne Termine
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                        .padding(.top, 50)
                                    
                                    if let schoolClass = currentUserClass(), userHasTimetable() {
                                        Text("Keine Termine für \(schoolClass) am \(formattedDate(selectedDate, format: "EEEE, dd.MM.yyyy"))")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    } else {
                                        Text("Keine Termine für den \(formattedDate(selectedDate, format: "EEEE, dd.MM.yyyy"))")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        
                                        if currentUserClass() == nil {
                                            Text("Bitte melde dich an und wähle deinen Jahrgang, um deinen Stundenplan zu sehen.")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                                .padding(.top, 8)
                                        } else {
                                            Text("Für deinen Jahrgang sind keine Stundenpläne verfügbar.")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal)
                                                .padding(.top, 8)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                // Termine anzeigen
                                ForEach(todaysLessons, id: \.id) { lesson in
                                    LessonCard(lesson: lesson, savedNotes: savedNotes[lesson.id])
                                        .onTapGesture {
                                            selectedLesson = lesson
                                            showLessonDetail = true
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
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
                .sheet(isPresented: $showLessonDetail) {
                    if let lesson = selectedLesson {
                        LessonDetailView(
                            lesson: lesson,
                            onSaveNotes: { notes in
                                if let id = selectedLesson?.id {
                                    savedNotes[id] = notes
                                }
                            }
                        )
                    }
                }
            }
            .navigationBarTitle("Stundenplan", displayMode: .inline)
        }
    }
}

// Karte für einen Termin
struct LessonCard: View {
    let lesson: Lesson
    let savedNotes: String?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Rectangle()
                    .fill(lesson.color)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                Text(lesson.timeSlot)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Subject
                Text(lesson.subject)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                // Room and Teacher
                HStack {
                    if !lesson.room.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(lesson.color)
                            
                            Text(lesson.room)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if !lesson.teacher.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(lesson.color)
                            
                            Text(lesson.teacher)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Notes (if any)
                if let notes = savedNotes, !notes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 14))
                            .foregroundColor(lesson.color)
                        
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 4)
                } else if !lesson.notes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                            .font(.system(size: 14))
                            .foregroundColor(lesson.color)
                        
                        Text(lesson.notes)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// Datumsauswahl-View
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Datum auswählen",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding()
                
                Spacer()
            }
            .navigationBarTitle("Datum auswählen", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Abbrechen") {
                    showDatePicker = false
                },
                trailing: Button("Fertig") {
                    showDatePicker = false
                }
            )
        }
    }
}

// Detailansicht für Termine
struct LessonDetailView: View {
    let lesson: Lesson
    var onSaveNotes: (String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var notes: String
    
    init(lesson: Lesson, onSaveNotes: @escaping (String) -> Void) {
        self.lesson = lesson
        self.onSaveNotes = onSaveNotes
        _notes = State(initialValue: lesson.notes)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header mit Fach und Zeit
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lesson.subject)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(lesson.color)
                            
                            Text(lesson.timeSlot)
                                .foregroundColor(.secondary)
                        }
                        .font(.system(size: 16))
                    }
                    .padding(.bottom, 10)
                    
                    // Raum und Lehrer
                    if !lesson.room.isEmpty || !lesson.teacher.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if !lesson.room.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(lesson.color)
                                        .frame(width: 24)
                                    
                                    Text("Raum")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Text(lesson.room)
                                        .font(.system(size: 16))
                                }
                            }
                            
                            if !lesson.teacher.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(lesson.color)
                                        .frame(width: 24)
                                    
                                    Text("Lehrer")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Text(lesson.teacher)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Notizen
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(lesson.color)
                            
                            Text("Notizen")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 150)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onChange(of: notes) { newValue in
                                // Speichere die Notizen automatisch beim Tippen
                                onSaveNotes(newValue)
                            }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Termindetails", displayMode: .inline)
            .navigationBarItems(trailing: Button("Fertig") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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
