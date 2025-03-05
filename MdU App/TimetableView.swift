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
    let startTime: Date
    let endTime: Date
}

struct TimetableView: View {
    @State private var selectedDate = Date()
    
    private let calendar = Calendar.current
    private let startDate = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
    private let endDate = Calendar.current.date(from: DateComponents(year: 2500, month: 1, day: 1))!
    
    private let days = ["MO", "DI", "MI", "DO", "FR"]
    
    private let lessonsByDay: [[Lesson]] = [
        [
            Lesson(subject: "Mathematik", room: "R1.101", teacher: "Dr. Meier", timeSlot: "8:00 - 9:30", color: .blue, startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!),
            Lesson(subject: "Deutsch", room: "R1.201", teacher: "Frau Schmidt", timeSlot: "9:45 - 11:15", color: .red, startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 45))!, endTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 15))!),
            Lesson(subject: "Englisch", room: "R2.101", teacher: "Mr. Brown", timeSlot: "11:35 - 13:05", color: .purple, startTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 35))!, endTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 5))!),
            Lesson(subject: "Physik", room: "R3.102", teacher: "Herr Weber", timeSlot: "13:50 - 15:20", color: .yellow, startTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 50))!, endTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 20))!),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray, startTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 30))!, endTime: Calendar.current.date(from: DateComponents(hour: 17, minute: 0))!)
        ],
        [
            Lesson(subject: "Biologie", room: "R2.301", teacher: "Frau Fischer", timeSlot: "8:00 - 9:30", color: .green, startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!),
            Lesson(subject: "Chemie", room: "R3.205", teacher: "Dr. Hoffmann", timeSlot: "9:45 - 11:15", color: .pink, startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 45))!, endTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 15))!),
            Lesson(subject: "Geschichte", room: "R1.112", teacher: "Herr Lehmann", timeSlot: "11:35 - 13:05", color: .cyan, startTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 35))!, endTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 5))!),
            Lesson(subject: "Kunst", room: "R4.104", teacher: "Frau Wagner", timeSlot: "13:50 - 15:20", color: .orange, startTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 50))!, endTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 20))!),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray, startTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 30))!, endTime: Calendar.current.date(from: DateComponents(hour: 17, minute: 0))!)
        ]
    ]
    
    private var weekInfo: String {
        let weekOfYear = calendar.component(.weekOfYear, from: selectedDate)
        let day = calendar.component(.day, from: selectedDate)
        let month = calendar.component(.month, from: selectedDate)
        let year = calendar.component(.year, from: selectedDate)
        let weekday = DateFormatter().weekdaySymbols[calendar.component(.weekday, from: selectedDate) - 1]
        return "KW \(weekOfYear), \(weekday), \(day).\(month).\(year)"
    }
    
    private func changeDay(by value: Int) {
        if let newDate = calendar.date(byAdding: .day, value: value, to: selectedDate), newDate >= startDate, newDate <= endDate {
            selectedDate = newDate
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(weekInfo)
                    .font(.headline)
                    .padding()
                
                HStack(spacing: 10) {
                    Button(action: { changeDay(by: -1) }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Button("Heute") {
                        selectedDate = Date()
                    }
                    .padding(.horizontal)
                    
                    Button(action: { changeDay(by: 1) }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        let dayIndex = (calendar.component(.weekday, from: selectedDate) + 5) % 7
                        if dayIndex >= 0 && dayIndex < days.count {
                            ForEach(lessonsByDay[dayIndex % lessonsByDay.count]) { lesson in
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
                                .padding(.trailing, 10)
                            }
                        } else {
                            Text("Kein Unterricht an diesem Tag")
                                .font(.title2)
                                .padding()
                        }
                    }
                    .padding()
                }
                .gesture(DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            changeDay(by: 1)
                        } else if value.translation.width > 50 {
                            changeDay(by: -1)
                        }
                    }
                )
            }
            .navigationBarTitle("Stundenplan", displayMode: .inline)
        }
    }
}

struct TimetableView_Previews: PreviewProvider {
    static var previews: some View {
        TimetableView()
    }
}
