import Foundation
import ReminderCore

/// 作成・編集フォームの入力値。保存が確定するまで元のリマインダーには反映しない。
struct ReminderDraft: Equatable {
    var title: String = ""
    var deadline: String = ""
    var priority: Reminder.Priority = .none
    var notes: String = ""
    private var initialDeadline: String = ""
    
    init(title: String = "", deadline: String = "", priority: Reminder.Priority = .none, notes: String = "") {
        self.title = title
        self.deadline = deadline
        self.priority = priority
        self.notes = notes
        initialDeadline = deadline
    }
    
    init(reminder: Reminder) {
        title = reminder.title
        priority = reminder.priority
        notes = reminder.notes ?? ""
        
        deadline = ReminderDeadlineText.string(for: reminder) ?? ""
        initialDeadline = deadline
    }
    
    /// 更新する期限の文字列。未変更なら`nil`を返し、元の期限の精度やタイムゾーンを保持する。
    var deadlineUpdate: String? {
        deadline == initialDeadline ? nil : deadline
    }
}
