//
//  MdU_AppApp.swift
//  MdU App
//
//  Created by Noah R on 24.02.25.
//

import SwiftUI

@main
struct MdU_AppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var nextcloudService = NextcloudService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.context)
                .environmentObject(nextcloudService)
                .onAppear {
                    // Prüfe, ob ein Benutzer angemeldet ist
                    if let user = CoreDataManager.shared.getCurrentUser(),
                       let username = user.username {
                        // Rufe die Benutzerdaten vom Server ab
                        nextcloudService.getUserData(username: username) { result in
                            switch result {
                            case .success(let nextcloudUser):
                                // Aktualisiere die lokalen Daten
                                user.firstName = nextcloudUser.firstName
                                user.lastName = nextcloudUser.lastName
                                user.email = nextcloudUser.email
                                user.schoolClass = nextcloudUser.schoolClass
                                CoreDataManager.shared.saveContext()
                            case .failure:
                                // Fehler beim Abrufen der Daten, ignorieren
                                break
                            }
                        }
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialisiere Core Data
        _ = CoreDataManager.shared
        
        return true
    }
    
    // Behandle die Rückkehr von der OAuth-Authentifizierung
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Überprüfe, ob die URL dem erwarteten Schema entspricht
        if url.scheme == "mduapp" {
            // Die URL wird automatisch von ASWebAuthenticationSession verarbeitet
            return true
        }
        
        return false
    }
}
