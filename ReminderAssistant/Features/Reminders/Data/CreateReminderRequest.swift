import Foundation

nonisolated
struct CreateReminderRequest {
    let title: String
    let deadline: String
    let priority: Reminder.Priority
    let notes: String
    let list: ReminderList
}
