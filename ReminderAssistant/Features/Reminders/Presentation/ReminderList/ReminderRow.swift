import Foundation
import SwiftUI

struct ReminderRow: View {
    let reminder: RAReminder
    let toggleCompletionAction: () -> Void
    
    @Environment(\.scenePhase) var scenePhase: ScenePhase
    
    init(reminder: RAReminder, onToggleCompletion: @escaping () -> Void) {
        self.reminder = reminder
        self.toggleCompletionAction = onToggleCompletion
    }
    
    var body: some View {
        VStack(alignment: .listRowSeparatorLeading, spacing: 2) {
            HStack(alignment: .center, spacing: nil) {
                toggleCompletionButton
                reminderTitle
                Spacer(minLength: nil)
                if reminder.priority != .none {
                    Image(systemName: "flag.fill")
                        .foregroundStyle(flagColor)
                }
            }
            
            if let dueDate = reminder.dueDate() {
                Text(dueDateText(dueDate))
                    .foregroundStyle(dueDateTextColor)
                    .font(.caption)
            }
        }
        .sensoryFeedback(.selection, trigger: reminder.displayedIsCompleted)
    }
    
    var toggleCompletionButton: some View {
        Button {
            toggleCompletionAction()
        } label: {
            Image(systemName: reminder.displayedIsCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(reminder.displayedIsCompleted ? .green : .secondary.opacity(0.5))
                .padding(.top, 2)
        }
        .buttonStyle(.plain)
    }
    
    var reminderTitle: some View {
        Text(reminder.title)
            .strikethrough(reminder.displayedIsCompleted)
            .foregroundStyle(reminder.displayedIsCompleted ? .secondary : .primary)
            .lineLimit(1)
    }
    
    var flagColor: Color {
        switch reminder.priority {
        case .high: .red
        case .medium: .orange
        case .low: .blue
        case .none: .secondary
        }
    }
    
    var dueDateTextColor: Color {
        reminder.dueDateStatus() == .overdue ? .red : .secondary
    }
}

extension ReminderRow {
    func dueDateText(_ date: Date) -> String {
        let calendar = reminder.dueDateCalendar()
        let dateText = if calendar.isDateInYesterday(date) {
            "昨日"
        } else if calendar.isDateInToday(date) {
            "今日"
        } else if calendar.isDateInTomorrow(date) {
            "明日"
        } else if let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: .now),
                  calendar.isDate(date, inSameDayAs: dayBeforeYesterday) {
            "一昨日"
        } else if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: .now),
                  calendar.isDate(date, inSameDayAs: dayAfterTomorrow) {
            "明後日"
        } else {
            date.formatted(Self.japaneseDateFormatStyle(calendar: calendar))
        }
        
        guard reminder.hasDueTime == true else { return dateText }
        
        return "\(dateText) \(date.formatted(Self.timeFormatStyle(calendar: calendar)))"
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

//#if DEBUG
//#Preview("Light") {
//    @Previewable @State var reminders = sampleReminders
//    
//    previewContent(reminders: $reminders)
//        .safeAreaPadding(.horizontal)
//        .preferredColorScheme(.light)
//}
//
//#Preview("Dark") {
//    @Previewable @State var reminders = sampleReminders
//    
//    previewContent(reminders: $reminders)
//        .safeAreaPadding(.horizontal)
//        .preferredColorScheme(.dark)
//}
//
//func previewContent(reminders: Binding<[RAReminder]>) -> some View {
//    VStack(spacing: 24) {
//        ForEach(reminders.wrappedValue.indices, id: \.self) { i in
//            ReminderRow(
//                reminder: reminders.wrappedValue[i],
//                onToggleCompletion: {
//                    let isCompleted = reminders.wrappedValue[i].isCompleted
//                    reminders.wrappedValue[i].setCompletion(!isCompleted)
//                }
//            )
//            .border(.gray.opacity(0.1))
//        }
//    }
//    .border(.gray.opacity(0.1))
//}
//
//private let previewList = RAReminderList(
//    calendarIdentifier: "preview-reminder-list",
//    title: "プレビュー用リスト"
//)
//
//private let previewCalendar = Calendar.gregorianCalendar()
//
//private func previewDateComponents(
//    additionalDays: Int,
//    additionalTime: (hour: Int, minute: Int)? = nil
//) -> DateComponents {
//    let calendar = previewCalendar
//    let date = calendar.date(byAdding: .day, value: additionalDays, to: .now)!
//    var components = calendar.dateComponents([.year, .month, .day], from: date)
//    
//    if let additionalTime {
//        components.hour = additionalTime.hour
//        components.minute = additionalTime.minute
//    }
//    
//    return components
//}
//
//var sampleReminders: [RAReminder] = [
//    .init(
//        calendarItemIdentifier: "preview-reminder-1",
//        list: previewList,
//        title: "会議資料を確認する",
//        dueDateComponents: previewDateComponents(additionalDays: -3, additionalTime: (hour: 3, minute: 5)),
//        priority: .high,
//        notes: "発表用スライドの最終確認をする"),
//    .init(
//        calendarItemIdentifier: "preview-reminder-2",
//        list: previewList,
//        title: "メールを返信する",
//        dueDateComponents: previewDateComponents(additionalDays: -2, additionalTime: (hour: 3, minute: 5)),
//        priority: .medium,
//        isCompleted: true),
//    .init(
//        calendarItemIdentifier: "preview-reminder-3",
//        list: previewList,
//        title: "牛乳を買う",
//        dueDateComponents: previewDateComponents(additionalDays: -1, additionalTime: (hour: 3, minute: 5)),
//        priority: .low),
//    .init(
//        calendarItemIdentifier: "preview-reminder-4",
//        list: previewList,
//        title: "図書館の本を返す",
//        dueDateComponents: previewDateComponents(additionalDays: 0, additionalTime: (hour: 3, minute: 5))),
//    .init(
//        calendarItemIdentifier: "preview-reminder-5",
//        list: previewList,
//        title: "経費を精算する",
//        dueDateComponents: previewDateComponents(additionalDays: 1, additionalTime: (hour: 3, minute: 5)),
//        priority: .high,
//        isCompleted: true),
//    .init(
//        calendarItemIdentifier: "preview-reminder-6",
//        list: previewList,
//        title: "週末の予定を確認する",
//        dueDateComponents: previewDateComponents(additionalDays: 2, additionalTime: (hour: 3, minute: 5)),
//        priority: .medium),
//    .init(
//        calendarItemIdentifier: "preview-reminder-7",
//        list: previewList,
//        title: "資料を印刷する",
//        dueDateComponents: previewDateComponents(additionalDays: 3, additionalTime: (hour: 3, minute: 5)),
//        priority: .low),
//    .init(
//        calendarItemIdentifier: "preview-reminder-8",
//        list: previewList,
//        title: "洗濯物を取り込む",
//        dueDateComponents: previewDateComponents(additionalDays: -1)),
//    .init(
//        calendarItemIdentifier: "preview-reminder-9",
//        list: previewList,
//        title: "来週の会議を準備する",
//        dueDateComponents: previewDateComponents(additionalDays: 0),
//        priority: .high),
//]
//#endif
