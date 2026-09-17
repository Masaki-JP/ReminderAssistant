import SwiftUI
import ReminderCore

struct ReminderListView: View {
    let sections: [ReminderListSection]
    let toggleCompletionAction: (Reminder) -> Void
    let editAction: (Reminder) -> Void
    let deleteAction: (_ id: String) -> Void
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    init(
        sections: [ReminderListSection],
        onToggleCompletion: @escaping (Reminder) -> Void,
        onEdit: @escaping (Reminder) -> Void,
        onDelete: @escaping (_ id: String) -> Void,
    ) {
        self.sections = sections
        self.toggleCompletionAction = onToggleCompletion
        self.editAction = onEdit
        self.deleteAction = onDelete
    }
    
    var isScrollIndicatorsVisible: Bool { sections.flatMap(\.reminders).count >= 100 }
    
    var body: some View {
        List {
            ForEach(sections) { self.section($0).listSectionSeparator(.hidden) }
        }
        .listStyle(.plain)
        .listRowSpacing(12)
        .listSectionSpacing(28)
        .environment(\.defaultMinListHeaderHeight, 0)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollIndicators(isScrollIndicatorsVisible == true ? .visible : .hidden)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    func section(_ section: ReminderListSection) -> some View {
        Section {
            ForEach(section.reminders) { reminder in
                ReminderRowView(
                    reminder: reminder,
                    onToggleCompletion: { toggleCompletionAction(reminder) },
                )
                .disabled(reminder.isMarkedForDeletion)
                .listRowBackground(Color.clear)
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
                .contextMenu {
                    Button("編集", systemImage: "pencil") {
                        editAction(reminder)
                    }
                    Button("削除（即時実行）", systemImage: "trash", role: .destructive) {
                        deleteAction(reminder.id)
                    }
                }
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
}

struct ReminderListSection: Identifiable {
    let title: String
    let tint: Color
    let reminders: [Reminder]
    
    var id: String { title }
}

private let reminderListPreviewCalendar = Calendar.gregorianCalendar()

#Preview("Light") {
    let startOfToday = reminderListPreviewCalendar.startOfDay(for: .now)
    let overduePreviewReminders = Array(
        Reminder.samples.filter { $0.dueDate().map { $0 < startOfToday } ?? false }.prefix(7)
    )
    let upcomingPreviewReminders = Array(
        Reminder.samples.filter { $0.dueDate().map { $0 >= startOfToday } ?? false }.prefix(7)
    )
    
    let sections = [
        ReminderListSection(title: "期限切れ", tint: .red, reminders: overduePreviewReminders),
        ReminderListSection(title: "期限前", tint: .blue, reminders: upcomingPreviewReminders),
    ]
    
    ReminderListView(
        sections: sections, onToggleCompletion: { _ in }, onEdit: { _ in }, onDelete: { _ in }
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    let startOfToday = reminderListPreviewCalendar.startOfDay(for: .now)
    let overduePreviewReminders = Array(
        Reminder.samples.filter { $0.dueDate().map { $0 < startOfToday } ?? false }.prefix(3)
    )
    let upcomingPreviewReminders = Array(
        Reminder.samples.filter { $0.dueDate().map { $0 >= startOfToday } ?? false }.prefix(3)
    )
    
    let sections = [
        ReminderListSection(title: "期限切れ", tint: .red, reminders: overduePreviewReminders),
        ReminderListSection(title: "期限前", tint: .blue, reminders: upcomingPreviewReminders),
    ]
    
    ReminderListView(
        sections: sections, onToggleCompletion: { _ in }, onEdit: { _ in }, onDelete: { _ in }
    )
    .preferredColorScheme(.dark)
}

/// ※1: primaryが機能しないため。
