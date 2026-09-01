import SwiftUI

struct ReminderList: View {
    let sections: [ReminderListSection]
    let onToggleCompletion: (RAReminder) -> Void
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var isScrollIndicatorsVisible: Bool {
        sections.flatMap(\.reminders).count >= 100
    }
    
    var body: some View {
        List {
            ForEach(sections) { section in
                self.section(section)
                    .listSectionSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .listRowSpacing(12)
        .listSectionSpacing(28)
        .environment(\.defaultMinListHeaderHeight, 0)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollIndicators(isScrollIndicatorsVisible == true ? .visible : .hidden)
        .background(backgroundColor)
    }
    
    func section(_ section: ReminderListSection) -> some View {
        Section {
            ForEach(section.reminders) { reminder in
                ReminderRow(
                    reminder: reminder,
                    onToggleCompletion: { onToggleCompletion(reminder) }
                )
                .padding(.trailing, 14)
                .padding([.top, .leading, .bottom], 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(rowBackgroundColor, in: .rect(cornerRadius: 16))
                .listRowBackground(backgroundColor)
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
            }
        } header: {
            sectionTitle(
                title: section.title,
                tintColor: section.tint,
                remindersCount: section.reminders.count
            )
            .listRowInsets(.init(top: .zero, leading: 16, bottom: 12, trailing: 12))
        }
        .listSectionMargins(.horizontal, 12)
    }
    
    func sectionTitle(title: String, tintColor: Color, remindersCount: Int) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.headline.weight(.medium))
                .foregroundStyle(colorScheme == .light ? .black : .white) // ※1
                .padding(.leading, 12)
                .background(alignment: .leading) {
                    Capsule()
                        .fill(tintColor)
                        .frame(width: 4)
                }
            
            Spacer()
            
            Text("\(remindersCount)")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(tintColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(tintColor.opacity(0.12), in: .capsule)
        }
    }
    
    var rowBackgroundColor: Color {
        let grayLevel = colorScheme == .light ? 1.0 : 0.075
        return .init(red: grayLevel, green: grayLevel, blue: grayLevel)
    }
    
    var backgroundColor: Color {
        .init(uiColor: .systemGroupedBackground)
    }
}

struct ReminderListSection: Identifiable {
    let title: String
    let tint: Color
    let reminders: [RAReminder]
    
    var id: String { title }
}

private let reminderListPreviewCalendar = Calendar.gregorianCalendar()

#Preview("Light") {
    let startOfToday = reminderListPreviewCalendar.startOfDay(for: .now)
    let overduePreviewReminders = Array(
        RAReminderSample.samples.filter { $0.dueDate().map { $0 < startOfToday } ?? false }.prefix(7)
    )
    let upcomingPreviewReminders = Array(
        RAReminderSample.samples.filter { $0.dueDate().map { $0 >= startOfToday } ?? false }.prefix(7)
    )
    
    let sections = [
        ReminderListSection(title: "期限切れ", tint: .red, reminders: overduePreviewReminders),
        ReminderListSection(title: "期限前", tint: .blue, reminders: upcomingPreviewReminders),
    ]
    
    ReminderList(
        sections: sections,
        onToggleCompletion: { _ in }
    )
    .background(.green)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let startOfToday = reminderListPreviewCalendar.startOfDay(for: .now)
    let overduePreviewReminders = Array(
        RAReminderSample.samples.filter { $0.dueDate().map { $0 < startOfToday } ?? false }.prefix(3)
    )
    let upcomingPreviewReminders = Array(
        RAReminderSample.samples.filter { $0.dueDate().map { $0 >= startOfToday } ?? false }.prefix(3)
    )
    
    let sections = [
        ReminderListSection(title: "期限切れ", tint: .red, reminders: overduePreviewReminders),
        ReminderListSection(title: "期限前", tint: .blue, reminders: upcomingPreviewReminders),
    ]
    
    ReminderList(
        sections: sections,
        onToggleCompletion: { _ in }
    )
    .preferredColorScheme(.dark)
}

/// ※1: primaryが機能しないため。
