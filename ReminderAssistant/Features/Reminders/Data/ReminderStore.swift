import EventKit
import JapaneseDateConverter

/// Actorの選定理由
/// - オブザーバートークンを保持するため、参照型である必要がある。
/// - メインスレッドへの負担は避けたい。（リマインダーの作成でも0.07秒ほど要する）
///
///
/// オペレーションについて
/// アクターはサスペンド中に再入可能なため、取得の実行中に作成か更新が呼ばれる可能性がある。
/// 実際に試したところ問題は生じなかったが、念の為に同時操作を防ぐために直列化を実装した。

///
///
/// 主な操作の実行時間（iPhone 17で測定）
/// - 作成：約0.07秒
/// - 更新：約0.1秒
/// - 取得：約0.8秒（初回は約2.0秒）
///
final actor ReminderStore: ReminderStoreProtocol {
    static let shared = ReminderStore()
    nonisolated let remindersMayHaveChanged: Notification.Name
    
    private let eventStore: EKEventStore
    private var token: NotificationCenter.ObservationToken
    
    private init() {
        let remindersMayHaveChanged = Notification.Name("remindersMayHaveChanged")
        self.remindersMayHaveChanged = remindersMayHaveChanged
        
        let eventStore = EKEventStore()
        self.eventStore = eventStore
        
        token = NotificationCenter.default.addObserver(of: eventStore, for: .changed) { _ in
            NotificationCenter.default.post(name: remindersMayHaveChanged, object: nil)
        }
    }
    
    deinit { NotificationCenter.default.removeObserver(token) }
    
    func create(
        title: String,
        deadline: String,
        priority: Reminder.Priority,
        notes: String,
        list: ReminderList,
    ) async throws(ReminderStoreError) {
        try await operation(priority: .medium) { () async throws(ReminderStoreError) -> Void in
            guard let calendar = eventStore.calendar(withIdentifier: list.calendarIdentifier) else {
                throw .listNotFound(calendarIdentifier: list.calendarIdentifier)
            }
            
            let dueDateCalendar = Calendar.gregorianCalendar()
            let dueDate = JapaneseDateConverter().convert(from: deadline).map {
                dueDateCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: $0)
            }
            try checkAuthorization()
            try checkCancel()
            guard let dueDate else { throw .deadlineConversionFailed }
            
            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = title
            reminder.dueDateComponents = dueDate
            reminder.startDateComponents = nil
            reminder.addAlarm(.init(relativeOffset: 0))
            reminder.priority = priority.ekReminderPriority
            reminder.notes = notes
            reminder.calendar = calendar
            
            try save(reminder)
        }
    }
    
    func set(id: String, completion: Bool) async throws(ReminderStoreError) {
        try await operation(priority: .medium) { () async throws(ReminderStoreError) -> Void in
            guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
                throw .reminderNotFound(calendarItemIdentifier: id)
            }
            
            reminder.isCompleted = completion
            try save(reminder)
        }
    }
    
    private typealias RemindersByCalendarIdentifier = [String: [Reminder]]
    
    func fetch() async throws(ReminderStoreError) -> [ReminderList] {
        try await operation(priority: .low) { () async throws(ReminderStoreError) -> [ReminderList] in
            let editableCalendars: [EKCalendar] = eventStore.calendars(for: .reminder)
                .filter(\.allowsContentModifications)
            
            let result = await fetchReminders(in: editableCalendars)
            try checkAuthorization()
            try checkCancel()
            
            switch result {
            case .success(let remindersByCalendarIdentifier):
                let defaultListIdentifier = eventStore.defaultCalendarForNewReminders()?.calendarIdentifier
                
                return editableCalendars.map { calendar in
                        .init(
                            calendarIdentifier: calendar.calendarIdentifier,
                            title: calendar.title,
                            isDefault: calendar.calendarIdentifier == defaultListIdentifier,
                            reminders: remindersByCalendarIdentifier[calendar.calendarIdentifier] ?? []
                        )
                }
            case .failure(let error): throw error
            }
        }
    }
    
    private func fetchReminders(
        in calendars: [EKCalendar]
    ) async -> Result<RemindersByCalendarIdentifier, ReminderStoreError> {
        await withCheckedContinuation { continuation in
            let predicate = eventStore.predicateForReminders(in: calendars)
            
            eventStore.fetchReminders(matching: predicate) { reminders in
                let result: Result<RemindersByCalendarIdentifier, ReminderStoreError> = if let reminders {
                    .success(reminders.reduce(into: RemindersByCalendarIdentifier()) { lists, ekReminder in
                        guard let reminder = ekReminder.reminder,
                              let calendarIdentifier = ekReminder.calendar?.calendarIdentifier else { return }
                        lists[calendarIdentifier, default: []].append(reminder)
                    })
                } else {
                    .failure(.fetchFailed)
                }
                
                continuation.resume(returning: result)
            }
        }
    }
    
    private func checkCancel() throws(ReminderStoreError) {
        do {
            try Task.checkCancellation()
        } catch {
            throw .cancelled
        }
    }
    
    private func checkAuthorization() throws(ReminderStoreError) {
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
            throw .accessNotAuthorized
        }
    }
    
    private func save(_ reminder: EKReminder) throws(ReminderStoreError) {
        do {
            try eventStore.save(reminder, commit: true)
        } catch let error as EKError where error.code == .eventStoreNotAuthorized {
            throw .accessNotAuthorized
        } catch {
            throw .saveFailed
        }
    }
    
    // MARK: - Operation
    
    /// operation の action 内から、operation を使用する別メソッドを呼ばない。
    /// 内側の operation は外側が保持しているロックの解放を待つが、外側の operation は内側の処理の完了を待つため、互いに待機してデッドロックする。
    @discardableResult
    private func operation<T>(
        priority: OperationPriority,
        action: () async throws(ReminderStoreError) -> T
    ) async throws(ReminderStoreError) -> T {
        await acquireOperation(priority: priority)
        defer { releaseOperation() }
        try checkAuthorization()
        try checkCancel()
        return try await action()
    }
    
    private enum OperationPriority {
        case high, medium, low
    }
    
    private var isOperating = false
    private var highPriorityWaiters: [CheckedContinuation<Void, Never>] = []
    private var mediumPriorityWaiters: [CheckedContinuation<Void, Never>] = []
    private var lowPriorityWaiters: [CheckedContinuation<Void, Never>] = []
    
    private func acquireOperation(priority: OperationPriority) async {
        if isOperating == false {
            isOperating = true
        } else {
            await withCheckedContinuation { continuation in
                switch priority {
                case .high:
                    highPriorityWaiters.append(continuation)
                case .medium:
                    mediumPriorityWaiters.append(continuation)
                case .low:
                    lowPriorityWaiters.append(continuation)
                }
            }
        }
    }
    
    private func releaseOperation() {
        if highPriorityWaiters.isEmpty == false {
            highPriorityWaiters.removeFirst().resume()
        } else if mediumPriorityWaiters.isEmpty == false {
            mediumPriorityWaiters.removeFirst().resume()
        } else if lowPriorityWaiters.isEmpty == false {
            lowPriorityWaiters.removeFirst().resume()
        } else {
            isOperating = false
        }
    }
}
