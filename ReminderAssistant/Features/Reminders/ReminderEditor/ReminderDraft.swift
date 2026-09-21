import Foundation
import ReminderCore

enum ReminderDeadlineFormatter {
    static func string(from date: Date, calendar: Calendar = .gregorianCalendar(), includesTime: Bool) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = includesTime ? "yyyy年M月d日 H時mm分" : "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

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
        
        if let date = reminder.dueDate() {
            deadline = ReminderDeadlineFormatter.string(
                from: date,
                calendar: reminder.dueDateCalendar(),
                includesTime: reminder.hasDueTime,
            )
        }
        initialDeadline = deadline
    }
    
    /// 更新する期限の文字列。未変更なら`nil`を返し、元の期限の精度やタイムゾーンを保持する。
    var deadlineUpdate: String? {
        deadline == initialDeadline ? nil : deadline
    }
}
