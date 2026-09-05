extension ContentView {
    enum Configuration {
        case production(
            reminderStore: ReminderStoreType = ReminderStore.shared,
            reminderStoreCache: ReminderStoreCache? = .init(),
            onReminderAccessRevoked: () -> Void,
        )

        case accessRequestPreview(reminderStore: ReminderStoreType)
    }
}
