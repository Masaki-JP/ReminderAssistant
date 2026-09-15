import Foundation

public struct ReminderSortOrder: Equatable, Sendable {
    public var field: Field = .dueDate
    public var direction: Direction = .ascending
    
    public static let defaultValue = Self()
    public var isDefault: Bool { self == Self.defaultValue }
    
    public init() {}
    
    /// 現在の並び順設定に従ってリマインダーをソートする。
    public func sorted(_ reminders: [Reminder]) -> [Reminder] {
        reminders.sorted { lhs, rhs in
            let lhsHasSortValue = hasSortValue(lhs)
            let rhsHasSortValue = hasSortValue(rhs)
            if lhsHasSortValue != rhsHasSortValue { return lhsHasSortValue }
            let result = comparisonResult(lhs, rhs)
            if result == .orderedSame { return fallbackComparisonResult(lhs, rhs) == .orderedAscending }
            return direction == .ascending ? result == .orderedAscending : result == .orderedDescending
        }
    }
    
    /// 未設定の日時・タイトルは、方向にかかわらず常に末尾に配置する。
    private func hasSortValue(_ reminder: Reminder) -> Bool {
        switch field {
        case .dueDate: reminder.dueDate() != nil
        case .priority: reminder.priority != .none
        case .title: normalizedTitle(reminder) != nil
        case .creationDate: reminder.creationDate != nil
        case .lastModifiedDate: reminder.lastModifiedDate != nil
        case .completionDate: reminder.completionDate != nil
        }
    }
    
    /// 指定したソート項目の値で2件のリマインダーを比較する。
    private func comparisonResult(_ lhs: Reminder, _ rhs: Reminder) -> ComparisonResult {
        switch field {
        case .dueDate: optionalComparison(lhs.dueDate(), rhs.dueDate())
        case .priority: comparison(lhs.priority, rhs.priority)
        case .title: titleComparison(lhs, rhs)
        case .creationDate: optionalComparison(lhs.creationDate, rhs.creationDate)
        case .lastModifiedDate: optionalComparison(lhs.lastModifiedDate, rhs.lastModifiedDate)
        case .completionDate: optionalComparison(lhs.completionDate, rhs.completionDate)
        }
    }
    
    /// 比較可能なオプション値を比較し、未設定の値は末尾として扱う。
    private func optionalComparison<T: Comparable>(_ lhs: T?, _ rhs: T?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?): comparison(lhs, rhs)
        case (nil, nil): .orderedSame
        case (nil, _): .orderedDescending
        case (_, nil): .orderedAscending
        }
    }
    
    /// 2つの比較可能な値の前後関係を返す。
    private func comparison<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        lhs == rhs ? .orderedSame : (lhs < rhs ? .orderedAscending : .orderedDescending)
    }
    
    /// 空白を除いたタイトルをローカライズされた標準順で比較する。
    private func titleComparison(_ lhs: Reminder, _ rhs: Reminder) -> ComparisonResult {
        optionalComparison(normalizedTitle(lhs), normalizedTitle(rhs)) { lhs, rhs in
            lhs.localizedStandardCompare(rhs)
        }
    }
    
    /// 同じソート値のリマインダーをタイトル、次にIDで安定して比較する。
    private func fallbackComparisonResult(_ lhs: Reminder, _ rhs: Reminder) -> ComparisonResult {
        let titleResult = titleComparison(lhs, rhs)
        guard titleResult == .orderedSame else { return titleResult }
        return lhs.id.localizedStandardCompare(rhs.id)
    }
    
    /// 前後の空白を除いたタイトルを返し、空の場合は未設定として扱う。
    private func normalizedTitle(_ reminder: Reminder) -> String? {
        let title = reminder.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty == true ? nil : title
    }
    
    /// 任意の比較処理でオプション値を比較し、未設定の値は末尾として扱う。
    private func optionalComparison<T>(_ lhs: T?, _ rhs: T?, using compare: (T, T) -> ComparisonResult) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?): compare(lhs, rhs)
        case (nil, nil): .orderedSame
        case (nil, _): .orderedDescending
        case (_, nil): .orderedAscending
        }
    }
}

public extension ReminderSortOrder {
    enum Field: CaseIterable, Identifiable, Sendable {
        case title, dueDate, priority, creationDate, lastModifiedDate, completionDate
        
        public var id: Self { self }
        
        public var displayName: String {
            switch self {
            case .dueDate: "期限"
            case .priority: "優先度"
            case .title: "タイトル"
            case .creationDate: "作成日時"
            case .lastModifiedDate: "更新日時"
            case .completionDate: "完了日時"
            }
        }
    }
    
    enum Direction: CaseIterable, Identifiable, Sendable {
        case ascending, descending
        
        public var id: Self { self }
        
        public var displayName: String {
            switch self {
            case .ascending: "昇順"
            case .descending: "降順"
            }
        }
    }
}
