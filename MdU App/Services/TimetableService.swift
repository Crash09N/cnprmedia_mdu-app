import Foundation
import SwiftUI

struct TimetableService {
    // Struktur für die JSON-Daten
    struct LessonData: Codable {
        let Fach: String
        let Raum: String
        let Lehrer: String
        let Zeit: String
    }
    
    // Lädt den Stundenplan für einen bestimmten Jahrgang, Wochentag und Wochentyp (rot/grün)
    static func loadTimetable(for schoolClass: String, weekday: String, isGreenWeek: Bool) -> [LessonData]? {
        let weekType = isGreenWeek ? "Grüne" : "Rote"
        
        print("TimetableService.loadTimetable() für Klasse \(schoolClass), Wochentag \(weekday), \(weekType) Woche")
        
        // Für 10b: Direkter Zugriff auf die Dateien mit vollständigem Pfad
        if schoolClass == "10b" {
            let fileManager = FileManager.default
            
            // Verwende den Bundle-Pfad für die App
            let bundlePath = Bundle.main.bundlePath
            let fullPath = "\(bundlePath)/10b"
            
            print("Suche in Verzeichnis: \(fullPath)")
            
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                do {
                    let files = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: fullPath), includingPropertiesForKeys: nil)
                    print("Gefundene Dateien im 10b-Ordner: \(files.map { $0.lastPathComponent })")
                    
                    // Suche nach Dateien, die mit dem Wochentag und Wochentyp beginnen
                    for file in files {
                        let filename = file.lastPathComponent
                        print("Prüfe Datei: \(filename)")
                        if filename.contains(weekday) && filename.contains(weekType) && filename.contains("10b") {
                            print("Gefunden im 10b-Ordner: \(file.path)")
                            
                            do {
                                let data = try Data(contentsOf: file)
                                let decoder = JSONDecoder()
                                let lessons = try decoder.decode([LessonData].self, from: data)
                                print("Erfolgreich \(lessons.count) Termine geladen")
                                return lessons
                            } catch {
                                print("Fehler beim Laden der Datei \(file.path): \(error)")
                            }
                        }
                    }
                    
                    print("Keine passende Datei für \(weekday), \(weekType) gefunden")
                } catch {
                    print("Fehler beim Durchsuchen des 10b-Verzeichnisses: \(error)")
                }
            } else {
                print("10b-Verzeichnis nicht gefunden oder ist kein Verzeichnis: \(fullPath)")
                
                // Versuche es mit dem Projektpfad als Fallback
                let projectPath = "/Users/matskahmann/Documents/GitHub/cnprmedia_mdu-app/MdU App/10b"
                print("Versuche Projektpfad: \(projectPath)")
                
                if fileManager.fileExists(atPath: projectPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                    do {
                        let files = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: projectPath), includingPropertiesForKeys: nil)
                        print("Gefundene Dateien im Projektpfad 10b-Ordner: \(files.map { $0.lastPathComponent })")
                        
                        // Suche nach Dateien, die mit dem Wochentag und Wochentyp beginnen
                        for file in files {
                            let filename = file.lastPathComponent
                            print("Prüfe Datei: \(filename)")
                            if filename.contains(weekday) && filename.contains(weekType) && filename.contains("10b") {
                                print("Gefunden im Projektpfad 10b-Ordner: \(file.path)")
                                
                                do {
                                    let data = try Data(contentsOf: file)
                                    let decoder = JSONDecoder()
                                    let lessons = try decoder.decode([LessonData].self, from: data)
                                    print("Erfolgreich \(lessons.count) Termine geladen")
                                    return lessons
                                } catch {
                                    print("Fehler beim Laden der Datei \(file.path): \(error)")
                                }
                            }
                        }
                        
                        print("Keine passende Datei für \(weekday), \(weekType) im Projektpfad gefunden")
                    } catch {
                        print("Fehler beim Durchsuchen des Projektpfad 10b-Verzeichnisses: \(error)")
                    }
                } else {
                    print("Projektpfad 10b-Verzeichnis nicht gefunden oder ist kein Verzeichnis: \(projectPath)")
                }
            }
            
            return nil
        }
        
        // Für andere Klassen: Verwende den bisherigen Ansatz
        let fileName = "\(weekday),\(weekType),\(schoolClass)"
        print("Versuche Stundenplan zu laden: \(fileName)")
        
        // Suche nach der Datei (auch mit möglichem Leerzeichen und Zahl am Ende)
        guard let url = findJsonFile(baseName: fileName) else {
            print("Keine Datei gefunden für: \(fileName)")
            return nil
        }
        
        do {
            print("Lade Daten aus: \(url.path)")
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let lessons = try decoder.decode([LessonData].self, from: data)
            print("Erfolgreich \(lessons.count) Termine geladen")
            return lessons
        } catch {
            print("Fehler beim Laden des Stundenplans: \(error)")
            return nil
        }
    }
    
    // Hilfsfunktion zum Finden der JSON-Datei (auch mit Varianten wie "Dateiname 2.json")
    private static func findJsonFile(baseName: String) -> URL? {
        print("Suche nach JSON-Datei: \(baseName)")
        
        // Extrahiere den Klassennamen aus dem Dateinamen
        let className = baseName.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespaces) ?? ""
        
        // Direkter Pfad zur JSON-Datei im 10b-Ordner
        if className == "10b" {
            let fileManager = FileManager.default
            
            // Versuche verschiedene mögliche Pfade zum 10b-Ordner
            let possiblePaths = [
                Bundle.main.bundleURL.appendingPathComponent("10b").path,
                Bundle.main.bundleURL.appendingPathComponent("MdU App").appendingPathComponent("10b").path,
                "/Users/matskahmann/Documents/GitHub/cnprmedia_mdu-app/MdU App/10b"
            ]
            
            for path in possiblePaths {
                print("Versuche Pfad: \(path)")
                
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue {
                    print("Verzeichnis gefunden: \(path)")
                    
                    do {
                        let files = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil)
                        print("Gefundene Dateien: \(files.map { $0.lastPathComponent })")
                        
                        // Extrahiere die Teile des Basisnamens für flexiblere Suche
                        let baseNameParts = baseName.components(separatedBy: ",")
                        let weekday = baseNameParts.first?.trimmingCharacters(in: .whitespaces) ?? ""
                        let weekType = baseNameParts.count > 1 ? baseNameParts[1].trimmingCharacters(in: .whitespaces) : ""
                        
                        print("Suche nach Dateien mit: Wochentag=\(weekday), Wochentyp=\(weekType), Klasse=\(className)")
                        
                        // Suche nach Dateien, die die Teile des Basisnamens enthalten
                        for file in files {
                            let filename = file.lastPathComponent
                            print("Prüfe Datei: \(filename)")
                            
                            if filename.contains(weekday) && filename.contains(weekType) && filename.contains(className) {
                                print("Gefunden: \(file.path)")
                                return file
                            }
                        }
                    } catch {
                        print("Fehler beim Durchsuchen des Verzeichnisses \(path): \(error)")
                    }
                } else {
                    print("Verzeichnis nicht gefunden oder ist kein Verzeichnis: \(path)")
                }
            }
        }
        
        // Prüfe zuerst den exakten Namen im Hauptverzeichnis der App
        if let url = Bundle.main.url(forResource: baseName, withExtension: "json") {
            print("Gefunden im Hauptverzeichnis: \(url.path)")
            return url
        }
        
        // Prüfe im Klassenordner
        if let url = Bundle.main.url(forResource: baseName, withExtension: "json", subdirectory: className) {
            print("Gefunden im Klassenordner: \(url.path)")
            return url
        }
        
        print("Keine passende JSON-Datei gefunden für: \(baseName)")
        return nil
    }
    
    // Prüft, ob für den angegebenen Jahrgang Stundenpläne existieren
    static func timetableExists(for schoolClass: String) -> Bool {
        // Spezialfall für 10b mit vollständigem Pfad
        if schoolClass == "10b" {
            let fileManager = FileManager.default
            let fullPath = "/Users/matskahmann/Documents/GitHub/cnprmedia_mdu-app/MdU App/10b"
            
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                print("10b-Verzeichnis gefunden unter vollständigem Pfad: \(fullPath)")
                return true
            } else {
                print("10b-Verzeichnis nicht gefunden unter vollständigem Pfad: \(fullPath)")
            }
        }
        
        // Prüfe, ob der Ordner existiert
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        let classDirectoryURL = bundleURL.appendingPathComponent(schoolClass)
        
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: classDirectoryURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            print("Klassenverzeichnis gefunden: \(classDirectoryURL.path)")
            return true
        }
        
        print("Kein Stundenplan für Klasse \(schoolClass) gefunden")
        return false
    }
    
    // Bestimmt, ob die aktuelle Woche eine grüne oder rote Woche ist
    static func isGreenWeek(for date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        // Gerade Wochen sind grün, ungerade sind rot
        let isGreen = weekOfYear % 2 == 0
        print("Woche \(weekOfYear) ist \(isGreen ? "grün" : "rot")")
        return isGreen
    }
    
    // Konvertiert LessonData zu Lesson
    static func convertToLesson(lessonData: LessonData, date: Date) -> Lesson {
        // Extrahiere Start- und Endzeit
        let timeComponents = lessonData.Zeit.components(separatedBy: "-")
        let startTimeString = timeComponents.first?.trimmingCharacters(in: .whitespaces) ?? "00:00"
        let endTimeString = timeComponents.last?.trimmingCharacters(in: .whitespaces) ?? "00:00"
        
        // Erstelle Date-Objekte für Start- und Endzeit
        let calendar = Calendar.current
        let startComponents = startTimeString.components(separatedBy: ":")
        let endComponents = endTimeString.components(separatedBy: ":")
        
        let startHour = Int(startComponents.first ?? "0") ?? 0
        let startMinute = Int(startComponents.last ?? "0") ?? 0
        let endHour = Int(endComponents.first ?? "0") ?? 0
        let endMinute = Int(endComponents.last ?? "0") ?? 0
        
        var startDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        startDateComponents.hour = startHour
        startDateComponents.minute = startMinute
        
        var endDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        endDateComponents.hour = endHour
        endDateComponents.minute = endMinute
        
        let startTime = calendar.date(from: startDateComponents) ?? date
        let endTime = calendar.date(from: endDateComponents) ?? date
        
        // Bestimme Farbe basierend auf dem Fach
        let color = getColorForSubject(lessonData.Fach)
        
        return Lesson(
            subject: lessonData.Fach,
            room: lessonData.Raum,
            teacher: lessonData.Lehrer,
            timeSlot: lessonData.Zeit,
            color: color,
            startTime: startTime,
            endTime: endTime,
            isSchoolEvent: false,
            targetGroups: [],
            notes: ""
        )
    }
    
    // Hilfsfunktion zur Bestimmung der Farbe basierend auf dem Fach
    private static func getColorForSubject(_ subject: String) -> Color {
        let subjectLower = subject.lowercased()
        
        if subjectLower.contains("mathe") {
            return .blue
        } else if subjectLower.contains("deutsch") {
            return .red
        } else if subjectLower.contains("englisch") || subjectLower.contains("französisch") || subjectLower.contains("latein") || subjectLower.contains("russisch") {
            return .purple
        } else if subjectLower.contains("physik") {
            return .yellow
        } else if subjectLower.contains("biologie") {
            return .green
        } else if subjectLower.contains("chemie") {
            return .pink
        } else if subjectLower.contains("geschichte") {
            return .cyan
        } else if subjectLower.contains("kunst") {
            return .orange
        } else if subjectLower.contains("sport") {
            return .green
        } else if subjectLower.contains("informatik") {
            return .blue
        } else if subjectLower.contains("ethik") || subjectLower.contains("religion") {
            return .purple
        } else if subjectLower.contains("erdkunde") || subjectLower.contains("geo") {
            return .brown
        } else {
            return .gray
        }
    }
    
    // Konvertiert einen Wochentag-Index in einen String
    static func weekdayString(for weekdayIndex: Int) -> String {
        print("Konvertiere Wochentag-Index: \(weekdayIndex)")
        switch weekdayIndex {
        case 2: return "Montag"
        case 3: return "Dienstag"
        case 4: return "Mittwoch"
        case 5: return "Donnerstag"
        case 6: return "Freitag"
        case 7: return "Samstag"
        case 1: return "Sonntag"
        default: 
            print("Ungültiger Wochentag-Index: \(weekdayIndex)")
            return ""
        }
    }
} 