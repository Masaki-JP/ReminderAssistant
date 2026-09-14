public import Foundation

public protocol ReminderRepository: Actor {
    nonisolated var remindersMayHaveChanged: Notification.Name { get }
    
    func create(
        title: String,
        deadline: String,
        priority: Reminder.Priority,
        notes: String,
        list: ReminderList,
    ) async throws(ReminderRepositoryError)
    
    func set(id: String, completion: Bool) async throws(ReminderRepositoryError)
    
    func fetch() async throws(ReminderRepositoryError) -> [ReminderList]
}

public enum ReminderRepositoryError: Error, Equatable {
    case accessNotAuthorized
    case listNotFound(calendarIdentifier: String)
    case reminderNotFound(calendarItemIdentifier: String)
    case fetchFailed
    case saveFailed
    case cancelled
    case deadlineConversionFailed
}
