public import Foundation

nonisolated
public struct Reminder: Codable, Identifiable, Hashable, Sendable {
    /// ``id``と同じ値。
    public let calendarItemIdentifier: String
    public let title: String
    public let dueDateComponents: DateComponents?
    public let priority: Self.Priority
    public let notes: String?
    public private(set) var isCompleted: Bool
    public private(set) var displayedIsCompleted: Bool
    public let creationDate: Date?
    public let lastModifiedDate: Date?
    public let completionDate: Date?
    
    /// ``calendarItemIdentifier``と同じ値。
    public var id: String { calendarItemIdentifier }

    public init(
        calendarItemIdentifier: String,
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
    
    public func dueDate(calendar: Calendar = .current) -> Date? {
        guard let dueDateComponents else { return nil }
        return Self.dueDate(from: dueDateComponents, calendar: calendar)
    }
    
    public mutating func setIsCompleted(_ isCompleted: Bool) {
        self.isCompleted = isCompleted
    }
    
    public mutating func setDisplayedIsCompleted(_ displayedIsCompleted: Bool) {
        self.displayedIsCompleted = displayedIsCompleted
    }

    public func dueDateCalendar(fallback calendar: Calendar = .current) -> Calendar {
        guard let dueDateComponents else { return calendar }
        return dueDateComponents.resolvedCalendar(fallback: calendar)
    }

    public static func dueDate(from components: DateComponents, calendar: Calendar = .current) -> Date? {
        components.resolvedCalendar(fallback: calendar).date(from: components)
    }
    
    public var hasDueTime: Bool {
        dueDateComponents?.hour != nil
        || dueDateComponents?.minute != nil
        || dueDateComponents?.second != nil
    }
    
    public func dueDateStatus(
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
    fileprivate func resolvedCalendar(fallback: Calendar = .current) -> Calendar {
        Calendar.gregorianCalendar(timeZone: timeZone ?? fallback.timeZone)
    }
}

nonisolated
public extension Reminder {
    enum DueDateStatus: Sendable {
        case noDueDate
        case overdue
        case upcoming
    }
    
    enum Priority: CaseIterable, Codable, Comparable, Identifiable, Sendable {
        case none
        case low
        case medium
        case high
        
        public var id: Self { self }
        
        public var displayName: String {
            switch self {
            case .none: "未指定"
            case .low: "低"
            case .medium: "中"
            case .high: "高"
            }
        }
        
    }
}
