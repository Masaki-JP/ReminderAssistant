nonisolated
public struct ReminderList: Codable, Identifiable, Hashable, Sendable {
    public let calendarIdentifier: String
    public let title: String
    public let isDefault: Bool
    public var reminders: [Reminder]
    
    public var id: String { calendarIdentifier }

    public init(calendarIdentifier: String, title: String, isDefault: Bool, reminders: [Reminder]) {
        self.calendarIdentifier = calendarIdentifier
        self.title = title
        self.isDefault = isDefault
        self.reminders = reminders
    }
}
