nonisolated extension RAReminder {
    static func placeholders(for list: RAReminderList) -> [RAReminder] {
        let dueDate1 = DateInput(date: "50日前", time: "9:00")
        let dueDate2 = DateInput(date: "50日後", time: "9:00")
        let creationDate = DateInput(date: "100日前", time: "9:00")
        
        return [
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000001",
                list: list,
                title: "xxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000002",
                list: list,
                title: "xxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000003",
                list: list,
                title: "xxxxxxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000004",
                list: list,
                title: "xxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000005",
                list: list,
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000006",
                list: list,
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000007",
                list: list,
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000008",
                list: list,
                title: "xxxxxxxxxxxxxxxx",
                dueDate: .init(date: "昨日", time: "11:02"),
                priority: .low,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000009",
                list: list,
                title: "xxxxxxxxxx",
                dueDate: dueDate2,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            RAReminder.sample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000010",
                list: list,
                title: "xxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
        ]
    }
}
