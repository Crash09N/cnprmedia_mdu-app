//
//  ContentView.swift
//  MdU App
//
//  Created by Noah Patrick R. and Mats K. on 24.02.25.
//

import SwiftUI
import WebKit

enum Page {
    case home, calendar, tasks, studentID, webView
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
                }
            }
            
            if currentPage != .webView {
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
            ScrollView {
                VStack(spacing: 20) {
                    Text("Marienschule Bielefeld")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    // WebView-Button
                    Button(action: { currentPage = .webView }) {
                        ZStack {
                            AsyncImage(url: URL(string: "https://marienschule-bielefeld.de/wp-content/uploads/marienschule-header.jpg")) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: UIScreen.main.bounds.width - 40, height: 150)
                                    .clipped()
                            } placeholder: {
                                Color.gray
                            }
                            .cornerRadius(20) // Gleiche Eckenabrundung wie das Widget
                            
                            VStack {
                                Text("Homepage")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .shadow(radius: 5)
                                    .padding(.top, 10)
                                Spacer()
                            }
                            .frame(width: UIScreen.main.bounds.width - 40, height: 150)
                        }
                        .frame(width: UIScreen.main.bounds.width - 40, height: 150)
                        .cornerRadius(20) // Gleiche Eckenabrundung wie das Widget
                        .shadow(radius: 10) // Gleicher Schatten wie das Widget
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // NextLessonWidget
                    NextLessonWidget(nextLesson: findNextLesson())
                        .padding(.horizontal, 20) // Gleicher horizontaler Abstand wie das WebView-Widget
                }
            }
            .navigationTitle("Home")
            .navigationBarHidden(true)
        }
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
    
    var body: some View {
        if let lesson = nextLesson {
            VStack(alignment: .leading, spacing: 10) {
                Text("Nächste Stunde:")
                    .font(.headline)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(lesson.subject)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !lesson.room.isEmpty {
                        Text("Raum: \(lesson.room)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    if !lesson.teacher.isEmpty {
                        Text("Lehrer: \(lesson.teacher)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Zeit: \(lesson.timeSlot)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
                
                ProgressView(value: progress(for: lesson))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding(.bottom, 10)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width - 40) // Gleiche Breite wie das WebView-Widget
            .background(Color(.systemBackground))
            .cornerRadius(20) // Gleiche Eckenabrundung wie das WebView-Widget
            .shadow(radius: 10) // Gleicher Schatten wie das WebView-Widget
        } else {
            Text("Keine weiteren Stunden heute")
                .padding()
                .frame(width: UIScreen.main.bounds.width - 40) // Gleiche Breite wie das WebView-Widget
                .background(Color(.systemBackground))
                .cornerRadius(20) // Gleiche Eckenabrundung wie das WebView-Widget
                .shadow(radius: 10) // Gleicher Schatten wie das WebView-Widget
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
            Spacer()
        }
        .padding()
        .background(Color(.darkGray))
        .clipShape(Capsule())
        .frame(width: 250, height: 50)
        .shadow(radius: 10)
    }
}


