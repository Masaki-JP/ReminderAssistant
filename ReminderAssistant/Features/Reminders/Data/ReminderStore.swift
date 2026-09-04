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
    private let eventStore: EKEventStore
    private var token: NotificationCenter.ObservationToken
    
    static let shared = ReminderStore()
    static let remindersMayHaveChanged = Notification.Name("remindersMayHaveChanged")
    
    nonisolated var remindersMayHaveChangedNotification: Notification.Name {
        Self.remindersMayHaveChanged
    }
    
    private init() {
        let eventStore = EKEventStore()
        self.eventStore = eventStore
        
        token = NotificationCenter.default.addObserver(of: eventStore, for: .changed) { _ in
            NotificationCenter.default.post(name: Self.remindersMayHaveChanged, object: nil)
        }
    }
    
    deinit { NotificationCenter.default.removeObserver(token) }
    
    func create(_ request: CreateReminderRequest) async throws(ReminderStoreError) {
        try await operation(priority: .normal) { () async throws(ReminderStoreError) -> Void in
            try checkAuthorization()
            
            guard let calendar = eventStore.calendar(withIdentifier: request.list.calendarIdentifier) else {
                try checkAuthorization()
                throw ReminderStoreError.listNotFound(
                    calendarIdentifier: request.list.calendarIdentifier
                )
            }
            
            let dueDate = JapaneseDateConverter().convert(from: request.deadline).map {
                Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: $0)
            }
            
            try checkCancel()
            guard let dueDate else { throw ReminderStoreError.deadlineConversionFailed }
            
            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = request.title
            reminder.dueDateComponents = dueDate
            reminder.startDateComponents = nil
            reminder.addAlarm(.init(relativeOffset: 0))
            reminder.priority = request.priority.ekReminderPriority
            reminder.notes = request.notes
            reminder.calendar = calendar
            
            try checkCancel()
            try save(reminder)
        }
    }
    
    func set(id: String, completion: Bool) async throws(ReminderStoreError) {
        try await operation(priority: .normal) { () async throws(ReminderStoreError) -> Void in
            try checkAuthorization()
            
            guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
                try checkAuthorization()
                throw ReminderStoreError.reminderNotFound(
                    calendarItemIdentifier: id
                )
            }
            
            try checkCancel()
            reminder.isCompleted = completion
            try save(reminder)
        }
    }
    
    func fetch() async throws(ReminderStoreError) -> ReminderStoreFetchResult {
        try await operation(priority: .low) { () async throws(ReminderStoreError) -> ReminderStoreFetchResult in
            try checkAuthorization()
            
            let editableCalendars: [EKCalendar] = eventStore.calendars(for: .reminder)
                .filter(\.allowsContentModifications)
            
            let result = await withCheckedContinuation { continuation in
                let predicate = eventStore.predicateForReminders(in: editableCalendars)
                
                eventStore.fetchReminders(matching: predicate) { reminders in
                    let result: Result<[RAReminder], ReminderStoreError> = if let reminders {
                        .success(reminders.compactMap(\.reminder))
                    } else {
                        .failure(.fetchFailed)
                    }
                    
                    continuation.resume(returning: result)
                }
            }
            
            try checkCancel()
            try checkAuthorization()
            
            switch result {
            case .success(let reminders):
                let editableLists: [RAReminderList] = editableCalendars.map { calendar in
                        .init(
                            calendarIdentifier: calendar.calendarIdentifier,
                            title: calendar.title
                        )
                }
                
                let defaultListIdentifier: String? = eventStore.defaultCalendarForNewReminders()
                    .flatMap { $0.allowsContentModifications ? $0.calendarIdentifier : nil }
                
                return ReminderStoreFetchResult(
                    reminders: reminders,
                    editableLists: editableLists,
                    defaultListIdentifier: defaultListIdentifier
                )
            case .failure(let error):
                throw error
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
        try checkCancel()
        return try await action()
    }
    
    private enum OperationPriority {
        case high, normal, low
    }
    
    private var isOperating = false
    private var highPriorityWaiters: [CheckedContinuation<Void, Never>] = []
    private var normalPriorityWaiters: [CheckedContinuation<Void, Never>] = []
    private var lowPriorityWaiters: [CheckedContinuation<Void, Never>] = []
    
    private func acquireOperation(priority: OperationPriority) async {
        if isOperating == false {
            isOperating = true; return
        } else {
            await withCheckedContinuation { continuation in
                switch priority {
                case .high:
                    highPriorityWaiters.append(continuation)
                case .normal:
                    normalPriorityWaiters.append(continuation)
                case .low:
                    lowPriorityWaiters.append(continuation)
                }
            }
        }
    }
    
    private func releaseOperation() {
        if highPriorityWaiters.isEmpty == false {
            highPriorityWaiters.removeFirst().resume()
        } else if normalPriorityWaiters.isEmpty == false {
            normalPriorityWaiters.removeFirst().resume()
        } else if lowPriorityWaiters.isEmpty == false {
            lowPriorityWaiters.removeFirst().resume()
        } else {
            isOperating = false
        }
    }
}
