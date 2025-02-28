//
//  ContentView.swift
//  MdU App
//
//  Created by Noah Patrick R. and Mats K. on 24.02.25.
//

import SwiftUI

enum Page {
    case home, calendar, tasks, studentID
}

struct ContentView: View {
    @State private var currentPage: Page = .home
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                switch currentPage {
                case .home:
                    HomeView()
                case .calendar:
                    TimetableView()
                case .tasks:
                    Text("Tasks View") // Placeholder for tasks view
                case .studentID:
                    Schülerausweis()
                }
            }
            
            // Floating menu bar
            VStack {
                Spacer()
                CustomFloatingMenuBar(currentPage: $currentPage)
                    .padding(.bottom, 0) // Menüleiste weiter unten
            }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Marienschule Bielefeld")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    ForEach(0..<5, id: \ .self) { index in
                        InfoWidget(title: "Elternbrief", content: "Neuster Elternbrief hier...")
                        InfoWidget(title: "Nächste Stunde", content: "Mathe - H216 - Malek")
                        InfoWidget(title: "MDU Timers", content: "Hausaufgaben nicht vergessen!")
                    }
                }
                .padding(.bottom, 70)
            }
            .navigationTitle("Home")
            .navigationBarHidden(true)
        }
    }
}

struct InfoWidget: View {
    var title: String
    var content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .foregroundColor(.black)
            Text(content)
                .foregroundColor(.gray)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16) // Mehr abgerundet
        .shadow(radius: 5)
        .padding(.horizontal)
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
        .background(Color(.darkGray)) // Dunkelgraue Farbe
        .clipShape(Capsule()) // Schmaler
        .frame(width: 250, height: 50) // Schmalere Leiste
        .shadow(radius: 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
