import SwiftUI
import ReminderCore

struct ReminderForm: View {
    @State var isCalendarPresented = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Binding var draft: ReminderDraft
    var focus: FocusState<ReminderEditorField?>.Binding
    let showsDeadline: Bool
    
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
    
    var labelTextColor: Color {
        let grayLevel = colorScheme == .light ? 0.5 : 0.6
        return Color(red: grayLevel, green: grayLevel, blue: grayLevel)
    }
    
    var borderColor: Color {
        let grayLevel = colorScheme == .light ? 0.8 : 0.3
        return .init(red: grayLevel, green: grayLevel, blue: grayLevel)
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
                
                prioritySection
                
                formDivider
                    .padding(.top, betweenDividerAndContentSpacing)
                    .padding(.bottom, betweenDividerAndContentSpacing)
                
                notesSection
            }
        }
        .scrollIndicators(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .contentMargins(.horizontal, 20)
        .contentMargins(.top, 18)
        .contentMargins(.bottom, 12)
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
    
    var deadlineTextInput: some View {
        HStack(spacing: 5) {
            TextField("来月15日の昼", text: $draft.deadline)
                .frame(height: singleLineTextFieldHeight)
                .focused(focus, equals: .deadline)
            
            Button {
                withAnimation { isCalendarPresented = true }
            } label: {
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
                "期限", selection: .constant(.now), displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal, 8)
            .padding(.bottom, -24)
            .background(bgColor, in: .rect(cornerRadius: 12))
            
            Button("テキストで期限を設定") {
                withAnimation { isCalendarPresented = false }
            }
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
    @Previewable @FocusState var focus: ReminderEditorField?
    ReminderForm(draft: $draft, focus: $focus, showsDeadline: true).preferredColorScheme(.light)
}

#Preview("Dark・Input") {
    @Previewable @State var draft = ReminderDraft(
        title: "観葉植物に肥料を追加する",
        deadline: "来月15日の昼",
        priority: .medium,
        notes: "ポトスには薄めた液体肥料を使用する",
    )
    @Previewable @FocusState var focus: ReminderEditorField?
    ReminderForm(draft: $draft, focus: $focus, showsDeadline: true).preferredColorScheme(.dark)
}

#Preview("Light・Without deadline") {
    @Previewable @State var draft = ReminderDraft(title: "観葉植物に肥料を追加する")
    @Previewable @FocusState var focus: ReminderEditorField?
    ReminderForm(draft: $draft, focus: $focus, showsDeadline: false).preferredColorScheme(.light)
}
