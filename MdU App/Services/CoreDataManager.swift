import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MdUApp")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Fehler beim Laden der Core Data Stores: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Fehler beim Speichern des Kontexts: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - User Management
    
    func saveUser(id: UUID = UUID(), firstName: String, lastName: String, email: String, username: String, birthDate: Date? = nil, schoolClass: String?, accessToken: String, refreshToken: String, tokenExpiryDate: Date) {
        let user = UserEntity(context: context)
        user.id = id
        user.firstName = firstName
        user.lastName = lastName
        user.email = email
        user.username = username
        user.birthDate = birthDate
        user.schoolClass = schoolClass
        user.accessToken = accessToken
        user.refreshToken = refreshToken
        user.tokenExpiryDate = tokenExpiryDate
        
        saveContext()
    }
    
    func getCurrentUser() -> UserEntity? {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        do {
            let users = try context.fetch(fetchRequest)
            return users.first
        } catch {
            print("Fehler beim Abrufen des Benutzers: \(error)")
            return nil
        }
    }
    
    func updateUserTokens(accessToken: String, refreshToken: String, expiryDate: Date) {
        if let user = getCurrentUser() {
            user.accessToken = accessToken
            user.refreshToken = refreshToken
            user.tokenExpiryDate = expiryDate
            saveContext()
        }
    }
    
    func deleteCurrentUser() {
        if let user = getCurrentUser() {
            context.delete(user)
            saveContext()
        }
    }
    
    func isTokenValid() -> Bool {
        guard let user = getCurrentUser(), 
              let expiryDate = user.tokenExpiryDate,
              let accessToken = user.accessToken, !accessToken.isEmpty else {
            return false
        }
        
        // Token ist gültig, wenn das Ablaufdatum in der Zukunft liegt
        return expiryDate > Date()
    }
} 