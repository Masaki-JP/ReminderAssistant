import Foundation
import ReminderCore
import Testing

struct MixReminderListTests {
    @Test("選択したリストのリマインダーを元の順序で集約する")
    func remindersCombinesOnlySelectedListsInInputOrder() {
        let lists = [
            reminderList(id: "work", reminderIDs: ["work-1"]),
            reminderList(id: "home", reminderIDs: ["home-1", "home-2"]),
            reminderList(id: "archive", reminderIDs: ["archive-1"]),
        ]
        let mixList = MixReminderList(title: "今日", listIDs: ["home", "work"])

        #expect(mixList.reminders(in: lists).map(\.id) == ["work-1", "home-1", "home-2"])
    }

    @Test("タイトルの前後の空白を除いて重複を判定し、自分自身は除外する")
    func duplicateTitleTrimsWhitespaceAndExcludesEditedList() {
        let existing = MixReminderList(id: UUID(), title: "  週末  ", listIDs: ["work", "home"])
        let mixLists = [existing]

        #expect(MixReminderList.hasDuplicateTitle("週末", in: mixLists))
        #expect(MixReminderList.hasDuplicateTitle("平日", in: mixLists) == false)
        #expect(existing.hasDuplicateTitle(in: mixLists) == false)
        #expect(MixReminderList.hasDuplicateTitle("週末", in: mixLists, excludingListID: existing.id) == false)
    }

    @Test("保存には空でないタイトルと既存リスト2件以上が必要")
    func canSaveRequiresTitleAndAtLeastTwoExistingLists() {
        let sourceLists = [
            ReminderList(id: "work", title: "仕事", isDefault: true, reminders: []),
            ReminderList(id: "home", title: "自宅", isDefault: false, reminders: []),
            ReminderList(id: "archive", title: "アーカイブ", isDefault: false, reminders: []),
        ]

        #expect(MixReminderList.canSave(title: " 今週 ", listIDs: ["work", "home"], in: sourceLists, mixLists: []))
        #expect(MixReminderList.canSave(title: "今週", listIDs: ["work"], in: sourceLists, mixLists: []) == false)
        #expect(MixReminderList.canSave(title: "今週", listIDs: ["work", "missing"], in: sourceLists, mixLists: []) == false)
        #expect(MixReminderList.canSave(title: " \n ", listIDs: ["work", "home"], in: sourceLists, mixLists: []) == false)

        let duplicate = MixReminderList(title: "今週", listIDs: ["work", "home"])
        #expect(MixReminderList.canSave(title: "今週", listIDs: ["work", "home"], in: sourceLists, mixLists: [duplicate]) == false)
    }

    private func reminderList(id: String, reminderIDs: [String]) -> ReminderList {
        ReminderList(
            id: id,
            title: id,
            isDefault: false,
            reminders: reminderIDs.map { Reminder(id: $0, title: $0) },
        )
    }
}
