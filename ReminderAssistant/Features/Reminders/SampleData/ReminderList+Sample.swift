nonisolated extension ReminderList {
    enum Sample {
        static let household = ReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000101",
            title: "家事"
        )
        
        static let personalTasks = ReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000102",
            title: "個人"
        )
        
        static let work = ReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000103",
            title: "仕事"
        )
        
        static let hobby = ReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000104",
            title: "趣味"
        )
        
        static let other = ReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000105",
            title: "その他"
        )
    }
}
