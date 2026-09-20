public import Foundation

nonisolated public enum CustomReminderListStorageError: Error, Sendable {
    case encodingFailed
    case invalidData
    case unsupportedVersion(Int)
}

/// `CustomReminderList`の保存形式を管理する。
nonisolated public enum CustomReminderListStorage {
    private static let currentVersion = 1

    private struct VersionHeader: Decodable {
        let version: Int
    }

    private struct Version1Document: Codable {
        let version: Int
        let lists: [CustomReminderList]
    }

    public static func encode(
        _ lists: [CustomReminderList]
    ) throws(CustomReminderListStorageError) -> Data {
        do {
            return try JSONEncoder().encode(Version1Document(version: currentVersion, lists: lists))
        } catch {
            throw .encodingFailed
        }
    }

    public static func decode(
        _ data: Data
    ) throws(CustomReminderListStorageError) -> [CustomReminderList] {
        guard data.isEmpty == false else {
            return []
        }

        let decoder = JSONDecoder()

        guard let header = try? decoder.decode(VersionHeader.self, from: data) else {
            throw .invalidData
        }

        switch header.version {
        case 1:
            do {
                return try decoder.decode(Version1Document.self, from: data).lists
            } catch {
                throw .invalidData
            }
        default:
            throw .unsupportedVersion(header.version)
        }
    }
}
