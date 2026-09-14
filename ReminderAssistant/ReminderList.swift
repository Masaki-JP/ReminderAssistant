import Foundation

nonisolated
struct ReminderList: Codable, Identifiable, Hashable {
    let calendarIdentifier: String
    let title: String
    let isDefault: Bool
    var reminders: [Reminder]
    
    var id: String { calendarIdentifier }
}
