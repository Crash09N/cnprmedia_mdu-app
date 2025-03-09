import SwiftUI

struct NextLessonWidget: View {
    let nextLesson: (Lesson, Int)?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if let (lesson, dayOffset) = nextLesson {
                VStack(alignment: .leading, spacing: 0) {
                    // Header mit Tagesanzeige
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [lesson.color, lesson.color.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .frame(width: 48, height: 48)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dayLabel(for: dayOffset))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("Nächste Stunde")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        Text(lesson.timeSlot)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [lesson.color, lesson.color.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        // Subject and room
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lesson.subject)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                if !lesson.room.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(lesson.color)
                                        
                                        Text(lesson.room)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if !lesson.teacher.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(lesson.color)
                                    
                                    Text(lesson.teacher)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        // Progress oder Countdown
                        VStack(spacing: 6) {
                            if dayOffset == 0 {
                                // Für heutige Termine: Fortschrittsbalken
                                ProgressView(value: progress(for: lesson))
                                    .progressViewStyle(LinearProgressViewStyle(tint: lesson.color))
                                
                                HStack {
                                    Text("Beginnt in \(timeUntilStart(for: lesson))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(progress(for: lesson) * 100))%")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(lesson.color)
                                }
                            } else {
                                // Für zukünftige Termine: Countdown in Tagen
                                HStack {
                                    Text(countdownText(for: dayOffset))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
            } else {
                // Anzeige, wenn keine Stunden vorhanden sind
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keine Stunden verfügbar")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Bitte wähle einen Jahrgang in deinem Profil")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
            }
        }
    }
    
    private func dayLabel(for dayOffset: Int) -> String {
        switch dayOffset {
        case 0:
            return "Heute"
        case 1:
            return "Morgen"
        default:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            if let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                let weekday = calendar.component(.weekday, from: futureDate)
                switch weekday {
                case 1: return "Sonntag"
                case 2: return "Montag"
                case 3: return "Dienstag"
                case 4: return "Mittwoch"
                case 5: return "Donnerstag"
                case 6: return "Freitag"
                case 7: return "Samstag"
                default: return ""
                }
            }
            return ""
        }
    }
    
    private func countdownText(for dayOffset: Int) -> String {
        if let (lesson, _) = nextLesson {
            switch dayOffset {
            case 1:
                return "Morgen um \(lesson.timeSlot.components(separatedBy: " - ")[0]) Uhr"
            default:
                return "In \(dayOffset) Tagen"
            }
        }
        return ""
    }
    
    private func progress(for lesson: Lesson) -> Float {
        let now = Date()
        if now < lesson.startTime {
            return 0.0
        } else if now > lesson.endTime {
            return 1.0
        } else {
            let totalDuration = lesson.endTime.timeIntervalSince(lesson.startTime)
            let elapsedDuration = now.timeIntervalSince(lesson.startTime)
            return Float(elapsedDuration / totalDuration)
        }
    }
    
    private func timeUntilStart(for lesson: Lesson) -> String {
        let now = Date()
        if now >= lesson.startTime {
            return "Läuft bereits"
        }
        
        let timeInterval = lesson.startTime.timeIntervalSince(now)
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours) Std. \(minutes) Min."
        } else {
            return "\(minutes) Minuten"
        }
    }
}
