import Foundation

struct ReminderFilter: Equatable {
    var completionStatus: CompletionStatus = .incomplete
    var dueDateCondition: DueDateCondition = .all
    var notesAvailability: NotesAvailability = .all
    var priorities: Set<RAReminder.Priority> = []
    var creationDateCondition: DateCondition = .all
    var lastModifiedDateCondition: DateCondition = .all
    var completionDateCondition: DateCondition = .all
    
    static let defaultValue = Self()
    
    var isDefault: Bool {
        self == Self.defaultValue
    }
    
    func matches(
        _ reminder: RAReminder,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> Bool {
        let hasNotes = reminder.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let isCompleted = reminder.isCompleted
        
        guard /// 完了状態
              completionStatus == .all
                || (completionStatus == .completed && isCompleted)
                || (completionStatus == .incomplete && !isCompleted),
              /// 期限日
              dueDateCondition.matches(reminder, calendar: calendar, now: now),
              /// メモの有無
              notesAvailability == .all
                || (notesAvailability == .hasNotes && hasNotes)
                || (notesAvailability == .noNotes && !hasNotes),
              /// 優先度
              priorities.isEmpty || priorities.contains(reminder.priority),
              /// 作成日
              creationDateCondition.matches(reminder.creationDate, calendar: calendar, now: now),
              /// 更新日
              lastModifiedDateCondition.matches(reminder.lastModifiedDate, calendar: calendar, now: now),
              /// 完了日
              completionDateCondition.matches(reminder.completionDate, calendar: calendar, now: now)
        else {
            return false
        }
        
        return true
    }
}

extension ReminderFilter {    
    enum CompletionStatus: CaseIterable, Identifiable {
        case all
        case incomplete
        case completed
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .all: "すべて"
            case .incomplete: "未完了"
            case .completed: "完了"
            }
        }
    }
    
    enum NotesAvailability: CaseIterable, Identifiable {
        case all
        case hasNotes
        case noNotes
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .all: "すべて"
            case .hasNotes: "あり"
            case .noNotes: "なし"
            }
        }
    }
    
    /// 期限日による絞り込みに使用される条件
    enum DueDateCondition: CaseIterable, Identifiable {
        case all
        case noDueDate
        case hasDueDate
        case overdue
        case today
        case tomorrow
        case nextSevenDays
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .all: "すべて"
            case .noDueDate: "期限なし"
            case .hasDueDate: "期限あり"
            case .overdue: "期限切れ"
            case .today: "今日"
            case .tomorrow: "明日"
            case .nextSevenDays: "今後7日間"
            }
        }
    }
    
    /// 作成日、更新日、完了日による絞り込みに使用される条件
    enum DateCondition: CaseIterable, Identifiable {
        case all
        case today
        case pastThreeDays
        case pastSevenDays
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .all: "すべて"
            case .today: "今日"
            case .pastThreeDays: "過去3日間"
            case .pastSevenDays: "過去7日間"
            }
        }
    }
}

private extension ReminderFilter.DueDateCondition {
    /// リマインダーの期限日が、この期限日条件に一致するかを判定する。
    func matches(_ reminder: RAReminder, calendar: Calendar, now: Date) -> Bool {
        let dueDateCalendar = reminder.dueDateCalendar(fallback: calendar)
        let dueDate = reminder.dueDate(calendar: dueDateCalendar)
        let today = dueDateCalendar.startOfDay(for: now)
        let tomorrow = dueDateCalendar.date(byAdding: .day, value: 1, to: today)
        
        return switch self {
        case .all:
            true
        case .noDueDate:
            dueDate == nil
        case .hasDueDate:
            dueDate != nil
        case .overdue:
            reminder.dueDateStatus(relativeTo: now, calendar: calendar) == .overdue
        case .today:
            dueDate.map { dueDateCalendar.isDate($0, inSameDayAs: now) } ?? false
        case .tomorrow:
            dueDate.map { dueDate in
                tomorrow.map { dueDateCalendar.isDate(dueDate, inSameDayAs: $0) } ?? false
            } ?? false
        case .nextSevenDays:
            dueDate.map {
                $0 >= today
                && $0 < dueDateCalendar.date(byAdding: .day, value: 7, to: today)!
            } ?? false
        }
    }
}

private extension ReminderFilter.DateCondition {
    /// 指定した日付が、この日付条件に一致するかを判定する。
    func matches(_ date: Date?, calendar: Calendar, now: Date) -> Bool {
        guard self != .all, let date else { return self == .all }
        
        return switch self {
        case .all:
            true
        case .today:
            calendar.isDate(date, inSameDayAs: now)
        case .pastThreeDays:
            matches(date, fromDaysAgo: 2, calendar: calendar, now: now)
        case .pastSevenDays:
            matches(date, fromDaysAgo: 6, calendar: calendar, now: now)
        }
    }
    
    /// 指定日数前の午前0時から今日の終わりまでに、日付が含まれるかを判定する。
    private func matches(_ date: Date, fromDaysAgo days: Int, calendar: Calendar, now: Date) -> Bool {
        let today = calendar.startOfDay(for: now)
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)
        else { return false }
        return date >= startDate && date < tomorrow
    }
}
