import Foundation

actor ReminderStoreCache {
    private struct StoredValue: Codable {
        let version: Int
        let cachedAt: Date
        let result: ReminderStoreFetchResult
    }

    private static let currentVersion = 2
    private static let cacheLifetime: TimeInterval = 24 * 60 * 60
    private let fileURL: URL?

    static let shared = ReminderStoreCache()

    init(fileManager: FileManager = .default) {
        let applicationSupportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        fileURL = applicationSupportURL?
            .appending(path: Bundle.main.bundleIdentifier ?? "EKReminder-260707")
            .appending(path: "ReminderStoreCache.json")
    }

    func fetch() -> ReminderStoreFetchResult? {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let storedValue = try? JSONDecoder().decode(StoredValue.self, from: data),
              storedValue.version == Self.currentVersion,
              storedValue.cachedAt.addingTimeInterval(Self.cacheLifetime) > .now
        else {
            return nil
        }

        return storedValue.result
    }

    func save(_ result: ReminderStoreFetchResult) {
        guard let fileURL else { return }

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let storedValue = StoredValue(
                version: Self.currentVersion,
                cachedAt: .now,
                result: result
            )
            let data = try JSONEncoder().encode(storedValue)
            try data.write(to: fileURL, options: .atomic)
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: fileURL.path()
            )
        } catch {
            return
        }
    }
}
