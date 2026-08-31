import SwiftUI

@main
struct EKReminder_260707App: App {
    @AppStorage("colorScheme") var colorSchemeSetting = ColorSchemeSetting.defaultValue
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorSchemeSetting.colorScheme)
        }
    }
}
