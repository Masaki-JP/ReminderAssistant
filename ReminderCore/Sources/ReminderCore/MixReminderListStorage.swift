public import Foundation

nonisolated public enum MixReminderListStorageError: Error, Sendable {
    case encodingFailed
    case invalidData
    case unsupportedVersion(Int)
}

/// `MixReminderList`の保存形式を管理する。
nonisolated public enum MixReminderListStorage {
    private static let currentVersion = 1

    private struct VersionHeader: Decodable {
        let version: Int
    }

    private struct Version1Document: Codable {
        let version: Int
        let lists: [MixReminderList]
    }

    public static func encode(
        _ lists: [MixReminderList]
    ) throws(MixReminderListStorageError) -> Data {
        do {
            return try JSONEncoder().encode(Version1Document(version: currentVersion, lists: lists))
        } catch {
            throw .encodingFailed
        }
    }

    public static func decode(
        _ data: Data
    ) throws(MixReminderListStorageError) -> [MixReminderList] {
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
