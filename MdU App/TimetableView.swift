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

    private let calendar = Calendar.current
    private let daysToShow = 7

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

    var body: some View {
        NavigationView {
            VStack {
                // 🔹 Obere Leiste mit Datum & Buttons
                HStack {
                    // 📅 DatePicker Button (klein & Grau)
                    Button(action: { showDatePicker = true }) {
                        Text(formattedDate(selectedDate, format: "MMMM yyyy"))
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    // 🎯 Heute-Button (gleiches Design)
                    Button(action: { selectedDate = today }) {
                        Text("Heute")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)

                // 🔹 Fixierte Datumsleiste (nur Wischen für Wochenwechsel)
                VStack {
                    HStack(spacing: 10) {
                        ForEach(daysInWeek(for: selectedDate), id: \.self) { date in
                            VStack {
                                Text(formattedDate(date, format: "E"))
                                    .font(.caption2)
                                    .foregroundColor(.gray)

                                // 📌 Datum als Button (mit Vibration)
                                Button(action: {
                                    selectedDate = date
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    Text(formattedDate(date, format: "d"))
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .frame(width: 35, height: 35)
                                        .background(date == selectedDate ? Color.red : Color.clear)
                                        .clipShape(Circle())
                                        .foregroundColor(date == selectedDate ? .white : .black)
                                        .shadow(radius: 3)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 60)
                .gesture(DragGesture()
                    .onEnded { value in
                        withAnimation(.easeInOut) {
                            if value.translation.width < -50 {
                                selectedDate = calendar.date(byAdding: .day, value: 7, to: selectedDate) ?? selectedDate
                            } else if value.translation.width > 50 {
                                selectedDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
                            }
                        }
                    }
                )

                // 🔹 Trennlinie für Wischgesten-Bereich
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3))
                    .padding(.horizontal, 10)

                // 🔹 Terminliste für den gewählten Tag
                ScrollView {
                    VStack(spacing: 10) {
                        let weekdayIndex = calendar.component(.weekday, from: selectedDate) - 2
                        let correctedIndex = weekdayIndex < 0 ? 6 : weekdayIndex

                        if correctedIndex >= 5 {
                            Text("Heute kein Unterricht, genieße deinen Tag!")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(lessonsForDay(), id: \.id) { lesson in
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
                                            Text("📍 \(lesson.room)")
                                                .font(.caption)
                                                .foregroundColor(.gray)

                                            Text("👩‍🏫 \(lesson.teacher)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationBarTitle("Stundenplan", displayMode: .inline)
            .sheet(isPresented: $showDatePicker) {
                DatePickerView(selectedDate: $selectedDate, showDatePicker: $showDatePicker)
            }
        }
    }

    // ✅ Funktion für die Termine (Einheitliche für Mo-Fr)
    private func lessonsForDay() -> [Lesson] {
        let exampleLessons = [
            Lesson(subject: "Mathematik", room: "R1.101", teacher: "Dr. Meier", timeSlot: "08:00 - 09:30", color: Color.red, startTime: Date(), endTime: Date()),
            Lesson(subject: "Englisch", room: "R2.102", teacher: "Frau Schmidt", timeSlot: "10:00 - 11:30", color: Color.blue, startTime: Date(), endTime: Date())
        ]
        return exampleLessons
    }
}

// 🔹 DatePickerView mit Beschriftung
struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var showDatePicker: Bool

    var body: some View {
        VStack {
            HStack {
                Button("Abbrechen") {
                    showDatePicker = false
                }
                .padding()
                .foregroundColor(.red)

                Spacer()

                Button("Fertig") {
                    showDatePicker = false
                }
                .padding()
                .foregroundColor(.blue)
            }

            Text("Wähle ein Datum aus") // 🔹 Neue Überschrift
                .font(.headline)
                .padding(.top, 10)

            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

// 🔹 Lesson Model
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
