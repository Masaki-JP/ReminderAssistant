import SwiftUI

struct NewReminderCommands: Commands {
    @FocusedValue(\.presentCreateReminderSheetAction) var presentCreateReminderSheetAction
    
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("新規作成") {
                presentCreateReminderSheetAction?()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(presentCreateReminderSheetAction == nil)
        }
    }
}

extension FocusedValues {
    @Entry var presentCreateReminderSheetAction: PresentCreateReminderSheetAction? = nil
}

struct PresentCreateReminderSheetAction {
    let reminderEditorMode: Binding<ReminderEditorMode?>
    
    func callAsFunction() { reminderEditorMode.wrappedValue = .create }
}
