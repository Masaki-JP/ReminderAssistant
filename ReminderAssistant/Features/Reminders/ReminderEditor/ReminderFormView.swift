import SwiftUI
import JapaneseDateConverter
import ReminderCore

struct ReminderFormView: View {
    @State var draft: ReminderDraft
    @State var calendarDeadline: Date
    @State var destinationListID: ReminderList.ID?
    @State var isDismissConfirmationDialogPresented = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var saveTask: Task<Void, Never>? = nil
    var isSaving: Bool { saveTask != nil }
    
    @FocusState var focus: ReminderEditorField?
    var focusBinding: Binding<ReminderEditorField?> {
        .init(get: { focus }, set: { focus = $0 })
    }
    
    var focusFields: [ReminderEditorField] {
        ReminderEditorField.allCases.filter { mode.showsDeadline || $0 != .deadline }
    }
    
    @State var saveError: ReminderEditorError?
    var saveErrorBinding: Binding<Bool> { .init(
        get: { saveError != nil },
        set: { if $0 == false { saveError = nil } }
    ) }
    
    let mode: ReminderEditorMode
    let destinationLists: [ReminderList]
    let initialDraft: ReminderDraft
    let japaneseDateConverter = {
        let jdc = JapaneseDateConverter()
        _ = jdc.convert(from: "test") // warmup
        return jdc
    }()
    let confirmAction: (ReminderDraft) async throws(ReminderEditorError) -> Void
    
    init(
        mode: ReminderEditorMode,
        destinationLists: [ReminderList] = [],
        destinationListID: ReminderList.ID? = nil,
        onConfirm: @escaping (ReminderDraft) async throws(ReminderEditorError) -> Void
    ) {
        self.mode = mode
        self.destinationLists = destinationLists
        let initialDraft = mode.initialDraft
        self.initialDraft = initialDraft
        self._draft = .init(initialValue: initialDraft)
        self._calendarDeadline = .init(initialValue: mode.initialCalendarDeadline)
        self._destinationListID = .init(
            initialValue: destinationListID
                ?? destinationLists.first(where: \.isDefault)?.id
                ?? destinationLists.first?.id
        )
        self.confirmAction = onConfirm
    }
    
    var canDismissWithoutConfirmation: Bool {
        draft == initialDraft
    }
    
    var isConfirmButtonDisabled: Bool {
        isSaving || !mode.canSave(draft, initialDraft: initialDraft)
    }
    
    var body: some View {
        NavigationStack {
            ReminderForm(
                draft: $draft,
                calendarDeadline: $calendarDeadline,
                destinationListID: $destinationListID,
                destinationLists: destinationLists,
                japaneseDateConverter: japaneseDateConverter,
                focus: $focus,
                showsDeadline: mode.showsDeadline,
                showsDestinationList: mode.showsDestinationList
            )
            .disabled(isSaving)
            .navigationTitle(mode.navigationTitle)
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
        .interactiveDismissDisabled(isSaving || !canDismissWithoutConfirmation)
        .alert(mode.errorTitle, isPresented: saveErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            if let saveError { Text(saveError.message) }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.03))
            guard !Task.isCancelled else { return }
            focus = .title
        }
        .onDisappear { saveTask?.cancel() }
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel, action: dismissSheet)
                .disabled(isSaving)
                .confirmationDialog(
                    "現在の入力を破棄して中断しますか？",
                    isPresented: $isDismissConfirmationDialogPresented,
                    titleVisibility: .visible
                ) {
                    Button("破棄して中断", role: .destructive, action: dismiss.callAsFunction)
                }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(role: .confirm, action: saveReminder)
                .accessibilityLabel(mode.confirmButtonTitle)
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
            saveReminderButton
        }
    }
    
    var focusPicker: some View {
        Picker("フォーカス", selection: focusBinding) {
            ForEach(focusFields) { field in
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
    
    var saveReminderButton: some View {
        Button(mode.confirmButtonTitle, systemImage: "checkmark", action: saveReminder)
            .buttonStyle(.glassProminent)
            .labelStyle(.iconOnly)
            .disabled(isConfirmButtonDisabled)
    }
}

extension ReminderFormView {
    func dismissSheet() {
        if canDismissWithoutConfirmation == true {
            dismiss()
        } else {
            isDismissConfirmationDialogPresented = true
        }
    }
    
    func saveReminder() {
        guard isConfirmButtonDisabled == false else { return }
        
        saveTask = .init {
            defer { saveTask = nil }
            
            do {
                try await confirmAction(draft); dismiss()
            } catch let error as ReminderEditorError {
                if case .cancelled = error { return }
                saveError = error
            } catch {
                saveError = .saveFailed
            }
        }
    }
}

#Preview("Light・Create") {
    ReminderFormView(mode: .create, destinationLists: ReminderList.samples) { _ in }
        .preferredColorScheme(.light)
}
#Preview("Dark・Create") {
    ReminderFormView(mode: .create, destinationLists: ReminderList.samples) { _ in }
        .preferredColorScheme(.dark)
}
#Preview("Light・Edit") {
    ReminderFormView(mode: .edit(Reminder.samples[0])) { _ in }.preferredColorScheme(.light)
}
#Preview("Dark・Edit without deadline") {
    ReminderFormView(mode: .edit(.init(id: "preview", title: "観葉植物に肥料を追加する"))) { _ in }
        .preferredColorScheme(.dark)
}
