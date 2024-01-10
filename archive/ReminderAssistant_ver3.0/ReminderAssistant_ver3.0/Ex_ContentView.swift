//
//  Ex_ContentView.swift
//  ReminderAssistant_ver3.0
//
//  Created by Masaki Doi on 2023/02/25.
//

import SwiftUI

extension ContentView {
    
    // リマインダー作成の関数
    func createReminder(title: String, deadline: String) {
        
        // 1. 整形された"deadline_String"の作成する
        let deadline_String = myRegex.getFormattedDeadline(deadline: deadline)
        
        // 2. 整形された"deadline_String"から当てはまる「regex」と「unicode35」探す
        var matchUnicode35 = ""
        myRegex.patterns.forEach { pattern in
            guard (pattern["regex"] != nil) && (pattern["unicode35"] != nil) else { fatalError() }
            if myRegex.matchOrNot(str: deadline_String, regex: pattern["regex"]!) {
                matchUnicode35 = pattern["unicode35"]!
            }
        }
        guard matchUnicode35 != "" else {
            noMatchAlert = true
            return
        }
        
        
        // 3. Date型の期限を作成する
        let deadline_Date = myRegex.getDateFromString(deadline: deadline_String, unicode35: matchUnicode35)
        guard deadline_Date != nil else {
            unknownErrorAlert = true
            return
        }
        
        
        // 4. リマインダーを作成
        guard eventStore.getAuthorizationStatus() else {
            settingAlert = true
            return
        }
        
        eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes, listName: reminderList)
        deadlineOfCreatedReminder = myRegex.getFullDateString(date: deadline_Date!)
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
            showNotificationView = true
        }
        
    }
    
    
    // NotificationViewが非表示になる時の処理
    func actionWhenNotificationViewDisappear() {
        title.removeAll()
        deadline.removeAll()
        notes.removeAll()
        deadlineOfCreatedReminder.removeAll()
        showNotificationView = false
    }
}
