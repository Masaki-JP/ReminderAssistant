nonisolated extension RAReminderList {
    enum Sample {
        static let household = RAReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000101",
            title: "家事"
        )
        
        static let personalTasks = RAReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000102",
            title: "個人"
        )
        
        static let work = RAReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000103",
            title: "仕事"
        )
        
        static let hobby = RAReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000104",
            title: "趣味"
        )
        
        static let other = RAReminderList(
            calendarIdentifier: "00000000-0000-0000-0000-000000000105",
            title: "その他"
        )
    }
}
