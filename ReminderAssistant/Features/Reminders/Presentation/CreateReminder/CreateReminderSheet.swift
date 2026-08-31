import SwiftUI

struct CreateReminderSheet: View {
    @State var title = ""
    @State var deadline = ""
    @State var priority: RAReminder.Priority = .none
    @State var notes = ""
    @State var isDismissConfirmationDialogPresented = false
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @ScaledMetric(relativeTo: .body) var singleLineTextFieldHight = 22.0
    
    @FocusState var focus: Field?
    var focusBinding: Binding<Field?> {
        .init(get: { focus }, set: { focus = $0 })
    }
    
    let confirmAction: (_ title: String, _ deadline: String, _ priority: RAReminder.Priority, _ notes: String) -> Void
    
    init(onConfirm: @escaping (_ title: String, _ deadline: String, _ priority: RAReminder.Priority, _ notes: String) -> Void) {
        self.confirmAction = onConfirm
    }
    
    var canDismissWithoutConfirmation: Bool {
        title.isEmpty && deadline.isEmpty && notes.isEmpty
    }
    
    var isConfirmButtonDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || deadline.isEmpty
    }
    
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    let notesTextFiledPlaceholder = """
    - モンステラは粒状肥料
    - ポトスは薄めた液体肥料
    - サンスベリアは未使用でOK
    """
    
    let labelToContentSpacing: CGFloat = 12
    let betweenDividerAndContentSpacing: CGFloat = 18
    let betweenDividerAndTextFieldSpacing: CGFloat = 8
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .zero) {
                    titleSection
                    
                    formDivider
                        .padding(.top, betweenDividerAndTextFieldSpacing)
                        .padding(.bottom, betweenDividerAndContentSpacing)
                    
                    deadlineSection
                    
                    formDivider
                        .padding(.top, betweenDividerAndTextFieldSpacing)
                        .padding(.bottom, betweenDividerAndContentSpacing)
                    
                    prioritySection
                    
                    formDivider
                        .padding(.top, betweenDividerAndContentSpacing)
                        .padding(.bottom, betweenDividerAndContentSpacing)
                    
                    notesSection
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 20)
            .contentMargins(.top, 18)
            .contentMargins(.bottom, 12)
            .navigationTitle("新規作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) {
                if isPad == false, focus != nil {
                    customKeyboardToolbar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
        }
        .interactiveDismissDisabled(!canDismissWithoutConfirmation)
        .task {
            try? await Task.sleep(for: .seconds(0.03))
            focus = .title
        }
    }
    
    var titleSection: some View {
        section(label: "件名", systemImage: "checklist") {
            TextField("観葉植物に肥料を追加する", text: $title)
                .frame(height: singleLineTextFieldHight)
                .focused($focus, equals: .title)
        }
    }
    
    var deadlineSection: some View {
        section(label: "期限", systemImage: "clock") {
            TextField("来月15日の昼", text: $deadline)
                .frame(height: singleLineTextFieldHight)
                .focused($focus, equals: .deadline)
        }
    }
    
    var prioritySection: some View {
        section(label: "優先度", systemImage: "flag") {
            HStack(spacing: 8) {
                ForEach(RAReminder.Priority.allCases) { priority in
                    priorityButton(priority)
                }
            }
        }
    }
    
    var notesSection: some View {
        section(label: "備考", systemImage: "text.alignleft") {
            TextField(
                "備考",
                text: $notes,
                prompt: Text(notesTextFiledPlaceholder),
                axis: .vertical
            )
            .lineLimit(6...30)
            .focused($focus, equals: .notes)
            .padding(10)
            .overlay(.secondary.opacity(0.35), in: .rect(cornerRadius: 8).stroke(lineWidth: 0.8))
        }
    }
    
    func section<Content: View>(label: String, systemImage: String, content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: labelToContentSpacing) {
            Label(label, systemImage: systemImage)
                .font(.footnote)
                .foregroundStyle(.secondary)
            content()
        }
    }
    
    var formDivider: some View {
        Rectangle()
            .fill(.secondary.opacity(0.35))
            .frame(height: 0.8)
    }
    
    func priorityButton(_ priority: RAReminder.Priority) -> some View {
        Button {
            self.priority = priority
        } label: {
            Text(priority.displayName)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .foregroundStyle(self.priority == priority ? .white : .primary)
                .background(self.priority == priority ? .secondary : colorScheme == .light ? .quinary : .quaternary, in: .capsule)
        }
        .foregroundStyle(.primary)
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel, action: dismissSheet)
                .confirmationDialog(
                    "現在の入力を破棄して中断しますか？",
                    isPresented: $isDismissConfirmationDialogPresented,
                    titleVisibility: .visible
                ) {
                    Button("破棄して中断", role: .destructive, action: dismiss.callAsFunction)
                }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm) {
                confirmAction(title, deadline, priority, notes)
                dismiss()
            }
            .disabled(isConfirmButtonDisabled)
        }
        
        if isPad == true {
            ToolbarItem(placement: .keyboard) { focusPicker }
            ToolbarItem(placement: .keyboard) { dismissKeyboardButton }
        }
    }
    
    var customKeyboardToolbar: some View {
        HStack(spacing: nil) {
            focusPicker
            dismissKeyboardButton
        }
    }
    
    var focusPicker: some View {
        Picker("フォーカス", selection: focusBinding) {
            ForEach(Field.allCases) { field in
                Text(field.displayName).tag(field)
            }
        }
        .pickerStyle(.segmented)
    }
    
    var dismissKeyboardButton: some View {
        Button("完了", systemImage: "keyboard.chevron.compact.down") {
            focus = nil
        }
        .buttonStyle(.glass)
        .labelStyle(.iconOnly)
    }
}

extension CreateReminderSheet {
    enum Field: CaseIterable, Identifiable {
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
    
    func dismissSheet() {
        if canDismissWithoutConfirmation == true {
            dismiss()
        } else {
            isDismissConfirmationDialogPresented = true
        }
    }
}

#Preview("Light") {
    CreateReminderSheet { (_, _, _, _) in }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    CreateReminderSheet { (_, _, _, _) in }
        .preferredColorScheme(.dark)
}
