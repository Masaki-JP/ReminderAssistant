import SwiftUI
import JapaneseDateConverter
import ReminderCore

struct ReminderForm: View {
    @State var isCalendarPresented = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Binding var draft: ReminderDraft
    @Binding var calendarDeadline: Date
    @Binding var destinationListID: ReminderList.ID?
    let destinationLists: [ReminderList]
    let japaneseDateConverter: JapaneseDateConverter
    var focus: FocusState<ReminderEditorField?>.Binding
    let showsDeadline: Bool
    let showsDestinationList: Bool
    
    /// `TextField`の初回フォーカス時に高さが変わる問題に対処するために使用する。
    @ScaledMetric(relativeTo: .body) var singleLineTextFieldHeight = 22.0
    
    let notesTextFieldPlaceholder = """
    - モンステラは粒状肥料
    - ポトスは薄めた液体肥料
    - サンスベリアは未使用でOK
    """
    let labelToContentSpacing: CGFloat = 12
    let betweenDividerAndContentSpacing: CGFloat = 18
    let betweenDividerAndTextFieldSpacing: CGFloat = 8
    let borderWidth: CGFloat = 1.0
    
    func presentCalendarInput() {
        focus.wrappedValue = nil
        if let convertedDeadline = japaneseDateConverter.convert(from: draft.deadline) {
            calendarDeadline = convertedDeadline
        }
        updateDeadlineFromCalendar()
        withAnimation { isCalendarPresented = true }
    }
    
    func presentTextDeadlineInput() {
        withAnimation { isCalendarPresented = false }
    }
    
    func updateDeadlineFromCalendar() {
        draft.deadline = ReminderDeadlineFormatter.string(from: calendarDeadline, includesTime: true)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .zero) {
                titleSection
                
                formDivider
                    .padding(.top, betweenDividerAndTextFieldSpacing)
                    .padding(.bottom, betweenDividerAndContentSpacing)
                
                if showsDeadline {
                    deadlineSection
                    
                    formDivider
                        .padding(.top, betweenDividerAndTextFieldSpacing)
                        .padding(.bottom, betweenDividerAndContentSpacing)
                }
                
                notesSection
                
                formDivider
                    .padding(.top, betweenDividerAndContentSpacing)
                    .padding(.bottom, betweenDividerAndContentSpacing)

                if showsDestinationList {
                    destinationListSection

                    formDivider
                        .padding(.top, betweenDividerAndContentSpacing)
                        .padding(.bottom, betweenDividerAndContentSpacing)
                }

                prioritySection
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .contentMargins(.horizontal, 20)
        .contentMargins(.top, 18)
        .contentMargins(.bottom, 12)
        .onChange(of: calendarDeadline, updateDeadlineFromCalendar)
    }
    
    var titleSection: some View {
        section(label: "件名", systemImage: "checklist") {
            TextField("観葉植物に肥料を追加する", text: $draft.title)
                .frame(height: singleLineTextFieldHeight)
                .focused(focus, equals: .title)
        }
    }
    
    var deadlineSection: some View {
        section(label: "期限", systemImage: "clock") {
            if isCalendarPresented == false {
                deadlineTextInput
            } else {
                deadlineCalendarInput
            }
        }
    }

    var destinationListSection: some View {
        section(label: "作成先", systemImage: "list.bullet") {
            Picker("作成先", selection: $destinationListID) {
                ForEach(destinationLists) { list in
                    Text(list.title).tag(Optional(list.id))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(.primary)
        }
    }
    
    var deadlineTextInput: some View {
        HStack(spacing: 5) {
            TextField("来月15日の昼", text: $draft.deadline)
                .frame(height: singleLineTextFieldHeight)
                .focused(focus, equals: .deadline)
            
            Button(action: presentCalendarInput) {
                Image(systemName: "calendar")
                    .resizable()
                    .scaledToFit()
                    .padding(.vertical, 1)
                    .padding(.trailing, 2)
                    .frame(height: singleLineTextFieldHeight)
            }
            .buttonStyle(.plain)
        }
    }
    
    var deadlineCalendarInput: some View {
        let bgColor = colorScheme == .light ? AnyShapeStyle(.background.opacity(0.75)) : AnyShapeStyle(Color(red: 0.15, green: 0.15, blue: 0.15))
        
        return VStack(alignment: .trailing, spacing: 12) {
            DatePicker(
                "期限", selection: $calendarDeadline, displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal, 8)
            .background(bgColor, in: .rect(cornerRadius: 12))
            
            Button("テキストで期限を設定", action: presentTextDeadlineInput)
                .font(.callout)
        }
        .padding(.bottom, 4)
    }
    
    var prioritySection: some View {
        section(label: "優先度", systemImage: "flag") {
            HStack(spacing: 8) {
                ForEach(Reminder.Priority.allCases) { priority in
                    priorityButton(priority)
                }
            }
        }
    }
    
    var notesSection: some View {
        section(label: "備考", systemImage: "text.alignleft") {
            TextField(
                "備考",
                text: $draft.notes,
                prompt: Text(notesTextFieldPlaceholder),
                axis: .vertical
            )
            .lineLimit(6...30)
            .focused(focus, equals: .notes)
            .padding(10)
            .overlay(borderColor, in: .rect(cornerRadius: 8).stroke(lineWidth: borderWidth))
        }
    }
    
    func section<Content: View>(label: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: labelToContentSpacing) {
            Label(label, systemImage: systemImage)
                .font(.footnote)
                .foregroundStyle(labelTextColor)
            content()
        }
    }
    
    var formDivider: some View {
        Rectangle()
            .fill(borderColor)
            .frame(height: borderWidth)
    }
    
    func priorityButton(_ priority: Reminder.Priority) -> some View {
        Button {
            draft.priority = priority
        } label: {
            Text(priority.displayName)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .foregroundStyle(draft.priority == priority ? .white : .primary)
                .background(draft.priority == priority ? .secondary : colorScheme == .light ? .quinary : .quaternary, in: .capsule)
        }
        .foregroundStyle(.primary)
    }
    
    var labelTextColor: Color {
        let grayLevel = colorScheme == .light ? 0.5 : 0.6
        return Color(red: grayLevel, green: grayLevel, blue: grayLevel)
    }
    
    var borderColor: Color {
        let grayLevel = colorScheme == .light ? 0.8 : 0.3
        return .init(red: grayLevel, green: grayLevel, blue: grayLevel)
    }
}

nonisolated enum ReminderEditorField: CaseIterable, Identifiable {
    case title, deadline, notes
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .title: "件名"
        case .deadline: "期限"
        case .notes: "備考"
        }
    }
}

#Preview("Light・Empty") {
    @Previewable @State var draft = ReminderDraft()
    @Previewable @State var calendarDeadline = Date.now
    @Previewable @FocusState var focus: ReminderEditorField?
    let sampleLists: [ReminderList] = [
        .init(id: "sampleList1", title: "Sample List 1", isDefault: true, reminders: []),
        .init(id: "sampleList2", title: "Sample List 2", isDefault: false, reminders: []),
        .init(id: "sampleList3", title: "Sample List 3", isDefault: false, reminders: []),
    ]
    
    ReminderForm(
        draft: $draft,
        calendarDeadline: $calendarDeadline,
        destinationListID: .constant(sampleLists.first!.id),
        destinationLists: sampleLists,
        japaneseDateConverter: JapaneseDateConverter(),
        focus: $focus,
        showsDeadline: true,
        showsDestinationList: true,
    )
    .preferredColorScheme(.light)
}

#Preview("Dark・Input") {
    @Previewable @State var draft = ReminderDraft(
        title: "観葉植物に肥料を追加する",
        deadline: "来月15日の昼",
        priority: .medium,
        notes: "ポトスには薄めた液体肥料を使用する",
    )
    @Previewable @State var calendarDeadline = Date.now
    @Previewable @FocusState var focus: ReminderEditorField?
    ReminderForm(
        draft: $draft,
        calendarDeadline: $calendarDeadline,
        destinationListID: .constant("assistant"),
        destinationLists: [.init(id: "assistant", title: "Reminder Assistant", isDefault: true, reminders: [])],
        japaneseDateConverter: JapaneseDateConverter(),
        focus: $focus,
        showsDeadline: true,
        showsDestinationList: true,
    )
    .preferredColorScheme(.dark)
}

#Preview("Light・Without deadline") {
    @Previewable @State var draft = ReminderDraft(title: "観葉植物に肥料を追加する")
    @Previewable @State var calendarDeadline = Date.now
    @Previewable @FocusState var focus: ReminderEditorField?
    ReminderForm(
        draft: $draft,
        calendarDeadline: $calendarDeadline,
        destinationListID: .constant(nil),
        destinationLists: [],
        japaneseDateConverter: JapaneseDateConverter(),
        focus: $focus,
        showsDeadline: false,
        showsDestinationList: false,
    )
    .preferredColorScheme(.light)
}
