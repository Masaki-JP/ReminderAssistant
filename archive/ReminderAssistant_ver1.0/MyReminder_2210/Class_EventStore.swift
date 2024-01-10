//
//  Class_EventStore.swift
//  MyReminder_2210
//
//  Created by 土井正貴 on 2022/10/05.
//
import Foundation
import EventKit










// EventStoreクラスの定義
final class EventStore {
    // 初期化
    private let store: EKEventStore
    init() {
        store = EKEventStore()
    }
    // リマインダーへのアクセス許可の要求
    func requestAccess() async -> Void {
        do {
            try await store.requestAccess(to: .reminder)
        } catch {
            print(error.localizedDescription)
        }
    }
    // リマインダーへのアクセスが許可されているか確認
    func getAuthorizationStatus() -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        if status == .authorized {
            return true
        } else {
            return false
        }
    }
    // 新規リマインダーを保存
    func saveNewReminder(newReminder: EKReminder) {
        do {
            try store.save(newReminder, commit: true)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}










// EventStoreクラスの拡張
extension EventStore {

    // 新規リマインダーを作成し保存
    func createReminder(title: String,deadLine: Date) {

        // EKReminderのインスタンスを作成
        let newReminder: EKReminder = EKReminder(eventStore: store)
        // リマインダーのタイトルを設定
        newReminder.title = title
        // リマインダーを追加するリストを設定
        newReminder.calendar = store.defaultCalendarForNewReminders()
        // リマインダーの期限の設定
        let alarm = EKAlarm(absoluteDate: deadLine)
        newReminder.addAlarm(alarm)
        // リマインダーを保存
        saveNewReminder(newReminder: newReminder)

    }
}
