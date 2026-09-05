import SwiftUI
import EventKit

struct RootView: View {
    @State private var isReminderAccessGranted = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    
    var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    var body: some View {
        Group {
            if isReminderAccessGranted == true {
                ContentView(configuration: .production(
                    onReminderAccessRevoked: { isReminderAccessGranted = false }
                ))
            } else {
                ReminderAccessRequestView(
                    onReminderAccessGranted: { isReminderAccessGranted = true }
                )
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            
            if isPreview == true {
                isReminderAccessGranted = false
            } else {
                isReminderAccessGranted = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
            }
        }
    }
}

#Preview("Light") { RootView().preferredColorScheme(.light) }
#Preview("Dark") { RootView().preferredColorScheme(.dark) }
