import Foundation

nonisolated
struct ReminderStoreFetchResult: Codable {
    let reminders: [Reminder]
    let editableLists: [ReminderList]
    let defaultListIdentifier: String?
}
