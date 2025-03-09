//
//  AccountView.swift
//  MdU App
//
//  Created by Mats Kahmann on 07.03.25.
//

import SwiftUI

struct AccountView: View {
    @StateObject private var oauthService = OAuthService()
    @State private var selectedTab = 0
    @State private var user: UserEntity? = nil
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingTestLogin = false
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggingIn = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)

                if let user = user {
                    VStack(spacing: 0) {
                        // Tab Picker
                        Picker("", selection: $selectedTab) {
                            Text("Profil").tag(0)
                            Text("Ausweis").tag(1)
                            Text("Einstellungen").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .padding(.top, 5)
                        .padding(.bottom, 0)
                        .background(Color.clear)

                        // Tab Content
                        TabView(selection: $selectedTab) {
                            AccountDetailsView(user: user, onLogout: logout)
                                .tag(0)
                            SchülerausweisWrapper()
                                .tag(1)
                            SettingsView()
                                .tag(2)
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .edgesIgnoringSafeArea(.bottom)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Logo oder App-Icon
                            Image(systemName: "graduationcap.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.blue)
                                .padding(.top, 40)
                            
                            Text("Willkommen bei der MdU App")
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("Bitte melde dich mit deinem Schulkonto an, um auf alle Funktionen zugreifen zu können.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            
                            // Anmeldeformular
                            VStack(spacing: 15) {
                                // Benutzername
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    TextField("Benutzername", text: $username)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .padding(.vertical, 10)
                                }
                                .padding(.horizontal)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                // Passwort
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    SecureField("Passwort", text: $password)
                                        .padding(.vertical, 10)
                                }
                                .padding(.horizontal)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                            .padding(.horizontal, 40)
                            
                            // Anmelden-Button
                            Button(action: login) {
                                if isLoggingIn {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    HStack {
                                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                                            .font(.title2)
                                        Text("Anmelden")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                            .disabled(isLoggingIn || username.isEmpty || password.isEmpty)
                            .opacity((isLoggingIn || username.isEmpty || password.isEmpty) ? 0.7 : 1)
                            
                            // Testdaten-Button
                            Button(action: { showingTestLogin = true }) {
                                HStack {
                                    Image(systemName: "hammer.fill")
                                        .font(.title2)
                                    Text("Testdaten verwenden")
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 10)
                            .disabled(isLoggingIn)
                            .opacity(isLoggingIn ? 0.7 : 1)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: checkExistingUser)
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Fehler bei der Anmeldung"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingTestLogin) {
                TestLoginView { testUser in
                    self.user = testUser
                    showingTestLogin = false
                }
            }
        }
        .onReceive(oauthService.$error) { error in
            if let error = error {
                print("DEBUG: AccountView - Received error: \(error.localizedDescription)")
                
                // Versuche, eine benutzerfreundlichere Fehlermeldung zu erstellen
                if let nsError = error as? NSError {
                    switch nsError.domain {
                    case "NextcloudService":
                        switch nsError.code {
                        case 7:
                            errorMessage = "Der Server hat eine HTML-Seite statt JSON zurückgegeben. Bitte überprüfe die Server-Konfiguration."
                        case 8:
                            errorMessage = nsError.localizedDescription
                        default:
                            errorMessage = nsError.localizedDescription
                        }
                    case NSURLErrorDomain:
                        switch nsError.code {
                        case NSURLErrorNotConnectedToInternet:
                            errorMessage = "Keine Internetverbindung. Bitte überprüfe deine Verbindung und versuche es erneut."
                        case NSURLErrorTimedOut:
                            errorMessage = "Zeitüberschreitung bei der Verbindung zum Server. Bitte versuche es später erneut."
                        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                            errorMessage = "Der Server ist nicht erreichbar. Bitte überprüfe die Server-Adresse und versuche es erneut."
                        default:
                            errorMessage = "Netzwerkfehler: \(nsError.localizedDescription)"
                        }
                    default:
                        if error.localizedDescription.contains("data couldn't be read") {
                            errorMessage = "Die Antwort vom Server konnte nicht verarbeitet werden. Bitte überprüfe, ob der Server korrekt konfiguriert ist."
                        } else {
                            errorMessage = error.localizedDescription
                        }
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
                
                showingError = true
                isLoggingIn = false
            }
        }
    }
    
    private func login() {
        print("DEBUG: AccountView - Starting login with username: \(username)")
        isLoggingIn = true
        
        // Überprüfe, ob die Eingaben gültig sind
        if username.isEmpty || password.isEmpty {
            errorMessage = "Bitte gib Benutzername und Passwort ein."
            showingError = true
            isLoggingIn = false
            return
        }
        
        oauthService.loginWithCredentials(username: username, password: password)
    }
    
    private func checkExistingUser() {
        // Prüfe, ob bereits ein Benutzer in der Datenbank existiert
        if CoreDataManager.shared.getCurrentUser() != nil {
            // Prüfe, ob das Token noch gültig ist oder aktualisiert werden muss
            oauthService.refreshTokenIfNeeded { success in
                if success {
                    self.user = CoreDataManager.shared.getCurrentUser()
                } else {
                    // Token konnte nicht aktualisiert werden, Benutzer muss sich neu anmelden
                    CoreDataManager.shared.deleteCurrentUser()
                }
            }
        }
        
        // Setze den Callback für erfolgreiche Authentifizierung
        oauthService.onAuthenticationCompleted = { user in
            self.user = user
            self.isLoggingIn = false
        }
    }
    
    private func logout() {
        oauthService.logout()
        withAnimation {
            user = nil
            username = ""
            password = ""
        }
    }
}

// MARK: - Test Login View
struct TestLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var firstName = "Max"
    @State private var lastName = "Mustermann"
    @State private var email = "max.mustermann@marienschule-bielefeld.de"
    @State private var username = "mmustermann"
    @State private var schoolClass = "Q1"
    @State private var birthDate = Date()
    @State private var password = "test123"
    var onLogin: (UserEntity) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Testbenutzer-Daten")) {
                    TextField("Vorname", text: $firstName)
                    TextField("Nachname", text: $lastName)
                    TextField("E-Mail", text: $email)
                    TextField("Benutzername", text: $username)
                    TextField("Klasse", text: $schoolClass)
                    DatePicker("Geburtsdatum", selection: $birthDate, displayedComponents: .date)
                    SecureField("Passwort", text: $password)
                }
                
                Section {
                    Button(action: createTestUser) {
                        Text("Testbenutzer erstellen")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Testdaten")
            .navigationBarItems(trailing: Button("Abbrechen") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func createTestUser() {
        // Lösche vorhandene Benutzer
        CoreDataManager.shared.deleteCurrentUser()
        
        // Speichere das Passwort in der Keychain
        KeychainManager.savePassword(password, for: username)
        
        // Erstelle einen neuen Testbenutzer
        let coreDataManager = CoreDataManager.shared
        coreDataManager.saveUser(
            firstName: firstName,
            lastName: lastName,
            email: email,
            username: username,
            birthDate: birthDate,
            schoolClass: schoolClass,
            accessToken: "test_access_token",
            refreshToken: "test_refresh_token",
            tokenExpiryDate: Date().addingTimeInterval(3600) // Token gültig für 1 Stunde
        )
        
        if let testUser = coreDataManager.getCurrentUser() {
            onLogin(testUser)
        }
    }
}

// MARK: - Account Details View
struct AccountDetailsView: View {
    let user: UserEntity
    let onLogout: () -> Void
    @StateObject private var oauthService = OAuthService()
    @State private var showingPassword = false
    @State private var password: String? = nil
    @State private var isRefreshing = false
    @State private var showRefreshSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Profilbild
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(.blue)
                    .padding(.top, 5)
                
                // Name
                Text("\(user.firstName ?? "") \(user.lastName ?? "")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding(.bottom, 5)
                
                // Benutzerinformationen
                VStack(spacing: 10) {
                    ProfileInfoRow(icon: "envelope.fill", label: "E-Mail", value: user.email ?? "")
                    ProfileInfoRow(icon: "person.text.rectangle.fill", label: "Benutzername", value: user.username ?? "")
                    
                    if let birthDate = user.birthDate {
                        ProfileInfoRow(icon: "calendar", label: "Geburtsdatum", value: formatDate(birthDate))
                    }
                    
                    if let schoolClass = user.schoolClass {
                        ProfileInfoRow(icon: "graduationcap.fill", label: "Klasse", value: schoolClass)
                    }
                    
                    // Passwort-Anzeige mit FaceID/TouchID
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text("Passwort")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if showingPassword, let password = password {
                                Text(password)
                                    .font(.body)
                                    .fontWeight(.medium)
                            } else {
                                Text("••••••••")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if showingPassword {
                                showingPassword = false
                                password = nil
                            } else {
                                showPassword()
                            }
                        }) {
                            Image(systemName: showingPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Daten aktualisieren Button
                    Button(action: refreshUserData) {
                        HStack {
                            if isRefreshing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isRefreshing ? "Wird aktualisiert..." : "Daten aktualisieren")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .disabled(isRefreshing)
                    .opacity(isRefreshing ? 0.7 : 1)
                    .padding(.top, 10)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Abmelden-Button
                Button(action: onLogout) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Abmelden")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                .padding(.top, 10)
            }
            .padding(.bottom, 50) // Zusätzlicher Abstand am unteren Rand
        }
        .padding(.bottom, 0)
        .alert(isPresented: $showRefreshSuccess) {
            Alert(
                title: Text("Daten aktualisiert"),
                message: Text("Ihre Benutzerdaten wurden erfolgreich aktualisiert."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(oauthService.$error) { error in
            if error != nil {
                isRefreshing = false
            }
        }
    }
    
    private func showPassword() {
        guard let username = user.username else { return }
        
        oauthService.getPasswordWithBiometricAuth(for: username) { retrievedPassword in
            if let retrievedPassword = retrievedPassword {
                self.password = retrievedPassword
                self.showingPassword = true
            }
        }
    }
    
    private func refreshUserData() {
        guard let username = user.username else { return }
        
        isRefreshing = true
        
        oauthService.refreshUserData(username: username) { success in
            isRefreshing = false
            
            if success {
                showRefreshSuccess = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Profile Info Row
struct ProfileInfoRow: View {
    var icon: String
    var label: String
    var value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("autoSync") private var autoSync = true
    @AppStorage("showHolidays") private var showHolidays = true
    @AppStorage("useFloatingMenuBar") private var useFloatingMenuBar = true

    var body: some View {
        Form {
            Section(header: Text("Erscheinungsbild")) {
                Toggle("Dark Mode", isOn: $isDarkMode)
                
                Toggle(isOn: $useFloatingMenuBar) {
                    Label {
                        Text("Schwebende Menüleiste")
                    } icon: {
                        Image(systemName: useFloatingMenuBar ? "dock.rectangle" : "rectangle.dock")
                            .foregroundColor(.blue)
                    }
                }
                .onChange(of: useFloatingMenuBar) { newValue in
                    // Haptisches Feedback beim Umschalten
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }

            Section(header: Text("Benachrichtigungen")) {
                Toggle("Benachrichtigungen aktivieren", isOn: $notificationsEnabled)
            }

            Section(header: Text("Synchronisation")) {
                Toggle("Automatische Synchronisation", isOn: $autoSync)
            }

            Section(header: Text("Kalender")) {
                Toggle(isOn: $showHolidays) {
                    Label {
                        Text("Feiertage anzeigen")
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }
                }
            }

            Section(header: Text("App-Info")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Einstellungen")
    }
}

// MARK: - Schülerausweis Wrapper
struct SchülerausweisWrapper: View {
    var body: some View {
        ScrollView {
            VStack {
                Schülerausweis()
                    .padding(.bottom, 50)
            }
        }
    }
}
