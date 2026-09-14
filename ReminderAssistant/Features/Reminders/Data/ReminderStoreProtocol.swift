import Foundation

protocol ReminderStoreProtocol: Actor {
    nonisolated var remindersMayHaveChanged: Notification.Name { get }
    
    func create(
        title: String,
        deadline: String,
        priority: Reminder.Priority,
        notes: String,
        list: ReminderList,
    ) async throws(ReminderStoreError)
    
    func set(id: String, completion: Bool) async throws(ReminderStoreError)
    
    func fetch() async throws(ReminderStoreError) -> [ReminderList]
}

enum ReminderStoreError: Error, Equatable {
    case accessNotAuthorized
    case listNotFound(calendarIdentifier: String)
    case reminderNotFound(calendarItemIdentifier: String)
    case fetchFailed
    case saveFailed
    case cancelled
    case deadlineConversionFailed
}
