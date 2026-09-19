import Foundation
import ReminderCore

/// `Reminder`のキャッシュ実装
/// （アップデート後のプロパティの変更等によるデコード失敗は許容する。）
actor ReminderStoreCache {
    private static let cacheLifetime: TimeInterval = 24 * 60 * 60 //24h
    private let fileURL: URL?
    
    init(fileManager: FileManager = .default) {
        let applicationSupportURL = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false,
        )
        
        fileURL = applicationSupportURL?
            .appending(path: Bundle.main.bundleIdentifier ?? "EKReminder-260707")
            .appending(path: "ReminderStoreCache.json")
    }
    
    func fetch() -> [ReminderList]? {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path(percentEncoded: false)),
              let cacheModificationDate = attributes[.modificationDate] as? Date,
              cacheModificationDate.addingTimeInterval(Self.cacheLifetime) > .now,
              let editableLists = try? JSONDecoder().decode([ReminderList].self, from: data)
        else {
            return nil
        }
        
        return editableLists
    }
    
    func save(_ editableLists: [ReminderList]) {
        guard let fileURL else { return }
        
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
            )
            
            let data = try JSONEncoder().encode(editableLists)
            try data.write(to: fileURL, options: .atomic)
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: fileURL.path(percentEncoded: false),
            )
        } catch {
            return
        }
    }
}
