//
//  TimetableView.swift
//  MdU App
//
//  Created by Mats Kahmann on 24.02.25.
//

import SwiftUI

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
        
        // Mock-Daten laden
        let mockLessons = [
            Lesson(subject: "Mathematik", room: "R1.101", teacher: "Dr. Schmidt", timeSlot: "08:00 - 09:30", color: .red, startTime: selectedDate, endTime: selectedDate, notes: savedNotes[UUID()] ?? "Hausaufgaben: Seite 42, Aufgaben 1-5"),
            Lesson(subject: "Englisch", room: "R2.102", teacher: "Fr. Müller", timeSlot: "09:45 - 11:15", color: .blue, startTime: selectedDate, endTime: selectedDate, notes: savedNotes[UUID()] ?? "Vokabeltest nächste Woche"),
            Lesson(subject: "Deutsch", room: "R3.103", teacher: "Hr. Meyer", timeSlot: "11:30 - 13:00", color: .green, startTime: selectedDate, endTime: selectedDate, notes: savedNotes[UUID()] ?? "Buchvorstellung vorbereiten")
        ]
        
        DispatchQueue.main.async {
            self.lessons = mockLessons
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
                                        .padding()
                                    
                                    Text("Keine Termine")
                                        .font(.title2.bold())
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                            } else {
                                ForEach(todaysLessons, id: \.id) { lesson in
                                    LessonCard(lesson: lesson)
                                        .padding(.horizontal)
                                        .onTapGesture {
                                            selectedLesson = lesson
                                            showLessonDetail = true
                                        }
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitle("Stundenplan", displayMode: .inline)
            .sheet(isPresented: $showDatePicker) {
                DatePickerView(selectedDate: $selectedDate, showDatePicker: $showDatePicker)
            }
            .sheet(isPresented: $showLessonDetail) {
                if let lesson = selectedLesson {
                    LessonDetailView(
                        lesson: lesson,
                        onSaveNotes: { updatedNotes in
                            // Speichere die Notizen
                            savedNotes[lesson.id] = updatedNotes
                            
                            // Aktualisiere die Lektion in der Liste
                            if let index = lessons.firstIndex(where: { $0.id == lesson.id }) {
                                lessons[index].notes = updatedNotes
                            }
                        }
                    )
                }
            }
            .onAppear {
                loadLessons()
            }
        }
    }
}

// Neue LessonCard View für besseres Styling
struct LessonCard: View {
    let lesson: Lesson
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                // Zeitleiste
                VStack(alignment: .trailing) {
                    Text(lesson.timeSlot)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(width: 85)
                
                Rectangle()
                    .fill(lesson.isSchoolEvent ? Color.gray : lesson.color)
                    .frame(width: 4, height: 65)
                    .cornerRadius(2)
                
                // Hauptinhalt
                VStack(alignment: .leading, spacing: 8) {
                    Text(lesson.subject)
                        .font(.system(size: 18, weight: .bold))
                    
                    if lesson.isSchoolEvent {
                        // Für Schultermine
                        if !lesson.targetGroups.isEmpty {
                            HStack(spacing: 12) {
                                Label(lesson.targetGroups.joined(separator: ", "), systemImage: "person.2.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if !lesson.room.isEmpty || !lesson.teacher.isEmpty {
                            HStack(spacing: 12) {
                                if !lesson.room.isEmpty {
                                    Label(lesson.room, systemImage: "mappin.circle")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                                
                                if !lesson.teacher.isEmpty {
                                    Label(lesson.teacher, systemImage: "info.circle")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    } else {
                        // Für reguläre Unterrichtsstunden
                        HStack(spacing: 12) {
                            Label(lesson.room, systemImage: "location.fill")
                            Label(lesson.teacher, systemImage: "person.fill")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    }
                }
                .padding(.leading, 12)
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
        }
        .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// DatePickerView mit modernem Kalender-Design
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool
    @State private var selectedMonth: Date
    
    init(selectedDate: Binding<Date>, showDatePicker: Binding<Bool>) {
        self._selectedDate = selectedDate
        self._showDatePicker = showDatePicker
        self._selectedMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private func moveMonth(by months: Int) {
        if let newDate = calendar.date(byAdding: .month, value: months, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func daysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        
        var dates: [Date] = []
        calendar.enumerateDates(
            startingAfter: dateInterval.start - 1,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date <= dateInterval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        return dates
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { showDatePicker = false }) {
                    Text("Abbrechen")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: { showDatePicker = false }) {
                    Text("Fertig")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            // Month Navigation
            HStack {
                Button(action: { moveMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                        .padding()
                }
                
                Text(monthFormatter.string(from: selectedMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                
                Button(action: { moveMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                        .padding()
                }
            }
            .padding(.horizontal)
            
            // Weekday Headers
            HStack {
                ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(for: selectedMonth), id: \.self) { date in
                    Button(action: {
                        selectedDate = date
                        withAnimation {
                            showDatePicker = false
                        }
                    }) {
                        Text(dayFormatter.string(from: date))
                            .font(.system(.body, design: .rounded))
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(
                                calendar.isDate(date, inSameDayAs: selectedDate) ?
                                    Color.blue :
                                    calendar.isDate(date, inSameDayAs: Date()) ?
                                        Color.blue.opacity(0.3) :
                                        calendar.component(.month, from: date) == calendar.component(.month, from: selectedMonth) ?
                                            Color.clear :
                                            Color.gray.opacity(0.1)
                            )
                            .foregroundColor(
                                calendar.isDate(date, inSameDayAs: selectedDate) ?
                                    .white :
                                    calendar.component(.month, from: date) == calendar.component(.month, from: selectedMonth) ?
                                        .primary :
                                        .gray
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
    }
}

// 🔹 Lesson Model
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

// Detailansicht für Termine
struct LessonDetailView: View {
    let lesson: Lesson
    let onSaveNotes: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var notes: String
    @State private var isEditingNotes = false
    
    init(lesson: Lesson, onSaveNotes: @escaping (String) -> Void) {
        self.lesson = lesson
        self.onSaveNotes = onSaveNotes
        self._notes = State(initialValue: lesson.notes)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header mit Farbbalken
                    HStack {
                        Rectangle()
                            .fill(lesson.isSchoolEvent ? Color.gray : lesson.color)
                            .frame(width: 8)
                            .cornerRadius(4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(lesson.subject)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(lesson.timeSlot)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Informationsblöcke
                    VStack(alignment: .leading, spacing: 12) {
                        if lesson.isSchoolEvent {
                            // Für Schultermine
                            InfoSection(title: "Art", content: "Schulevent", icon: "calendar.badge.exclamationmark")
                            
                            if !lesson.targetGroups.isEmpty {
                                InfoSection(title: "Zielgruppe", content: lesson.targetGroups.joined(separator: ", "), icon: "person.2.fill")
                            }
                        } else {
                            // Für reguläre Unterrichtsstunden
                            InfoSection(title: "Art", content: "Unterrichtsstunde", icon: "book.fill")
                        }
                        
                        if !lesson.room.isEmpty {
                            InfoSection(title: "Ort", content: lesson.room, icon: "mappin.circle.fill")
                        }
                        
                        if !lesson.teacher.isEmpty {
                            InfoSection(title: lesson.isSchoolEvent ? "Information" : "Lehrkraft", content: lesson.teacher, icon: lesson.isSchoolEvent ? "info.circle.fill" : "person.fill")
                        }
                        
                        // Datum
                        InfoSection(title: "Datum", content: dateFormatter.string(from: lesson.startTime), icon: "calendar")
                        
                        // Notizen (nur für Schulstunden)
                        if !lesson.isSchoolEvent {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.blue)
                                    Text("Notizen")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Wenn wir den Bearbeitungsmodus verlassen, speichern wir automatisch
                                        if isEditingNotes {
                                            saveNotes()
                                        }
                                        isEditingNotes.toggle()
                                    }) {
                                        Text(isEditingNotes ? "Fertig" : "Bearbeiten")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                if isEditingNotes {
                                    TextEditor(text: $notes)
                                        .frame(minHeight: 100)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                        .onChange(of: notes) { newValue in
                                            // Speichere die Notizen automatisch bei jeder Änderung
                                            onSaveNotes(newValue)
                                        }
                                } else {
                                    if notes.isEmpty {
                                        Text("Keine Notizen vorhanden")
                                            .italic()
                                            .foregroundColor(.gray)
                                            .padding(.leading, 26)
                                    } else {
                                        Text(notes)
                                            .padding(.leading, 26)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Termindetails", displayMode: .inline)
            .navigationBarItems(trailing: Button("Schließen") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func saveNotes() {
        // Rufe den Callback auf, um die Notizen zu speichern
        onSaveNotes(notes)
        
        // Zeige kurze Bestätigung
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
