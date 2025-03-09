import SwiftUI

// Zeile für ein Suchergebnis
struct LessonSearchResultRow: View {
    let lesson: Lesson
    let dayOffset: Int
    let dayLabel: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Farbiger Indikator und Icon
            ZStack {
                Circle()
                    .fill(lesson.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: getIconForSubject(lesson.subject))
                    .font(.system(size: 18))
                    .foregroundColor(lesson.color)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Fach und Raum
                HStack {
                    Text(lesson.subject)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !lesson.room.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(lesson.color)
                            
                            Text(lesson.room)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(lesson.color.opacity(0.1))
                        )
                    }
                }
                
                // Lehrer und Zeit
                HStack {
                    if !lesson.teacher.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundColor(lesson.color)
                            
                            Text(lesson.teacher)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(lesson.color)
                        
                        Text(lesson.timeSlot)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tag
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Text(dayLabel)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Zum Kalender")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // Gibt ein passendes Icon für das Fach zurück
    private func getIconForSubject(_ subject: String) -> String {
        let subjectLower = subject.lowercased()
        
        if subjectLower.contains("mathe") {
            return "function"
        } else if subjectLower.contains("deutsch") {
            return "text.book.closed"
        } else if subjectLower.contains("englisch") || subjectLower.contains("französisch") || subjectLower.contains("latein") || subjectLower.contains("russisch") {
            return "globe"
        } else if subjectLower.contains("physik") {
            return "atom"
        } else if subjectLower.contains("biologie") {
            return "leaf"
        } else if subjectLower.contains("chemie") {
            return "flask"
        } else if subjectLower.contains("geschichte") {
            return "clock.arrow.circlepath"
        } else if subjectLower.contains("kunst") {
            return "paintbrush"
        } else if subjectLower.contains("sport") {
            return "figure.run"
        } else if subjectLower.contains("informatik") {
            return "desktopcomputer"
        } else if subjectLower.contains("ethik") || subjectLower.contains("religion") {
            return "heart"
        } else if subjectLower.contains("erdkunde") || subjectLower.contains("geo") {
            return "map"
        } else {
            return "book"
        }
    }
}
