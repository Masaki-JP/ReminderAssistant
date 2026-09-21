import Foundation
import ReminderCore

enum ReminderEditorMode: Identifiable {
    case create
    case edit(Reminder)
    
    var id: String {
        switch self {
        case .create: "create"
        case .edit(let reminder): "edit:\(reminder.id)"
        }
    }
    
    var navigationTitle: String {
        switch self {
        case .create: "新規作成"
        case .edit: "編集"
        }
    }
    
    var confirmButtonTitle: String {
        switch self {
        case .create: "作成"
        case .edit: "保存"
        }
    }
    
    var errorTitle: String {
        switch self {
        case .create: "作成失敗"
        case .edit: "保存失敗"
        }
    }
    
    var initialDraft: ReminderDraft {
        switch self {
        case .create: .init()
        case .edit(let reminder): .init(reminder: reminder)
        }
    }
    
    var initialCalendarDeadline: Date {
        let calendar = Calendar.gregorianCalendar()
        let defaultDeadline = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
        
        guard case .edit(let reminder) = self,
              let dueDateComponents = reminder.dueDateComponents else {
            return defaultDeadline
        }
        
        if reminder.hasDueTime == true {
            return reminder.dueDate() ?? defaultDeadline
        }
        
        var calendarDeadlineComponents = DateComponents()
        calendarDeadlineComponents.calendar = calendar
        calendarDeadlineComponents.timeZone = calendar.timeZone
        calendarDeadlineComponents.year = dueDateComponents.year
        calendarDeadlineComponents.month = dueDateComponents.month
        calendarDeadlineComponents.day = dueDateComponents.day
        calendarDeadlineComponents.hour = 9
        calendarDeadlineComponents.minute = 0
        calendarDeadlineComponents.second = 0
        return calendar.date(from: calendarDeadlineComponents) ?? defaultDeadline
    }
    
    /// 作成時、または編集対象に期限がある場合だけ期限欄を表示し、入力を必須にする。
    var showsDeadline: Bool {
        switch self {
        case .create: true
        case .edit(let reminder): reminder.dueDateComponents != nil
        }
    }
    
    func canSave(_ draft: ReminderDraft, initialDraft: ReminderDraft) -> Bool {
        guard draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return false }
        if showsDeadline && draft.deadline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        switch self {
        case .create: return true
        case .edit: return draft != initialDraft
        }
    }
}
