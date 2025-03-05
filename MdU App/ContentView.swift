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
                    Text("Kalender View")
                case .tasks:
                    Text("Aufgaben View")
                case .studentID:
                    Text("Schülerausweis View")
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Marienschule Bielefeld")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
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
                            .cornerRadius(30)
                            
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
                        .cornerRadius(30)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarHidden(true)
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
