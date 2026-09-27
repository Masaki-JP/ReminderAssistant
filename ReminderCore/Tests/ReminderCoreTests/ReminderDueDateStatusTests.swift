import Foundation
import ReminderCore
import Testing

struct ReminderDueDateStatusTests {
    private let calendar = Calendar.gregorianCalendar(timeZone: Self.utc)
    private var now: Date { Self.date(year: 2026, month: 9, day: 27, hour: 12) }

    @Test("期限なしのリマインダーは期限なし状態になる")
    func reminderWithoutDueDateHasNoDueDateStatus() {
        expect(
            Reminder(id: "no-due-date", title: "期限なし").dueDateStatus(relativeTo: now, calendar: calendar),
            is: .noDueDate,
        )
    }

    @Test("終日期限は当日中は期限前で、翌日から期限切れになる")
    func allDayDueDateExpiresAfterItsCalendarDay() {
        let dueToday = reminder(id: "today", year: 2026, month: 9, day: 27)
        let dueYesterday = reminder(id: "yesterday", year: 2026, month: 9, day: 26)

        expect(dueToday.dueDateStatus(relativeTo: now, calendar: calendar), is: .upcoming)
        expect(
            dueToday.dueDateStatus(
                relativeTo: Self.date(year: 2026, month: 9, day: 28),
                calendar: calendar,
            ),
            is: .overdue,
        )
        expect(dueYesterday.dueDateStatus(relativeTo: now, calendar: calendar), is: .overdue)
    }

    @Test("時刻指定期限は指定時刻を過ぎると期限切れになる")
    func timedDueDateUsesExactTimeBoundary() {
        let dueAtNoon = reminder(id: "noon", year: 2026, month: 9, day: 27, hour: 12)

        expect(
            dueAtNoon.dueDateStatus(
                relativeTo: Self.date(year: 2026, month: 9, day: 27, hour: 11, minute: 59),
                calendar: calendar,
            ),
            is: .upcoming,
        )
        expect(dueAtNoon.dueDateStatus(relativeTo: now, calendar: calendar), is: .upcoming)
        expect(
            dueAtNoon.dueDateStatus(
                relativeTo: Self.date(year: 2026, month: 9, day: 27, hour: 12, minute: 1),
                calendar: calendar,
            ),
            is: .overdue,
        )
    }

    @Test("期限コンポーネントのタイムゾーンに従って終日を判定する")
    func allDayDueDateUsesItsTimeZone() {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let dueDate = reminder(id: "los-angeles", year: 2026, month: 9, day: 27, timeZone: losAngeles)

        expect(
            dueDate.dueDateStatus(
                relativeTo: Self.date(year: 2026, month: 9, day: 28, hour: 6, minute: 59),
                calendar: calendar,
            ),
            is: .upcoming,
        )
        expect(
            dueDate.dueDateStatus(
                relativeTo: Self.date(year: 2026, month: 9, day: 28, hour: 7),
                calendar: calendar,
            ),
            is: .overdue,
        )
    }

    private func reminder(
        id: String,
        year: Int,
        month: Int,
        day: Int,
        hour: Int? = nil,
        timeZone: TimeZone = Self.utc,
    ) -> Reminder {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.timeZone = timeZone
        return Reminder(id: id, title: id, dueDateComponents: components)
    }

    private func expect(_ actual: Reminder.DueDateStatus, is expected: Reminder.DueDateStatus) {
        switch (actual, expected) {
        case (.noDueDate, .noDueDate), (.overdue, .overdue), (.upcoming, .upcoming):
            #expect(true)
        default:
            Issue.record("期限状態が一致しません")
        }
    }

    private static var utc: TimeZone { TimeZone(secondsFromGMT: 0)! }

    private static func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        let calendar = Calendar.gregorianCalendar(timeZone: utc)
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
