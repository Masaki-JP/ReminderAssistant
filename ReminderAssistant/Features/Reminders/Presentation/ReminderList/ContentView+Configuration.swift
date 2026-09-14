extension ContentView {
    enum Configuration {
        case production(
            reminderRepository: ReminderRepositoryType = EventKitReminderRepository.shared,
            reminderStoreCache: ReminderStoreCache? = .init(),
            onReminderAccessRevoked: () -> Void,
        )

        case placeholder(reminderRepository: ReminderRepositoryType)
    }
}
