import Foundation

nonisolated
struct ReminderStoreFetchResult: Codable {
    let reminders: [RAReminder]
    let editableLists: [RAReminderList]
    let defaultListIdentifier: String?
}
