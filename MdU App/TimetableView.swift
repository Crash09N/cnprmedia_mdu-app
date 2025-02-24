//
//  TimetableView.swift
//  MdU App
//
//  Created by Mats Kahmann on 24.02.25.
//

import SwiftUI

struct Lesson: Identifiable {
    let id = UUID()
    let subject: String
    let room: String
    let teacher: String
    let timeSlot: String
    let color: Color
}

struct TimetableView: View {
    @State private var selectedDayIndex = 0
    @Environment(\.presentationMode) var presentationMode
    private let days = ["MO", "DI", "MI", "DO", "FR"]
    
    private let lessonsByDay: [[Lesson]] = [
        [ // Montag
            Lesson(subject: "Mathematik", room: "R1.101", teacher: "Dr. Meier", timeSlot: "8:00 - 9:30", color: .blue),
            Lesson(subject: "Deutsch", room: "R1.201", teacher: "Frau Schmidt", timeSlot: "9:45 - 11:15", color: .red),
            Lesson(subject: "Englisch", room: "R2.101", teacher: "Mr. Brown", timeSlot: "11:35 - 13:05", color: .purple),
            Lesson(subject: "Physik", room: "R3.102", teacher: "Herr Weber", timeSlot: "13:50 - 15:20", color: .yellow),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray)
        ],
        [ // Dienstag
            Lesson(subject: "Biologie", room: "R2.301", teacher: "Frau Fischer", timeSlot: "8:00 - 9:30", color: .green),
            Lesson(subject: "Chemie", room: "R3.205", teacher: "Dr. Hoffmann", timeSlot: "9:45 - 11:15", color: .pink),
            Lesson(subject: "Geschichte", room: "R1.112", teacher: "Herr Lehmann", timeSlot: "11:35 - 13:05", color: .cyan),
            Lesson(subject: "Kunst", room: "R4.104", teacher: "Frau Wagner", timeSlot: "13:50 - 15:20", color: .orange),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray)
        ],
        [ // Mittwoch
            Lesson(subject: "Informatik", room: "R5.101", teacher: "Herr Krause", timeSlot: "8:00 - 9:30", color: .blue),
            Lesson(subject: "Sport", room: "Sporthalle", teacher: "Frau Becker", timeSlot: "9:45 - 11:15", color: .green),
            Lesson(subject: "Musik", room: "Musiksaal", teacher: "Herr Mayer", timeSlot: "11:35 - 13:05", color: .red),
            Lesson(subject: "Philosophie", room: "R3.201", teacher: "Dr. Schulz", timeSlot: "13:50 - 15:20", color: .purple),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray)
        ],
        [ // Donnerstag
            Lesson(subject: "Sozialkunde", room: "R2.202", teacher: "Frau Keller", timeSlot: "8:00 - 9:30", color: .brown),
            Lesson(subject: "Französisch", room: "R1.204", teacher: "Herr Dupont", timeSlot: "9:45 - 11:15", color: .yellow),
            Lesson(subject: "Mathematik", room: "R1.101", teacher: "Dr. Meier", timeSlot: "11:35 - 13:05", color: .blue),
            Lesson(subject: "Erdkunde", room: "R3.303", teacher: "Frau Zimmer", timeSlot: "13:50 - 15:20", color: .green),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray)
        ],
        [ // Freitag
            Lesson(subject: "Latein", room: "R1.304", teacher: "Herr Römer", timeSlot: "8:00 - 9:30", color: .red),
            Lesson(subject: "Psychologie", room: "R2.401", teacher: "Frau Seidel", timeSlot: "9:45 - 11:15", color: .purple),
            Lesson(subject: "Wirtschaft", room: "R3.501", teacher: "Herr Wagner", timeSlot: "11:35 - 13:05", color: .cyan),
            Lesson(subject: "Ethik", room: "R2.123", teacher: "Dr. Braun", timeSlot: "13:50 - 15:20", color: .orange),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray)
        ]
    ]
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date().addingTimeInterval(Double(selectedDayIndex * 86400)))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text(formattedDate)
                        .font(.headline)
                    Spacer()
                    Button("Heute") {
                        selectedDayIndex = 0
                    }
                    .padding(.horizontal)
                }
                .padding()
                
                TabView(selection: $selectedDayIndex) {
                    ForEach(0..<days.count, id: \.self) { index in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(lessonsByDay[index]) { lesson in
                                    HStack {
                                        Text(lesson.timeSlot)
                                            .font(.caption2)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        VStack(alignment: .leading) {
                                            Text(lesson.subject).font(.headline)
                                            if !lesson.room.isEmpty { Text(lesson.room).font(.caption).foregroundColor(.gray) }
                                            if !lesson.teacher.isEmpty { Text(lesson.teacher).font(.caption).foregroundColor(.gray) }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(lesson.color.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.trailing, 10) // Abstand zum rechten Rand
                                }
                            }
                            .padding()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarTitle("Timetable", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zurück") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

// **Preview für Xcode hinzufügen**
struct TimetableView_Previews: PreviewProvider {
    static var previews: some View {
        TimetableView()
    }
}

