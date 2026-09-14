import ReminderCore

nonisolated extension Reminder {
    static var samples: [Reminder] {
        ReminderList.samples.flatMap(\.reminders).sorted { $0.id < $1.id }
    }
}
