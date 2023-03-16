//
//  Ex_ContentView.swift
//  MacApp
//
//  Created by Masaki Doi on 2023/03/15.
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
            if myRegex.matchOrNot(dateString: deadline_String, regex: pattern["regex"]!) {
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
            showSettingAlert = true
            return
        }
        
        let notes = ""
        
        eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes, listName: reminderListForNewReminder)
        deadlineOfCreatedReminder = myRegex.getFullDateString(date: deadline_Date!)
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
            showCompletionAlert = true
        }
        
    }
    
}
