import SwiftUI

struct Lesson {
    let subject: String
    let room: String
    let teacher: String
    let timeSlot: String
    let color: Color
    let startTime: Date
    let endTime: Date
    var isSchoolEvent: Bool = false
    var targetGroups: [String] = []
    var notes: String = ""
} 