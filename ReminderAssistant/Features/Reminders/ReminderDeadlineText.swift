import Foundation
import ReminderCore

enum ReminderDeadlineText {
    static func string(for reminder: Reminder, relativeTo now: Date = .now) -> String? {
        guard let dueDate = reminder.dueDate() else { return nil }
        return string(
            for: dueDate,
            hasDueTime: reminder.hasDueTime,
            calendar: reminder.dueDateCalendar(),
            relativeTo: now
        )
    }
    
    static func string(
        for date: Date,
        hasDueTime: Bool,
        calendar: Calendar,
        relativeTo now: Date = .now
    ) -> String {
        let dateText = if calendar.isDateInYesterday(date) {
            "昨日"
        } else if calendar.isDateInToday(date) {
            "今日"
        } else if calendar.isDateInTomorrow(date) {
            "明日"
        } else if let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: now),
                  calendar.isDate(date, inSameDayAs: dayBeforeYesterday) {
            "一昨日"
        } else if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: now),
                  calendar.isDate(date, inSameDayAs: dayAfterTomorrow) {
            "明後日"
        } else {
            date.formatted(japaneseDateFormatStyle(calendar: calendar))
        }
        
        guard hasDueTime else { return dateText }
        
        return "\(dateText) \(date.formatted(timeFormatStyle(calendar: calendar)))"
    }
    
    static func japaneseDateFormatStyle(calendar: Calendar) -> Date.VerbatimFormatStyle {
        .verbatim(
            japaneseDateFormat,
            locale: Locale(identifier: "ja_JP"),
            timeZone: calendar.timeZone,
            calendar: calendar
        )
    }
    
    static func timeFormatStyle(calendar: Calendar) -> Date.VerbatimFormatStyle {
        .verbatim(
            timeFormat,
            locale: Locale(identifier: "ja_JP"),
            timeZone: calendar.timeZone,
            calendar: calendar
        )
    }
    
    static let japaneseDateFormat: Date.FormatString = "\(month: .defaultDigits)月\(day: .defaultDigits)日（\(weekday: .abbreviated)）"
    static let timeFormat: Date.FormatString = "\(hour: .defaultDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)"
}
