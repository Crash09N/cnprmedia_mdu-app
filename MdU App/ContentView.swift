//
//  ContentView.swift
//  MdU App
//
//  Created by Noah Patrick R. and Mats K. on 24.02.25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Display the selected view based on the selectedTab state
            if selectedTab == 0 {
                HomeView()
            } else {
                Schülerausweis()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingTabBar(selectedTab: $selectedTab)
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Marienschule Bielefeld")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        ForEach(0..<5, id: \..self) { _ in
                            InfoWidget(title: "Elternbrief", content: "Neuster Elternbrief hier...")
                            InfoWidget(title: "Nächste Stunde", content: "Mathe - H216 - Malek")
                            InfoWidget(title: "MDU Timers", content: "Hausaufgaben nicht vergessen!")
                        }
                    }
                    .padding(.bottom, 70)
                }
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

struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack {
            TabBarButton(icon: "house.fill", index: 0, selectedTab: $selectedTab)
            Spacer()
            TabBarButton(icon: "book.fill", index: 1, selectedTab: $selectedTab)
        }
        .padding()
        .background(Color.gray.opacity(0.9))
        .cornerRadius(25)
        .frame(maxWidth: 300)
        .shadow(radius: 5)
    }
}

struct TabBarButton: View {
    var icon: String
    var index: Int
    @Binding var selectedTab: Int

    var body: some View {
        Button(action: {
            selectedTab = index
        }) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundColor(selectedTab == index ? .blue : .white)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}