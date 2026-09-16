/// リマインダー一覧画面で表示するエラー。
enum ContentViewModelError: Error {
    case createReminderFailed
    case loadRemindersFailed
    case toggleCompletionFailed
    case deleteReminderFailed
    case reminderDestinationListUnavailable
    
    var title: String {
        switch self {
        case .createReminderFailed: "作成失敗"
        case .loadRemindersFailed: "読み込み失敗"
        case .toggleCompletionFailed: "更新失敗"
        case .deleteReminderFailed: "削除失敗"
        case .reminderDestinationListUnavailable: "作成先を選択してください"
        }
    }
    
    var message: String {
        switch self {
        case .createReminderFailed: "新規リマインダーを作成できませんでした。もう一度お試しください。"
        case .loadRemindersFailed: "リマインダーを読み込めませんでした。もう一度お試しください。"
        case .toggleCompletionFailed: "完了状態を更新できませんでした。最新の状態を再読み込みします。"
        case .deleteReminderFailed: "リマインダーを削除できませんでした。最新の状態を再読み込みします。"
        case .reminderDestinationListUnavailable: "新規リマインダーの作成先を設定画面で選択してください。"
        }
    }
    
    enum RecoveryBehavior { case dismiss, reload }
    
    var recoveryBehavior: RecoveryBehavior {
        switch self {
        case .loadRemindersFailed: .reload
        case .createReminderFailed, .toggleCompletionFailed, .deleteReminderFailed, .reminderDestinationListUnavailable: .dismiss
        }
    }
}
