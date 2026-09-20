public import Foundation

/// 既存のリストを組み合わせた表示用のリスト。元のリストやリマインダーは変更しない。
nonisolated public struct CustomReminderList: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var listIDs: Set<String>
    
    public init(id: UUID = .init(), title: String, listIDs: Set<String>) {
        self.id = id
        self.title = title
        self.listIDs = listIDs
    }
    
    public func reminders(in lists: [ReminderList]) -> [Reminder] {
        lists.filter { listIDs.contains($0.id) }.flatMap(\.reminders)
    }
    
    /// 指定されたリストを除外して、前後の空白を除いたタイトルの重複を確認する。
    public static func hasDuplicateTitle(
        _ title: String,
        in customLists: [CustomReminderList],
        excludingListID: UUID? = nil,
    ) -> Bool {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return customLists.contains {
            $0.id != excludingListID && $0.title.trimmingCharacters(in: .whitespacesAndNewlines) == normalizedTitle
        }
    }
    
    /// 自身を除外して、前後の空白を除いたタイトルの重複を確認する。
    public func hasDuplicateTitle(in customLists: [CustomReminderList]) -> Bool {
        Self.hasDuplicateTitle(title, in: customLists, excludingListID: id)
    }
    
    /// タイトル、リスト数、タイトルの重複に関する保存条件を満たすか確認する。
    public static func canSave(
        title: String,
        listIDs: Set<String>,
        in lists: [ReminderList],
        customLists: [CustomReminderList],
        excludingListID: UUID? = nil,
    ) -> Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        && listIDs.intersection(lists.map(\.id)).count >= 2
        && hasDuplicateTitle(title, in: customLists, excludingListID: excludingListID) == false
    }
    
    /// 自身の情報が保存条件を満たすか確認する。
    public func canSave(in lists: [ReminderList], customLists: [CustomReminderList]) -> Bool {
        Self.canSave(title: title, listIDs: listIDs, in: lists, customLists: customLists, excludingListID: id)
    }
}
