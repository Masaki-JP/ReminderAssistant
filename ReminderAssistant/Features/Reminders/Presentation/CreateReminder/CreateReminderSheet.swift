import SwiftUI

struct CreateReminderSheet: View {
    @State var title = ""
    @State var deadline = ""
    @State var priority: Reminder.Priority = .none
    @State var notes = ""
    @State var isDismissConfirmationDialogPresented = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var creationTask: Task<Void, Never>? = nil
    var isCreating: Bool { creationTask != nil }
    
    @FocusState var focus: CreateReminderField?
    var focusBinding: Binding<CreateReminderField?> {
        .init(get: { focus }, set: { focus = $0 })
    }
    
    @State var creationError: CreateReminderError?
    var creationErrorBinding: Binding<Bool> { .init(
        get: { creationError != nil },
        set: { if $0 == false { creationError = nil } }
    ) }
    
    let confirmAction: (
        _ title: String,
        _ deadline: String,
        _ priority: Reminder.Priority,
        _ notes: String
    ) async throws(CreateReminderError) -> Void
    
    init(
        onConfirm: @escaping (
            _ title: String,
            _ deadline: String,
            _ priority: Reminder.Priority,
            _ notes: String
        ) async throws(CreateReminderError) -> Void
    ) {
        self.confirmAction = onConfirm
    }
    
    var canDismissWithoutConfirmation: Bool {
        title.isEmpty && deadline.isEmpty && notes.isEmpty
    }
    
    var isConfirmButtonDisabled: Bool {
        isCreating
        || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || deadline.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            CreateReminderForm(
                title: $title,
                deadline: $deadline,
                priority: $priority,
                notes: $notes,
                focus: $focus
            )
            .disabled(isCreating)
            .navigationTitle("新規作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) {
                if focus != nil, case .phone = InterfaceIdiom.current {
                    customPhoneKeyboardToolbar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
        }
        .interactiveDismissDisabled(isCreating || !canDismissWithoutConfirmation)
        .alert("作成失敗", isPresented: creationErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            if let creationError {
                Text(creationError.message)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.03))
            focus = .title
        }
        .onDisappear { creationTask?.cancel() }
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel, action: dismissSheet)
                .disabled(isCreating)
                .confirmationDialog(
                    "現在の入力を破棄して中断しますか？",
                    isPresented: $isDismissConfirmationDialogPresented,
                    titleVisibility: .visible
                ) {
                    Button("破棄して中断", role: .destructive, action: dismiss.callAsFunction)
                }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm, action: createReminder)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(isConfirmButtonDisabled)
        }
        
        if case .pad(let isPhysicalKeyboardConnected) = InterfaceIdiom.current,
           isPhysicalKeyboardConnected == false {
            ToolbarItem(placement: .keyboard) { focusPicker }
            ToolbarItem(placement: .keyboard) { dismissKeyboardButton }
        }
    }
    
    var customPhoneKeyboardToolbar: some View {
        HStack(spacing: nil) {
            focusPicker
            dismissKeyboardButton
            createReminderButton
        }
    }
    
    var focusPicker: some View {
        Picker("フォーカス", selection: focusBinding) {
            ForEach(CreateReminderField.allCases) { field in
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
        .glassEffect(.regular.tint(colorScheme == .light ? .clear : .gray))
        .labelStyle(.iconOnly)
    }
    
    var createReminderButton: some View {
        Button("作成", systemImage: "checkmark", action: createReminder)
            .buttonStyle(.glassProminent)
            .labelStyle(.iconOnly)
            .disabled(isConfirmButtonDisabled)
    }
}

extension CreateReminderSheet {
    func dismissSheet() {
        if canDismissWithoutConfirmation == true {
            dismiss()
        } else {
            isDismissConfirmationDialogPresented = true
        }
    }
    
    func createReminder() {
        guard creationTask == nil else { return }
        
        creationTask = .init {
            defer { creationTask = nil }
            
            do {
                try await confirmAction(title, deadline, priority, notes)
                dismiss()
            } catch let error as CreateReminderError {
                if case .cancelled = error { return }
                creationError = error
            } catch {
                creationError = .saveFailed
            }
        }
    }
}

/// リマインダー作成画面で扱うエラー。
enum CreateReminderError: Error {
    case invalidDeadline
    case destinationListUnavailable
    case saveFailed
    case cancelled
}

extension CreateReminderError {
    var message: String {
        switch self {
        case .invalidDeadline:
            "期限を認識できませんでした。入力内容を確認し、もう一度お試しください。"
        case .destinationListUnavailable:
            "作成先のリストを利用できません。設定画面で作成先を選択してください。"
        case .saveFailed:
            "新規リマインダーの保存に失敗しました。もう一度お試しください。"
        case .cancelled:
            ""
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
