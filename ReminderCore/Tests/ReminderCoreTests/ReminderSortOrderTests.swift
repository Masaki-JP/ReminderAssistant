import Foundation
import ReminderCore
import Testing

struct ReminderSortOrderTests {
    private let calendar = Calendar.gregorianCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)

    @Test("既定の並び順は期限の昇順")
    func defaultSortOrderIsAscendingDueDate() {
        let order = ReminderSortOrder()

        #expect(order.isDefault)
        #expect(order.field == .dueDate)
        #expect(order.direction == .ascending)
    }

    @Test("期限順では未設定値を昇順・降順とも末尾に置く")
    func dueDateSortOrdersDatesAndKeepsMissingValuesLastInEitherDirection() {
        let earlier = reminder(id: "earlier", dueDate: Self.date(day: 1))
        let later = reminder(id: "later", dueDate: Self.date(day: 2))
        let missing = reminder(id: "missing")
        var order = ReminderSortOrder()

        #expect(order.sorted([missing, later, earlier]).map(\.id) == ["earlier", "later", "missing"])

        order.direction = .descending
        #expect(order.sorted([missing, earlier, later]).map(\.id) == ["later", "earlier", "missing"])
    }

    @Test("優先度順では未指定を末尾に置く")
    func prioritySortUsesPriorityOrderAndKeepsUnspecifiedLast() {
        var order = ReminderSortOrder()
        order.field = .priority

        let high = reminder(id: "high", priority: .high)
        let low = reminder(id: "low", priority: .low)
        let medium = reminder(id: "medium", priority: .medium)
        let none = reminder(id: "none", priority: .none)

        #expect(order.sorted([none, high, medium, low]).map(\.id) == ["low", "medium", "high", "none"])

        order.direction = .descending
        #expect(order.sorted([low, none, high, medium]).map(\.id) == ["high", "medium", "low", "none"])
    }

    @Test("タイトルの空白を除いて比較し、同じ場合はID順にする")
    func titleSortTrimsWhitespaceAndUsesIDToBreakTies() {
        var order = ReminderSortOrder()
        order.field = .title

        let alpha = reminder(id: "alpha", title: " Alpha ")
        let alphaDuplicate = reminder(id: "alpha-2", title: "Alpha")
        let beta = reminder(id: "beta", title: "Beta")
        let blank = reminder(id: "blank", title: "  \n")

        #expect(order.sorted([blank, beta, alphaDuplicate, alpha]).map(\.id) == ["alpha", "alpha-2", "beta", "blank"])

        order.direction = .descending
        #expect(order.sorted([blank, alpha, beta]).map(\.id) == ["beta", "alpha", "blank"])
    }

    @Test("日付順では未設定値を末尾に置く")
    func dateSortPlacesMissingDatesLastAndOrdersDates() {
        var order = ReminderSortOrder()
        order.field = .creationDate

        let earlier = reminder(id: "earlier", creationDate: Self.date(day: 1))
        let later = reminder(id: "later", creationDate: Self.date(day: 2))
        let missing = reminder(id: "missing")

        #expect(order.sorted([missing, later, earlier]).map(\.id) == ["earlier", "later", "missing"])
    }

    private func reminder(
        id: String,
        title: String? = nil,
        dueDate: Date? = nil,
        priority: Reminder.Priority = .none,
        creationDate: Date? = nil
    ) -> Reminder {
        var dueDateComponents = dueDate.map {
            calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: $0)
        }
        dueDateComponents?.timeZone = calendar.timeZone

        return Reminder(
            id: id,
            title: title ?? id,
            dueDateComponents: dueDateComponents,
            priority: priority,
            creationDate: creationDate,
        )
    }

    private static func date(day: Int) -> Date {
        let calendar = Calendar.gregorianCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: day))!
    }
}
