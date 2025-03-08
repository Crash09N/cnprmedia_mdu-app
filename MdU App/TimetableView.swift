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
    private let daysToShow = 7
    private let startYear = 2025
    private let endYear = 2100
    
    private let lessonsByDay: [[Lesson]] = [
        [
            Lesson(subject: "Mathematik", room: "R1.101", teacher: "Dr. Meier", timeSlot: "8:00 - 9:30", color: Color.red.opacity(0.2), startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!)
        ],
        [
            Lesson(subject: "Deutsch", room: "R1.201", teacher: "Frau Schmidt", timeSlot: "9:45 - 11:15", color: Color.red.opacity(0.2), startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 45))!, endTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 15))!)
        ],
        [
            Lesson(subject: "Englisch", room: "R2.101", teacher: "Mr. Brown", timeSlot: "11:35 - 13:05", color: Color.red.opacity(0.2), startTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 35))!, endTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 5))!)
        ],
        [
            Lesson(subject: "Physik", room: "R3.102", teacher: "Herr Weber", timeSlot: "13:50 - 15:20", color: Color.red.opacity(0.2), startTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 50))!, endTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 20))!)
        ],
        [
            Lesson(subject: "Biologie", room: "R2.301", teacher: "Frau Fischer", timeSlot: "8:00 - 9:30", color: Color.red.opacity(0.2), startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!)
        ],
        [],
        []
    ]
    
    private func formattedDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    private func startOfWeek(for date: Date) -> Date {
        let weekday = calendar.component(.weekday, from: date) - 2
        return calendar.date(byAdding: .day, value: -weekday, to: date)!
    }
    
    private func daysInWeek() -> [Date] {
        let start = startOfWeek(for: selectedDate)
        return (0..<daysToShow).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // **Monat, Jahr & Heute-Button**
                HStack {
                    Text(formattedDate(selectedDate, format: "MMMM yyyy"))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedDate = Date() // Springt zu HEUTE
                    }) {
                        Text("Heute")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // **Tagesanzeige (fixiert)**
                HStack {
                    ForEach(daysInWeek(), id: \.self) { date in
                        VStack {
                            Text(formattedDate(date, format: "E")) // Wochentag
                                .font(.caption)
                                .foregroundColor(date == selectedDate ? .black : .gray)
                            
                            Text(formattedDate(date, format: "d")) // Datum
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(width: 40, height: 40)
                                .background(date == selectedDate ? Color.red : Color.clear)
                                .clipShape(Circle())
                                .foregroundColor(date == selectedDate ? .white : .black)
                        }
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.vertical, 10)

                // **Stundenplan**
                ScrollView {
                    VStack(spacing: 10) {
                        let dayIndex = (calendar.component(.weekday, from: selectedDate) + 5) % 7
                        if dayIndex >= 0 && dayIndex < lessonsByDay.count {
                            if lessonsByDay[dayIndex].isEmpty {
                                Text("Kein Unterricht an diesem Tag")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(lessonsByDay[dayIndex]) { lesson in
                                    HStack {
                                        Text(lesson.timeSlot)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .frame(width: 70, alignment: .trailing)
                                        
                                        Rectangle()
                                            .frame(width: 2, height: 50)
                                            .foregroundColor(Color.gray.opacity(0.3))
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(lesson.subject)
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                            
                                            HStack {
                                                if !lesson.room.isEmpty {
                                                    Text("📍 \(lesson.room)")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                                if !lesson.teacher.isEmpty {
                                                    Text("👩‍🏫 \(lesson.teacher)")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
                .gesture(DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            let newDate = calendar.date(byAdding: .day, value: 7, to: selectedDate)
                            if let newDate = newDate, calendar.component(.year, from: newDate) <= endYear {
                                selectedDate = newDate
                            }
                        } else if value.translation.width > 50 {
                            let newDate = calendar.date(byAdding: .day, value: -7, to: selectedDate)
                            if let newDate = newDate, calendar.component(.year, from: newDate) >= startYear {
                                selectedDate = newDate
                            }
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
