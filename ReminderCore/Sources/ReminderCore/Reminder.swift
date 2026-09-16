public import Foundation

nonisolated
public struct Reminder: Codable, Identifiable, Hashable, Sendable {
    /// リマインダーID。`EKCalendarItem`の`calendarItemIdentifier`が入る。
    public let id: String
    public let title: String
    public let dueDateComponents: DateComponents?
    public let priority: Self.Priority
    public let notes: String?
    public private(set) var isCompleted: Bool
    public let creationDate: Date?
    public let lastModifiedDate: Date?
    public let completionDate: Date?
    
    public private(set) var displayedIsCompleted: Bool
    public private(set) var isMarkedForDeletion = false
    
    public init(
        id: String,
        title: String,
        dueDateComponents: DateComponents? = nil,
        priority: Self.Priority = .none,
        notes: String? = nil,
        isCompleted: Bool = false,
        creationDate: Date? = nil,
        lastModifiedDate: Date? = nil,
        completionDate: Date? = nil
    ) {
        self.id = id
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
    
    /// 期限日のコンポーネントから期限日時を生成する。
    public func dueDate(calendar: Calendar = .current) -> Date? {
        guard let dueDateComponents else { return nil }
        return Self.dueDate(from: dueDateComponents, calendar: calendar)
    }
    
    /// リマインダーの完了状態を更新する。
    public mutating func setIsCompleted(_ isCompleted: Bool) {
        self.isCompleted = isCompleted
    }
    
    /// 画面に表示する完了状態を更新する。
    public mutating func setDisplayedIsCompleted(_ displayedIsCompleted: Bool) {
        self.displayedIsCompleted = displayedIsCompleted
    }
    
    /// 削除予定としてマークする。
    public mutating func markForDeletion() {
        isMarkedForDeletion = true
    }
    
    /// 期限日を解釈するカレンダーを返す。期限日のコンポーネントにタイムゾーンが指定されている場合はそのタイムゾーンを使用し、指定されていない場合はフォールバックのカレンダーのタイムゾーンを使用する。
    public func dueDateCalendar(fallback calendar: Calendar = .current) -> Calendar {
        guard let dueDateComponents else { return calendar }
        return dueDateComponents.resolvedCalendar(fallback: calendar)
    }
    
    /// 指定した期限日のコンポーネントから期限日時を生成する。
    public static func dueDate(from components: DateComponents, calendar: Calendar = .current) -> Date? {
        components.resolvedCalendar(fallback: calendar).date(from: components)
    }
    
    /// 期限日に時刻が指定されているかを示す。
    public var hasDueTime: Bool {
        dueDateComponents?.hour != nil || dueDateComponents?.minute != nil || dueDateComponents?.second != nil
    }
    
    /// 指定した日時を基準に期限日の状態を判定する。時刻が指定されていない期限日は、その日が終わるまで期限切れと判定しない。
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
        case noDueDate, overdue, upcoming
    }
    
    enum Priority: CaseIterable, Codable, Comparable, Identifiable, Sendable {
        case none, low, medium, high
        
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
