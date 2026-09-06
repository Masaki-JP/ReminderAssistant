import Foundation

extension UserDefaultsKey {
    /// rawValue は @AppStorage のキー文字列として使用される。
    ///
    enum AppStorageKey: String {
        case colorScheme
        case hasInitializedReminderDestinationList
        case lastSelectedListID
        case reminderDestinationListID
    }
    
    enum AppStorageDefaultValue {
        static let hasInitializedReminderDestinationList = false
    }
}
