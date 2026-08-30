import Foundation

nonisolated
protocol ReminderStoreCacheProtocol: Sendable {
    func fetch() async -> ReminderStoreFetchResult?
    func save(_ result: ReminderStoreFetchResult) async
}
