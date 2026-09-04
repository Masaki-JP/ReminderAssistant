import SwiftUI

@main
struct ReminderAssistantApp: App {
    @AppStorage("colorScheme") var colorSchemeSetting = ColorSchemeSetting.defaultValue
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(colorSchemeSetting.colorScheme)
        }
    }
}
