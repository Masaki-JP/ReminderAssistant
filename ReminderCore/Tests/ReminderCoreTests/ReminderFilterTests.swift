import Foundation
import ReminderCore
import Testing

struct ReminderFilterTests {
    private let calendar = Calendar.gregorianCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
    private var now: Date { Self.date(year: 2026, month: 9, day: 27, hour: 12) }

    @Test("既定のフィルターは未完了のリマインダーだけに一致する")
    func defaultFilterMatchesOnlyIncompleteReminders() {
        let filter = ReminderFilter()

        #expect(filter.isDefault)
        #expect(filter.matches(reminder(id: "incomplete"), calendar: calendar, now: now))
        #expect(filter.matches(reminder(id: "completed", isCompleted: true), calendar: calendar, now: now) == false)
    }

    @Test("完了状態の条件でリマインダーを絞り込む", arguments: ReminderFilter.CompletionStatus.allCases)
    func completionStatusFiltersReminders(_ status: ReminderFilter.CompletionStatus) {
        var filter = ReminderFilter()
        filter.completionStatus = status

        let incomplete = filter.matches(reminder(id: "incomplete"), calendar: calendar, now: now)
        let completed = filter.matches(reminder(id: "completed", isCompleted: true), calendar: calendar, now: now)

        switch status {
        case .all:
            #expect(incomplete)
            #expect(completed)
        case .incomplete:
            #expect(incomplete)
            #expect(completed == false)
        case .completed:
            #expect(incomplete == false)
            #expect(completed)
        }
    }

    @Test("メモ条件は空白だけのメモを未入力として扱う")
    func notesFilterTreatsWhitespaceAsEmpty() {
        var filter = ReminderFilter()
        filter.notesAvailability = .hasNotes
        #expect(filter.matches(reminder(id: "notes", notes: "  memo\n"), calendar: calendar, now: now))
        #expect(filter.matches(reminder(id: "blank", notes: " \n\t"), calendar: calendar, now: now) == false)

        filter.notesAvailability = .noNotes
        #expect(filter.matches(reminder(id: "blank", notes: " \n\t"), calendar: calendar, now: now))
        #expect(filter.matches(reminder(id: "notes", notes: "memo"), calendar: calendar, now: now) == false)
    }

    @Test("優先度条件は選択された優先度に一致する")
    func priorityFilterMatchesAnySelectedPriority() {
        var filter = ReminderFilter()
        filter.priorities = [.medium, .high]

        #expect(filter.matches(reminder(id: "high", priority: .high), calendar: calendar, now: now))
        #expect(filter.matches(reminder(id: "low", priority: .low), calendar: calendar, now: now) == false)
    }

    @Test("期限条件で期限なし・今日・明日を区別する")
    func dueDateFilterDistinguishesMissingTodayAndTomorrow() {
        let noDueDate = reminder(id: "none")
        let today = reminder(id: "today", dueDate: Self.date(year: 2026, month: 9, day: 27, hour: 23))
        let tomorrow = reminder(id: "tomorrow", dueDate: Self.date(year: 2026, month: 9, day: 28))
        var filter = ReminderFilter()

        filter.dueDateCondition = .noDueDate
        #expect(filter.matches(noDueDate, calendar: calendar, now: now))
        #expect(filter.matches(today, calendar: calendar, now: now) == false)

        filter.dueDateCondition = .hasDueDate
        #expect(filter.matches(tomorrow, calendar: calendar, now: now))
        #expect(filter.matches(noDueDate, calendar: calendar, now: now) == false)

        filter.dueDateCondition = .today
        #expect(filter.matches(today, calendar: calendar, now: now))
        #expect(filter.matches(tomorrow, calendar: calendar, now: now) == false)

        filter.dueDateCondition = .tomorrow
        #expect(filter.matches(tomorrow, calendar: calendar, now: now))
        #expect(filter.matches(today, calendar: calendar, now: now) == false)
    }

    @Test("終日期限は当日中は期限切れにならない")
    func overdueFilterKeepsAllDayDueDateCurrentUntilTomorrow() {
        var filter = ReminderFilter()
        filter.dueDateCondition = .overdue

        let dueEarlierToday = reminder(id: "all-day-today", dueDate: Self.date(year: 2026, month: 9, day: 27))
        let dueYesterday = reminder(id: "all-day-yesterday", dueDate: Self.date(year: 2026, month: 9, day: 26))
        let timedEarlierToday = reminder(
            id: "timed-today",
            dueDate: Self.date(year: 2026, month: 9, day: 27, hour: 11),
            hasDueTime: true,
        )

        #expect(filter.matches(dueEarlierToday, calendar: calendar, now: now) == false)
        #expect(filter.matches(dueYesterday, calendar: calendar, now: now))
        #expect(filter.matches(timedEarlierToday, calendar: calendar, now: now))
    }

    @Test("今後7日間の条件は今日から6日後までを含む")
    func nextSevenDaysIncludesTodayAndSixthDayButExcludesSeventhDay() {
        var filter = ReminderFilter()
        filter.dueDateCondition = .nextSevenDays

        let today = reminder(id: "today", dueDate: Self.date(year: 2026, month: 9, day: 27))
        let sixthDay = reminder(id: "sixth", dueDate: Self.date(year: 2026, month: 10, day: 3))
        let seventhDay = reminder(id: "seventh", dueDate: Self.date(year: 2026, month: 10, day: 4))
        let yesterday = reminder(id: "yesterday", dueDate: Self.date(year: 2026, month: 9, day: 26))

        #expect(filter.matches(today, calendar: calendar, now: now))
        #expect(filter.matches(sixthDay, calendar: calendar, now: now))
        #expect(filter.matches(seventhDay, calendar: calendar, now: now) == false)
        #expect(filter.matches(yesterday, calendar: calendar, now: now) == false)
    }

    @Test("日付条件は暦日の境界で判定し、日付なしは除外する")
    func dateFilterUsesCalendarDayBoundariesAndRejectsMissingDates() {
        var filter = ReminderFilter()
        filter.creationDateCondition = .pastThreeDays

        let startOfWindow = reminder(id: "start", creationDate: Self.date(year: 2026, month: 9, day: 25))
        let beforeWindow = reminder(id: "before", creationDate: Self.date(year: 2026, month: 9, day: 24, hour: 23, minute: 59))
        let tomorrow = reminder(id: "future", creationDate: Self.date(year: 2026, month: 9, day: 28))

        #expect(filter.matches(startOfWindow, calendar: calendar, now: now))
        #expect(filter.matches(beforeWindow, calendar: calendar, now: now) == false)
        #expect(filter.matches(tomorrow, calendar: calendar, now: now) == false)
        #expect(filter.matches(reminder(id: "missing-date"), calendar: calendar, now: now) == false)

        filter.creationDateCondition = .all
        #expect(filter.matches(reminder(id: "missing-date"), calendar: calendar, now: now))
    }

    private func reminder(
        id: String,
        dueDate: Date? = nil,
        hasDueTime: Bool = false,
        priority: Reminder.Priority = .none,
        notes: String? = nil,
        isCompleted: Bool = false,
        creationDate: Date? = nil,
        lastModifiedDate: Date? = nil,
        completionDate: Date? = nil
    ) -> Reminder {
        var dueDateComponents = dueDate.map {
            calendar.dateComponents([.year, .month, .day], from: $0)
        }
        if hasDueTime, let dueDate {
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: dueDate)
            dueDateComponents?.hour = timeComponents.hour
            dueDateComponents?.minute = timeComponents.minute
            dueDateComponents?.second = timeComponents.second
        }
        dueDateComponents?.timeZone = calendar.timeZone

        return Reminder(
            id: id,
            title: id,
            dueDateComponents: dueDateComponents,
            priority: priority,
            notes: notes,
            isCompleted: isCompleted,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate,
            completionDate: completionDate,
        )
    }

    private static func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        let calendar = Calendar.gregorianCalendar(timeZone: TimeZone(secondsFromGMT: 0)!)
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
