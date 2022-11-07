//
//  Class_EventStore.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/10/11.
//

import Foundation
import EventKit




// EventStoreクラスの定義
final class EventStore {

    // 初期化
    let store: EKEventStore
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

    // 新規リマインダーを作成
    func createReminder(title: String, deadLine: Date, listName: String) -> Void {
        let newReminder: EKReminder = EKReminder(eventStore: store)
        newReminder.title = title


        if isListExist(list: listName) {
            store.calendars(for: .reminder).forEach { list in
                if listName == list.title {
                    newReminder.calendar = list
                }
            }
        } else {
            newReminder.calendar = store.defaultCalendarForNewReminders()
        }




        let alarm = EKAlarm(absoluteDate: deadLine)
        newReminder.addAlarm(alarm)
        newReminder.dueDateComponents = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(identifier: "Asia/Tokyo")!, from: deadLine)
        // このプロパティを設定しておかなければ、期限切れのリマインダーとしてショートカットは認識してくれない。
        do {
            try store.save(newReminder, commit: true)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}




extension EventStore {

    // リマインダーリストを取得
    func getLists() -> [String] {
        var lists = [] as [String]
        self.store.calendars(for: .reminder).forEach { list in
            lists.append(list.title)
        }
        print(lists)
        return lists
    }

    // リストが存在するか確認
    func isListExist(list: String) -> Bool {
        var isExist = false
        self.store.calendars(for: .reminder).forEach { calendar in
            if list == calendar.title {
                isExist = true
            }
        }
        return isExist
    }
}
