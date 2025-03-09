//
//  ContentView.swift
//  MdU App
//
//  Created by Noah Patrick R. and Mats K. on 24.02.25.
//

import SwiftUI
import WebKit
		
enum Page {
    case home, calendar, tasks, files, webView, articles, account
}

struct ContentView: View {
    @State private var currentPage: Page = .home
    @State private var selectedDate: Date = Date()
    @AppStorage("useFloatingMenuBar") private var useFloatingMenuBar = true
    
    var body: some View {
        ZStack {
            Group {
                switch currentPage {
                case .home:
                    HomeView(currentPage: $currentPage, selectedDate: $selectedDate)
                case .calendar:
                    TimetableView(initialDate: selectedDate)
                case .tasks:
                    Text("Tasks")
                case .files:
                    FilesView()
                case .webView:
                    WebViewContainer(currentPage: $currentPage)
                case .articles:
                    ArticlesView(currentPage: $currentPage)
                case .account:
                    AccountView()
                }
            }
            
            if currentPage != .webView && currentPage != .articles {
                VStack {
                    Spacer()
                    CustomFloatingMenuBar(currentPage: $currentPage, isFloating: useFloatingMenuBar)
                        .padding(.bottom, useFloatingMenuBar ? 0 : -8)
                }
            }
        }
    }
}

struct HomeView: View {
    @Binding var currentPage: Page
    @Binding var selectedDate: Date
    
    private let lessonsByDay: [[Lesson]] = [
        // Montag
        [
            Lesson(subject: "Mathematik", room: "R1.101", teacher: "Dr. Meier", timeSlot: "8:00 - 9:30", color: .blue, startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!),
            Lesson(subject: "Deutsch", room: "R1.201", teacher: "Frau Schmidt", timeSlot: "9:45 - 11:15", color: .red, startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 45))!, endTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 15))!),
            Lesson(subject: "Englisch", room: "R2.101", teacher: "Mr. Brown", timeSlot: "11:35 - 13:05", color: .purple, startTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 35))!, endTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 5))!),
            Lesson(subject: "Physik", room: "R3.102", teacher: "Herr Weber", timeSlot: "13:50 - 15:20", color: .yellow, startTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 50))!, endTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 20))!),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray, startTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 30))!, endTime: Calendar.current.date(from: DateComponents(hour: 17, minute: 0))!)
        ],
        // Dienstag
        [
            Lesson(subject: "Biologie", room: "R2.301", teacher: "Frau Fischer", timeSlot: "8:00 - 9:30", color: .green, startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!),
            Lesson(subject: "Chemie", room: "R3.205", teacher: "Dr. Hoffmann", timeSlot: "9:45 - 11:15", color: .pink, startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 45))!, endTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 15))!),
            Lesson(subject: "Geschichte", room: "R1.112", teacher: "Herr Lehmann", timeSlot: "11:35 - 13:05", color: .cyan, startTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 35))!, endTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 5))!),
            Lesson(subject: "Kunst", room: "R4.104", teacher: "Frau Wagner", timeSlot: "13:50 - 15:20", color: .orange, startTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 50))!, endTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 20))!),
            Lesson(subject: "Freistunde", room: "", teacher: "", timeSlot: "15:30 - 17:00", color: .gray, startTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 30))!, endTime: Calendar.current.date(from: DateComponents(hour: 17, minute: 0))!)
        ],
        // Mittwoch
        [
            Lesson(subject: "Sport", room: "Sporthalle", teacher: "Herr Müller", timeSlot: "8:00 - 9:30", color: .green, startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!),
            Lesson(subject: "Informatik", room: "R2.205", teacher: "Herr Klein", timeSlot: "9:45 - 11:15", color: .blue, startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 45))!, endTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 15))!),
            Lesson(subject: "Ethik", room: "R1.112", teacher: "Frau Bauer", timeSlot: "11:35 - 13:05", color: .purple, startTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 35))!, endTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 5))!)
        ],
        // Donnerstag
        [
            Lesson(subject: "Deutsch", room: "R1.201", teacher: "Frau Schmidt", timeSlot: "8:00 - 9:30", color: .red, startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!),
            Lesson(subject: "Mathematik", room: "R1.101", teacher: "Dr. Meier", timeSlot: "9:45 - 11:15", color: .blue, startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 45))!, endTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 15))!),
            Lesson(subject: "Kunst", room: "R4.104", teacher: "Frau Wagner", timeSlot: "11:35 - 13:05", color: .orange, startTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 35))!, endTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 5))!),
            Lesson(subject: "Englisch", room: "R2.101", teacher: "Mr. Brown", timeSlot: "13:50 - 15:20", color: .purple, startTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 50))!, endTime: Calendar.current.date(from: DateComponents(hour: 15, minute: 20))!)
        ],
        // Freitag
        [
            Lesson(subject: "Geschichte", room: "R1.112", teacher: "Herr Lehmann", timeSlot: "8:00 - 9:30", color: .cyan, startTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!, endTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 30))!),
            Lesson(subject: "Physik", room: "R3.102", teacher: "Herr Weber", timeSlot: "9:45 - 11:15", color: .yellow, startTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 45))!, endTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 15))!),
            Lesson(subject: "Biologie", room: "R2.301", teacher: "Frau Fischer", timeSlot: "11:35 - 13:05", color: .green, startTime: Calendar.current.date(from: DateComponents(hour: 11, minute: 35))!, endTime: Calendar.current.date(from: DateComponents(hour: 13, minute: 5))!)
        ]
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // School title with tap gesture to show articles
                        Text("Marienschule Bielefeld")
                            .font(.system(size: 32, weight: .bold))
                            .padding(.top, 20)
                            .onTapGesture {
                                currentPage = .articles
                            }
                        
                        // WebView-Button (Homepage)
                        GeometryReader { geometry in
                            Button(action: { currentPage = .webView }) {
                                ZStack(alignment: .bottom) {
                                    AsyncImage(url: URL(string: "https://marienschule-bielefeld.de/wp-content/uploads/marienschule-header.jpg")) { image in
                                        image.resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width, height: 180)
                                            .clipped()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: geometry.size.width, height: 180)
                                            .overlay(
                                                ProgressView()
                                                    .scaleEffect(1.5)
                                            )
                                    }
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                                            startPoint: .bottom,
                                            endPoint: .center
                                        )
                                    )
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Homepage")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text("marienschule-bielefeld.de")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        .padding(.leading, 16)
                                        .padding(.bottom, 16)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.trailing, 16)
                                            .padding(.bottom, 16)
                                    }
                                }
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                            }
                        }
                        .frame(height: 180)
                        
                        // News button
                        Button(action: { currentPage = .articles }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                                    
                                    Image(systemName: "newspaper.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Neuigkeiten")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Aktuelle Nachrichten und Ankündigungen")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .padding(.trailing, 8)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            )
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        
                        // NextLessonWidget
                        NextLessonWidget(nextLesson: findNextLesson())
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .onTapGesture {
                                if let (lesson, dayOffset) = findNextLesson() {
                                    // Berechne das Datum des Termins
                                    let calendar = Calendar.current
                                    let today = calendar.startOfDay(for: Date())
                                    if let lessonDate = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                                        // Setze das ausgewählte Datum und navigiere zur Kalenderansicht
                                        selectedDate = lessonDate
                                        currentPage = .calendar
                                    }
                                }
                            }
                        
                        // Kontakt-Widget
                        SchoolContactWidget()
                            .frame(minWidth: 0, maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func findNextLesson() -> (Lesson, Int)? {
        let calendar = Calendar.current
        let now = Date()
        let currentWeekday = calendar.component(.weekday, from: now)
        
        // Wochentag-Index (0 = Montag, 1 = Dienstag, usw.)
        // Calendar.current.weekday: 1 = Sonntag, 2 = Montag, ..., 7 = Samstag
        let currentDayIndex = currentWeekday == 1 ? 6 : currentWeekday - 2
        
        // Prüfe zuerst den aktuellen Tag
        if currentDayIndex < lessonsByDay.count {
            for lesson in lessonsByDay[currentDayIndex] {
                if lesson.startTime > now {
                    // Nächste Stunde am aktuellen Tag gefunden
                    return (lesson, 0)
                }
            }
        }
        
        // Prüfe die nächsten Tage
        for dayOffset in 1...7 {
            let nextDayIndex = (currentDayIndex + dayOffset) % 7
            
            // Überspringe Wochenenden (Samstag und Sonntag)
            if nextDayIndex >= 5 {
                continue
            }
            
            if nextDayIndex < lessonsByDay.count && !lessonsByDay[nextDayIndex].isEmpty {
                // Erste Stunde des nächsten Tages mit Unterricht
                return (lessonsByDay[nextDayIndex][0], dayOffset)
            }
        }
        
        // Keine nächste Stunde gefunden
        return nil
    }
}

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
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keine weiteren Stunden")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Genieße den Rest der Woche!")
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

struct WebViewContainer: View {
    @Binding var currentPage: Page
    @State private var webView = WKWebView()
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { currentPage = .home }) {
                    Image(systemName: "arrow.left")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .padding()
            }
            
            ZStack {
                WebView(webView: webView, url: URL(string: "https://marienschule-bielefeld.de")!, isLoading: $isLoading)
                    .edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(2)
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    var webView: WKWebView
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

struct CustomFloatingMenuBar: View {
    @Binding var currentPage: Page
    @Environment(\.colorScheme) var colorScheme
    var isFloating: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                ForEach([
                    (page: Page.home, icon: "house.fill", label: "Home"),
                    (page: Page.calendar, icon: "calendar", label: "Kalendar"),
                    (page: Page.tasks, icon: "list.bullet", label: "Aufgaben"),
                    (page: Page.files, icon: "folder.fill", label: "Dateien"),
                    (page: Page.account, icon: "person.crop.circle", label: "Account")
                ], id: \.page) { item in
                    MenuBarButton(
                        icon: item.icon,
                        label: item.label,
                        isSelected: currentPage == item.page,
                        action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { currentPage = item.page } }
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                ZStack {
                    if colorScheme == .dark {
                        Color.black.opacity(0.95)
                    } else {
                        Color(UIColor.systemGray6).opacity(0.95)
                    }
                }
                .background(
                    Material.ultraThickMaterial
                )
                .clipShape(RoundedRectangle(cornerRadius: isFloating ? 24 : 0))
                .shadow(color: isFloating ? Color.black.opacity(0.25) : Color.clear, radius: isFloating ? 15 : 0, x: 0, y: isFloating ? 8 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isFloating ? 24 : 0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.white.opacity(0.2) : Color.white.opacity(0.5),
                                colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFloating ? 1 : 0
                    )
            )
            .padding(.horizontal, isFloating ? 20 : 0)
            .padding(.bottom, isFloating ? 12 : 0)
        }
        .edgesIgnoringSafeArea(isFloating ? [] : [.bottom])
    }
}

struct MenuBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 3)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                        .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.8) : .gray))
                        .frame(width: 40, height: 40)
                }
                
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .blue : (colorScheme == .dark ? .white.opacity(0.8) : .gray))
            }
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
    }
}

// Kontakt-Widget für die Marienschule
struct SchoolContactWidget: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                Text("Kontakt")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
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
                // Schulname
                Text("MARIENSCHULE")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                // Adresse
                ContactInfoRow(icon: "mappin.circle.fill", title: "Adresse", content: "Sieboldstraße 4a\n33611 Bielefeld")
                
                // Telefon/Fax
                ContactInfoRow(icon: "phone.fill", title: "Telefon/Fax", content: "0521 871851\n0521 8016135")
                
                // E-Mail
                ContactInfoRow(icon: "envelope.fill", title: "E-Mail", content: "kontakt@marienschule-bielefeld.de", isLink: true, linkType: .email)
                
                // Internet
                ContactInfoRow(icon: "globe", title: "Internet", content: "marienschule-bielefeld.de", isLink: true, linkType: .website)
                    .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// Hilfsstruct für Kontaktinformationen
struct ContactInfoRow: View {
    let icon: String
    let title: String
    let content: String
    var isLink: Bool = false
    var linkType: LinkType = .none
    
    enum LinkType {
        case none, email, website, phone
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            if isLink {
                Button(action: {
                    openLink()
                }) {
                    Text(content)
                        .font(.system(size: 15))
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func openLink() {
        var urlString = ""
        
        switch linkType {
        case .email:
            urlString = "mailto:\(content)"
        case .website:
            urlString = "https://\(content)"
        case .phone:
            urlString = "tel:\(content.replacingOccurrences(of: " ", with: ""))"
        default:
            return
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
