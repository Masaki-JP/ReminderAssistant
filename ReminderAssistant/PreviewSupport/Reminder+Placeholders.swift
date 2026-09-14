import ReminderCore

nonisolated extension Reminder {
    static func placeholders() -> [Reminder] {
        let dueDate1 = DateInput(date: "50日前", time: "9:00")
        let dueDate2 = DateInput(date: "50日後", time: "9:00")
        let creationDate = DateInput(date: "100日前", time: "9:00")
        
        return [
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000001",
                title: "xxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000002",
                title: "xxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000003",
                title: "xxxxxxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000004",
                title: "xxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000005",
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000006",
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000007",
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000008",
                title: "xxxxxxxxxxxxxxxx",
                dueDate: .init(date: "昨日", time: "11:02"),
                priority: .low,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000009",
                title: "xxxxxxxxxx",
                dueDate: dueDate2,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            Reminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000010",
                title: "xxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
        ]
    }
}
