import SwiftUI

@main
struct ReminderAssistantApp: App {
    @AppStorage(UserDefaultsKey.AppStorageKey.colorScheme.rawValue)
    var colorSchemeSetting = ColorSchemeSetting.defaultValue
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(colorSchemeSetting.colorScheme)
        }
    }
}
