import Foundation

nonisolated
struct RAReminder: Codable, Identifiable, Hashable {
    /// ``id``と同じ値。
    let calendarItemIdentifier: String
    let list: RAReminderList
    let title: String
    let dueDateComponents: DateComponents?
    let priority: Self.Priority
    let notes: String?
    private(set) var isCompleted: Bool
    private(set) var displayedIsCompleted: Bool
    let creationDate: Date?
    let lastModifiedDate: Date?
    let completionDate: Date?
    
    /// ``calendarItemIdentifier``と同じ値。
    var id: String { calendarItemIdentifier }

    init(
        calendarItemIdentifier: String,
        list: RAReminderList,
        title: String,
        dueDateComponents: DateComponents? = nil,
        priority: Self.Priority = .none,
        notes: String? = nil,
        isCompleted: Bool = false,
        creationDate: Date? = nil,
        lastModifiedDate: Date? = nil,
        completionDate: Date? = nil
    ) {
        self.calendarItemIdentifier = calendarItemIdentifier
        self.list = list
        self.title = title
        self.dueDateComponents = dueDateComponents
        self.priority = priority
        self.notes = notes
        self.isCompleted = isCompleted
        self.displayedIsCompleted = isCompleted
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
        self.completionDate = completionDate
    }
    
    func dueDate(calendar: Calendar = .current) -> Date? {
        guard let dueDateComponents else { return nil }
        return Self.dueDate(from: dueDateComponents, calendar: calendar)
    }
    
    mutating func setIsCompleted(_ isCompleted: Bool) {
        self.isCompleted = isCompleted
    }
    
    mutating func setDisplayedIsCompleted(_ displayedIsCompleted: Bool) {
        self.displayedIsCompleted = displayedIsCompleted
    }

    func dueDateCalendar(fallback calendar: Calendar = .current) -> Calendar {
        guard let dueDateComponents else { return calendar }
        return dueDateComponents.resolvedCalendar(fallback: calendar)
    }

    static func dueDate(from components: DateComponents, calendar: Calendar = .current) -> Date? {
        components.resolvedCalendar(fallback: calendar).date(from: components)
    }
    
    var hasDueTime: Bool {
        dueDateComponents?.hour != nil
        || dueDateComponents?.minute != nil
        || dueDateComponents?.second != nil
    }
    
    func dueDateStatus(
        relativeTo now: Date = .now,
        calendar: Calendar = .current
    ) -> DueDateStatus {
        guard let dueDate = dueDate(calendar: calendar) else { return .noDueDate }
        let dueDateCalendar = dueDateCalendar(fallback: calendar)
        let comparisonDate = hasDueTime ? now : dueDateCalendar.startOfDay(for: now)
        return dueDate < comparisonDate ? .overdue : .upcoming
    }
}

nonisolated
extension DateComponents {
    /// グレゴリオ暦とコンポーネントに指定されたタイムゾーンで期日を解釈する。
    func resolvedCalendar(fallback: Calendar = .current) -> Calendar {
        Calendar.gregorianCalendar(timeZone: timeZone ?? fallback.timeZone)
    }
}

nonisolated
extension RAReminder {
    enum DueDateStatus {
        case noDueDate
        case overdue
        case upcoming
    }
    
    enum Priority: CaseIterable, Codable, Comparable, Identifiable {
        case none
        case low
        case medium
        case high
        
        var id: Self { self }
        
        var displayName: String {
            switch self {
            case .none: "未指定"
            case .low: "低"
            case .medium: "中"
            case .high: "高"
            }
        }
        
        init?(ekReminderPriority: Int) {
            switch ekReminderPriority {
            case 0: self = .none
            case 1...4: self = .high
            case 5: self = .medium
            case 6...9: self = .low
            default: return nil
            }
        }

        var ekReminderPriority: Int {
            switch self {
            case .none: 0
            case .low: 9
            case .medium: 5
            case .high: 1
            }
        }
    }
}
