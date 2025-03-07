//
//  ContentView.swift
//  MdU App
//
//  Created by Noah Patrick R. and Mats K. on 24.02.25.
//

import SwiftUI
import WebKit
		
enum Page {
    case home, calendar, tasks, studentID, webView, articles
}

struct ContentView: View {
    @State private var currentPage: Page = .home
    
    var body: some View {
        ZStack {
            Group {
                switch currentPage {
                case .home:
                    HomeView(currentPage: $currentPage)
                case .calendar:
                    TimetableView()
                case .tasks:
                    Text("Tasks")
                case .studentID:
                    Schülerausweis()
                case .webView:
                    WebViewContainer(currentPage: $currentPage)
                case .articles:
                    ArticlesView(currentPage: $currentPage)
                }
            }
            
            if currentPage != .webView && currentPage != .articles {
                VStack {
                    Spacer()
                    CustomFloatingMenuBar(currentPage: $currentPage)
                        .padding(.bottom, 0)
                }
            }
        }
    }
}

struct HomeView: View {
    @Binding var currentPage: Page
    
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func findNextLesson() -> Lesson? {
        let now = Date()
        for day in lessonsByDay {
            for lesson in day {
                if lesson.startTime > now {
                    return lesson
                }
            }
        }
        return nil
    }
}

struct NextLessonWidget: View {
    let nextLesson: Lesson?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Group {
            if let lesson = nextLesson {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
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
                        
                        Text("Nächste Stunde")
                            .font(.system(size: 18, weight: .semibold))
                        
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
                        
                        // Progress
                        VStack(spacing: 6) {
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
                        
                        Text("Genieße den Rest des Tages!")
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
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: { currentPage = .home }) {
                Image(systemName: "house.fill")
                    .foregroundColor(currentPage == .home ? .blue : .white)
            }
            Spacer()
            Button(action: { currentPage = .calendar }) {
                Image(systemName: "calendar")
                    .foregroundColor(currentPage == .calendar ? .blue : .white)
            }
            Spacer()
            Button(action: { currentPage = .tasks }) {
                Image(systemName: "list.bullet")
                    .foregroundColor(currentPage == .tasks ? .blue : .white)
            }
            Spacer()
            Button(action: { currentPage = .studentID }) {
                Image(systemName: "person.crop.rectangle")
                    .foregroundColor(currentPage == .studentID ? .blue : .white)
                
            }
            .padding()
            .background(Color(.darkGray))
            .clipShape(Capsule())
            .frame(width: 250, height: 50)
            .shadow(radius: 10)
        }
    }
    
}
