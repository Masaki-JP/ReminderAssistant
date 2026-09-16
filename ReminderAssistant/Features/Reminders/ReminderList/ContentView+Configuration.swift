import ReminderEventKit

extension ContentView {
    enum Configuration {
        case production(
            reminderRepository: ReminderRepositoryType = ReminderRepository.shared,
            reminderStoreCache: ReminderStoreCache? = .init(),
            onReminderAccessRevoked: () -> Void,
        )
        
        // ReminderAccessRequestViewで、実データにアクセスせずに表示するための構成。
        case placeholder(reminderRepository: ReminderRepositoryType)
    }
}
