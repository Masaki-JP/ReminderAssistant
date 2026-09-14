struct CreateReminderRequest {
    var title: String
    var deadline: String
    var priority: Reminder.Priority
    var notes: String
    /// フォーム入力時は未設定で、作成時に`ContentView`が作成先リストの識別子を設定する。
    var listIdentifier: String? = nil
}
