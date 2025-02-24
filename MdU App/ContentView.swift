//
//  ContentView.swift
//  MdU App
//
//  Created by Noah Patrick R. and Mats K. on 24.02.25.
//

import SwiftUI

struct ContentView: View {
    @State private var showSchülerausweis = false

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
                
                FloatingMenuBar(showSchülerausweis: $showSchülerausweis)
            }
            .navigationTitle("Home")
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showSchülerausweis) {
            Schülerausweis()
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

struct FloatingMenuBar: View {
    @Binding var showSchülerausweis: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack {
                MenuButton(icon: "house.fill")
                Spacer()
                MenuButton(icon: "calendar")
                Spacer()
                MenuButton(icon: "checkmark.circle")
                Spacer()
                MenuButton(icon: "book.fill", action: {
                    showSchülerausweis = true
                })
            }
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadius(25)
            .padding(.horizontal, 30)
        }
    }
}

struct MenuButton: View {
    var icon: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            action?()
            print("\(icon) gedrückt")
        }) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundColor(.white)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}