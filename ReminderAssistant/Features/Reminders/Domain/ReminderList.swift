import Foundation

nonisolated
struct ReminderList: Codable, Identifiable, Hashable {
    let calendarIdentifier: String
    let title: String
    
    var id: String { calendarIdentifier }
}
