public import Foundation

public protocol ReminderRepositoryProtocol: Actor {
    nonisolated var remindersMayHaveChanged: Notification.Name { get }
    
    func create(
        title: String,
        deadline: String,
        priority: Reminder.Priority,
        notes: String,
        list: ReminderList,
    ) async throws(ReminderRepositoryError)
    
    func update(
        id: String,
        title: String?,
        deadline: String?,
        priority: Reminder.Priority?,
        notes: String??,
    ) async throws(ReminderRepositoryError)
    
    func set(id: String, completion: Bool) async throws(ReminderRepositoryError)
    func delete(id: String) async throws(ReminderRepositoryError)
    func fetch() async throws(ReminderRepositoryError) -> [ReminderList]
}

public enum ReminderRepositoryError: Error, Equatable {
    case accessNotAuthorized
    case listNotFound(id: String)
    case reminderNotFound(id: String)
    case fetchFailed
    case saveFailed
    case cancelled
    case invalidTitle
    case deadlineConversionFailed
    case deleteFailed
}
