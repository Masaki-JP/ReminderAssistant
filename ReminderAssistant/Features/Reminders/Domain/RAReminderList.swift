import Foundation

nonisolated
struct RAReminderList: Codable, Identifiable, Hashable {
    let calendarIdentifier: String
    let title: String
    
    var id: String { calendarIdentifier }
}
