//
//  ContentView.swift
//  MdU App
//
//  Created by Noah Patrick R. and Mats K. on 24.02.25.
//

import SwiftUI

struct ContentView: View {
    @State private var currentPage: FloatingMenuBar.Page = .home
    
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
            FloatingMenuBar(currentPage: $currentPage)
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
                    
                    ForEach(0..<5, id: \.self) { _ in
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
                .font(.title)
                .foregroundColor(.black)
            Text(content)
                .foregroundColor(.gray)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
        .padding(.horizontal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
