import Foundation

nonisolated
struct CreateReminderRequest {
    let title: String
    let deadline: String
    let priority: RAReminder.Priority
    let notes: String
    let list: RAReminderList
}
