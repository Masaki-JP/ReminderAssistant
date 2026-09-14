import SwiftUI
import EventKit

struct ReminderAccessRequestView: View {
    private let eventStore = EKEventStore()
    private let reminderAccessGrantedHandler: () -> Void
    @State var task: Task<Void, Never>? = nil
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.openURL) var openURL: OpenURLAction
    
    init(onReminderAccessGranted: @escaping () -> Void) {
        self.reminderAccessGrantedHandler = onReminderAccessGranted
    }
    
    static let fakeReminderRepository: FakeReminderRepository = {
        let list = ReminderList(
            calendarIdentifier: "xxx",
            title: "xxx",
            isDefault: true,
            reminders: Reminder.placeholders()
        )
        
        return .init(
            editableLists: [list],
            fetchDelay: .zero,
        )
    }()
    
    var body: some View {
        ContentView(configuration: .placeholder(
            reminderRepository: Self.fakeReminderRepository,
        ))
        .overlay {
            contentCover.ignoresSafeArea()
            if task == nil {
                accessRequestPrompt
            }
        }
    }
    
    var contentCover: some View {
        Color(red: 0.1, green: 0.1, blue: 0.1)
            .opacity(0.5)
            .allowsHitTesting(true)
    }
    
    var accessRequestPrompt: some View {
        let bgColor = (colorScheme == .light ? .white : Color(red: 0.2, green: 0.2, blue: 0.2)).opacity(0.7)
        
        return VStack(spacing: 24) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 120))
                .foregroundStyle(.tint)
            
            VStack(spacing: 12) {
                Text("リマインダー情報のアクセス権")
                    .font(.title2.bold())
                
                Text("表示・作成・管理を行うために\nアクセス許可が必要です。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            
            if EKEventStore.authorizationStatus(for: .reminder) == .notDetermined {
                Button("アクセスを許可", action: requestAccess)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
            } else {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Button("設定を開く") { openURL(url) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                } else {
                    Text("（設定アプリからリマインダーへのアクセスを許可してください。）")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .glassEffect(.clear.tint(bgColor), in: .rect(cornerRadius: 40))
    }
    
    func requestAccess() {
        task = Task {
            defer { task = nil }
            
            if (try? await eventStore.requestFullAccessToReminders()) == true {
                reminderAccessGrantedHandler()
            }
        }
    }
}

#Preview("Light") {
    ReminderAccessRequestView(onReminderAccessGranted: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ReminderAccessRequestView(onReminderAccessGranted: {})
        .preferredColorScheme(.dark)
}
