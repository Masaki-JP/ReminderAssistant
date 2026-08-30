import EventKit

nonisolated
extension EKReminder {
    var reminder: RAReminder? {
        let calendarItemIdentifier = self.calendarItemIdentifier
        let calendar = self.calendar
        let title = self.title
        let creationDate = self.creationDate
        let lastModifiedDate = self.lastModifiedDate
        let completionDate = self.completionDate
        
        /// カレンダー項目IDとタイトルが有効であることを確認する。
        guard let calendar,
              calendar.calendarIdentifier.isEmpty == false,
              calendar.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              let title,
              calendarItemIdentifier.isEmpty == false,
              title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return nil
        }
        
        if let dueDateComponents {
            /// 期日に年月日が指定され、実際に日付へ変換できることを確認する。
            guard dueDateComponents.year != nil,
                  dueDateComponents.month != nil,
                  dueDateComponents.day != nil,
                  RAReminder.dueDate(from: dueDateComponents) != nil else {
                return nil
            }
        }
        
        /// EventKitの優先度がアプリで扱える値であることを確認する。
        guard let priority = RAReminder.Priority(ekReminderPriority: self.priority) else {
            return nil
        }
        
        /// 完了状態と完了日時が整合していることを確認する。
        guard self.isCompleted == (completionDate != nil) else {
            return nil
        }
        
        /// 作成日時が最終更新日時より後になっていないことを確認する。
        if let creationDate, let lastModifiedDate,
           creationDate > lastModifiedDate {
            return nil
        }
        
        if let completionDate {
            /// 完了日時が作成日時より前になっていないことを確認する。
            if let creationDate, creationDate > completionDate {
                return nil
            }
            
            /// 完了日時が最終更新日時より後になっていないことを確認する。
            if let lastModifiedDate, completionDate > lastModifiedDate {
                return nil
            }
        }
        
        return RAReminder(
            calendarItemIdentifier: calendarItemIdentifier,
            list: .init(
                calendarIdentifier: calendar.calendarIdentifier,
                title: calendar.title
            ),
            title: title,
            dueDateComponents: dueDateComponents,
            priority: priority,
            notes: self.notes,
            isCompleted: self.isCompleted,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate,
            completionDate: completionDate
        )
    }
}
