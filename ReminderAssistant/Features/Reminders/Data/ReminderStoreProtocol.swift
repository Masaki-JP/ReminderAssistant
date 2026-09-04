import Foundation

enum ReminderStoreError: Error, Equatable {
    case accessNotAuthorized
    case listNotFound(calendarIdentifier: String)
    case reminderNotFound(calendarItemIdentifier: String)
    case fetchFailed
    case saveFailed
    case cancelled
    case deadlineConversionFailed
}

protocol ReminderStoreProtocol: Actor {
    nonisolated var remindersMayHaveChangedNotification: Notification.Name { get }
    
    func create(_ request: CreateReminderRequest) async throws(ReminderStoreError)
    func set(id: String, completion: Bool) async throws(ReminderStoreError)
    func fetch() async throws(ReminderStoreError) -> ReminderStoreFetchResult
}
