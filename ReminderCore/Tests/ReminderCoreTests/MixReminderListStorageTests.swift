import Foundation
import ReminderCore
import Testing

struct MixReminderListStorageTests {
    @Test("保存したミックスリストを元の値に復元する")
    func encodeThenDecodePreservesLists() throws {
        let lists = [
            MixReminderList(title: "仕事", listIDs: ["work", "shared"]),
            MixReminderList(title: "自宅", listIDs: ["home", "shared"]),
        ]

        let data = try MixReminderListStorage.encode(lists)

        #expect(try MixReminderListStorage.decode(data) == lists)
    }

    @Test("空データはミックスリストなしとして復元する")
    func emptyDataDecodesAsNoLists() throws {
        #expect(try MixReminderListStorage.decode(Data()) == [])
    }

    @Test("不正なJSONや不完全なドキュメントを拒否する")
    func invalidDocumentsThrowInvalidData() {
        expectDecodeError(Data("{".utf8), isInvalidData: true)
        expectDecodeError(Data(#"{"version":1}"#.utf8), isInvalidData: true)
    }

    @Test("未対応の保存形式バージョンを報告する")
    func unsupportedVersionIsReported() {
        let data = Data(#"{"version":42,"lists":[]}"#.utf8)

        do {
            _ = try MixReminderListStorage.decode(data)
            Issue.record("未対応バージョンのデータを拒否しませんでした")
        } catch {
            if case .unsupportedVersion(42) = error {
                return
            } else {
                Issue.record("想定外の保存エラー: \(error)")
            }
        }
    }

    private func expectDecodeError(_ data: Data, isInvalidData: Bool) {
        do {
            _ = try MixReminderListStorage.decode(data)
            Issue.record("不正なデータを拒否しませんでした")
        } catch {
            if isInvalidData, case .invalidData = error {
                return
            } else {
                Issue.record("想定外の保存エラー: \(error)")
            }
        }
    }
}
