//
//  AccountView.swift
//  MdU App
//
//  Created by Mats Kahmann on 07.03.25.
//

import SwiftUI

struct AccountView: View {
    @State private var loggedInUser: User? = nil
    @State private var showRegister = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)

                if let user = loggedInUser {
                    AccountDetailsView(user: user) { logout() }
                } else {
                    if showRegister {
                        RegisterView(loggedInUser: $loggedInUser, showRegister: $showRegister)
                    } else {
                        LoginView(loggedInUser: $loggedInUser, showRegister: $showRegister)
                    }
                }
            }
        }
    }

    private func logout() {
        withAnimation {
            loggedInUser = nil
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @Binding var loggedInUser: User?
    @Binding var showRegister: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Willkommen zurück!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }

            CustomTextField(placeholder: "E-Mail", text: $email)
            CustomSecureField(placeholder: "Passwort", text: $password)

            Button(action: login) {
                Text("Anmelden").modifier(CustomButtonStyle(color: .blue))
            }

            Button(action: { showRegister = true }) {
                Text("Noch kein Konto? Registrieren").foregroundColor(.blue).padding(.top, 10)
            }
        }
        .padding()
    }

    private func login() {
        if let usersData = UserDefaults.standard.data(forKey: "users"),
           let users = try? JSONDecoder().decode([User].self, from: usersData),
           let user = users.first(where: { $0.email == email && $0.password == password }) {
            withAnimation {
                loggedInUser = user
            }
        } else {
            errorMessage = "Falsche E-Mail oder Passwort!"
        }
    }
}

// MARK: - Register View
struct RegisterView: View {
    @Binding var loggedInUser: User?
    @Binding var showRegister: Bool
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthDate = Date()
    @State private var schoolYear = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Neues Konto erstellen")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)

            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }

            CustomTextField(placeholder: "Vorname", text: $firstName)
            CustomTextField(placeholder: "Nachname", text: $lastName)
            CustomTextField(placeholder: "E-Mail", text: $email)
            CustomSecureField(placeholder: "Passwort", text: $password)
            CustomSecureField(placeholder: "Passwort bestätigen", text: $confirmPassword)
            CustomTextField(placeholder: "Jahrgang (z. B. 2025)", text: $schoolYear)
            
            DatePicker("Geburtsdatum", selection: $birthDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()

            Button(action: register) {
                Text("Registrieren").modifier(CustomButtonStyle(color: .blue))
            }

            Button(action: { showRegister = false }) {
                Text("Zurück zum Login").foregroundColor(.blue).padding(.top, 10)
            }
        }
        .padding()
    }

    private func register() {
        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, !schoolYear.isEmpty else {
            errorMessage = "Bitte fülle alle Felder aus!"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwörter stimmen nicht überein!"
            return
        }

        var users = (try? JSONDecoder().decode([User].self, from: UserDefaults.standard.data(forKey: "users") ?? Data())) ?? []

        guard !users.contains(where: { $0.email == email }) else {
            errorMessage = "Diese E-Mail ist bereits registriert!"
            return
        }

        let newUser = User(firstName: firstName, lastName: lastName, email: email, password: password, birthDate: birthDate, schoolYear: schoolYear)
        users.append(newUser)

        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: "users")
        }

        withAnimation {
            loggedInUser = newUser
        }
    }
}

// MARK: - Account Details View
struct AccountDetailsView: View {
    let user: User
    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Mein Profil")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.blue)

            VStack(spacing: 15) {
                ProfileCard(icon: "person.fill", label: "Name", value: "\(user.firstName) \(user.lastName)")
                ProfileCard(icon: "envelope.fill", label: "E-Mail", value: user.email)
                ProfileCard(icon: "calendar", label: "Geburtsdatum", value: formattedDate(user.birthDate))
                ProfileCard(icon: "graduationcap.fill", label: "Jahrgang", value: user.schoolYear)
            }
            .padding()

            Button(action: onLogout) {
                Text("Abmelden").modifier(CustomButtonStyle(color: .red))
            }
        }
        .padding()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - UI Components
struct ProfileCard: View {
    var icon: String
    var label: String
    var value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title)
            VStack(alignment: .leading) {
                Text(label).font(.headline).foregroundColor(.gray)
                Text(value).font(.title3).bold()
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white).shadow(radius: 5))
    }
}

struct User: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let birthDate: Date
    let schoolYear: String
}

// MARK: - Benutzerdefinierte Eingabefelder
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 2))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 1))
            .padding(.horizontal)
    }
}

// MARK: - Benutzerdefinierte Button-Stile
struct CustomButtonStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(12)
            .shadow(radius: 5)
            .padding(.horizontal)
    }
}
