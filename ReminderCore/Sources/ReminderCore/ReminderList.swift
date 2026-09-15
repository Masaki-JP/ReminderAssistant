nonisolated
public struct ReminderList: Codable, Identifiable, Hashable, Sendable {
    /// リストID。`EKCalendar`の`calendarIdentifier`が入る。
    public let id: String
    public let title: String
    public let isDefault: Bool
    public var reminders: [Reminder]
    
    public init(id: String, title: String, isDefault: Bool, reminders: [Reminder]) {
        self.id = id
        self.title = title
        self.isDefault = isDefault
        self.reminders = reminders
    }
}
