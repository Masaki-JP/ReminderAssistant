import SwiftUI

struct ReminderSectionBuilder {
    private let reminders: [RAReminder]
    private let sortOrder: ReminderSortOrder
    private let calendar: Calendar
    private let now: Date
    
    init(
        reminders: [RAReminder],
        sortOrder: ReminderSortOrder,
        calendar: Calendar = .current,
        now: Date = .now
    ) {
        self.reminders = reminders
        self.sortOrder = sortOrder
        self.calendar = calendar
        self.now = now
    }
    
    func build() -> [ReminderListSection] {
        let sections = switch sortOrder.field {
        case .dueDate:
            dueDateSections
        case .priority:
            prioritySections
        case .creationDate:
            dateSections(for: \.creationDate)
        case .lastModifiedDate:
            dateSections(for: \.lastModifiedDate)
        case .completionDate:
            dateSections(for: \.completionDate)
        case .title:
            [ReminderListSection(title: "すべて", tint: .accentColor, reminders: reminders)]
        }
        
        return sections.filter { $0.reminders.isEmpty == false }
    }
    
    private var dueDateSections: [ReminderListSection] {
        let overdueReminders = reminders.filter {
            $0.dueDateStatus(relativeTo: now, calendar: calendar) == .overdue
        }
        let upcomingReminders = reminders.filter {
            $0.dueDateStatus(relativeTo: now, calendar: calendar) == .upcoming
        }
        let noDueDateReminders = reminders.filter {
            $0.dueDateStatus(relativeTo: now, calendar: calendar) == .noDueDate
        }
        let datedSections = [
            ReminderListSection(title: "期限切れ", tint: .red, reminders: overdueReminders),
            ReminderListSection(title: "期限前", tint: .blue, reminders: upcomingReminders)
        ]
        let orderedDatedSections = sortOrder.direction == .ascending
        ? datedSections
        : Array(datedSections.reversed())
        
        return orderedDatedSections + [
            ReminderListSection(title: "期限なし", tint: .secondary, reminders: noDueDateReminders)
        ]
    }
    
    private var prioritySections: [ReminderListSection] {
        let specifiedPrioritySections = [
            ReminderListSection(title: "低", tint: .blue, reminders: reminders(with: .low)),
            ReminderListSection(title: "中", tint: .orange, reminders: reminders(with: .medium)),
            ReminderListSection(title: "高", tint: .red, reminders: reminders(with: .high))
        ]
        let orderedSpecifiedPrioritySections = sortOrder.direction == .ascending
        ? specifiedPrioritySections
        : Array(specifiedPrioritySections.reversed())
        
        return orderedSpecifiedPrioritySections + [
            ReminderListSection(title: "なし", tint: .secondary, reminders: reminders(with: .none))
        ]
    }
    
    private func reminders(with priority: RAReminder.Priority) -> [RAReminder] {
        reminders.filter { $0.priority == priority }
    }
    
    private func dateSections(for keyPath: KeyPath<RAReminder, Date?>) -> [ReminderListSection] {
        let todayReminders = reminders.filter { reminder in
            reminder[keyPath: keyPath].map { calendar.isDate($0, inSameDayAs: now) } ?? false
        }
        let yesterdayReminders = reminders.filter { reminder in
            reminder[keyPath: keyPath].map(isYesterday) ?? false
        }
        let olderReminders = reminders.filter { reminder in
            guard let date = reminder[keyPath: keyPath] else { return false }
            return calendar.compare(date, to: now, toGranularity: .day) == .orderedAscending
            && isYesterday(date) == false
        }
        let futureReminders = reminders.filter { reminder in
            guard let date = reminder[keyPath: keyPath] else { return false }
            return calendar.compare(date, to: now, toGranularity: .day) == .orderedDescending
        }
        let noDateReminders = reminders.filter { $0[keyPath: keyPath] == nil }
        
        let datedSections = [
            ReminderListSection(title: "未来の日時（要確認）", tint: .red, reminders: futureReminders),
            ReminderListSection(title: "今日", tint: .blue, reminders: todayReminders),
            ReminderListSection(title: "昨日", tint: .orange, reminders: yesterdayReminders),
            ReminderListSection(title: "2日以上前", tint: .secondary, reminders: olderReminders)
        ]
        let orderedDatedSections = sortOrder.direction == .ascending
        ? Array(datedSections.reversed())
        : datedSections
        
        return orderedDatedSections + [
            ReminderListSection(title: "日時なし", tint: .secondary, reminders: noDateReminders)
        ]
    }
    
    private func isYesterday(_ date: Date) -> Bool {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return false }
        return calendar.isDate(date, inSameDayAs: yesterday)
    }
}
