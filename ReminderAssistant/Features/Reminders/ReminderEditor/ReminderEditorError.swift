/// リマインダー作成・編集画面で扱うエラー。
enum ReminderEditorError: Error {
    case invalidTitle
    case invalidDeadline
    case destinationListUnavailable
    case reminderUnavailable
    case saveFailed
    case cancelled
    
    var message: String {
        switch self {
        case .invalidTitle:
            "件名を入力してください。"
        case .invalidDeadline:
            "期限を認識できませんでした。入力内容を確認し、もう一度お試しください。"
        case .destinationListUnavailable:
            "作成先のリストを利用できません。設定画面で作成先を選択してください。"
        case .reminderUnavailable:
            "編集対象のリマインダーが見つかりません。画面を閉じて一覧を確認してください。"
        case .saveFailed:
            "リマインダーの保存に失敗しました。もう一度お試しください。"
        case .cancelled:
            ""
        }
    }
}
