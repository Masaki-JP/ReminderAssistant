import SwiftUI

struct NewReminderCommands: Commands {
    @FocusedValue(\.newReminderAction) var newReminderAction
    
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("新規作成") {
                newReminderAction?()
            }
            .keyboardShortcut("n", modifiers: .command)
            .disabled(newReminderAction == nil)
        }
    }
}

extension FocusedValues {
    @Entry var newReminderAction: (() -> Void)? = nil
}
