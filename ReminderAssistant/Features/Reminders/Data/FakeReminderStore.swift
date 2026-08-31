import Foundation
import JapaneseDateConverter

actor FakeReminderStore: ReminderStoreProtocol {
    struct ScheduledAdditions {
        /// リマインダーを追加する間隔。（fetchDelayより長い時間を指定するのが好ましい）
        let interval: Duration
        /// 定期的に追加するリマインダー。配列の先頭から順に追加する。
        fileprivate var pendingReminders: [RAReminder]
        
        /// 定期的なリマインダー追加の設定を生成する。
        /// - Parameters:
        ///   - interval: リマインダーを追加する間隔。（fetchDelayより長い時間を指定するのが好ましい）
        ///   - reminders: 定期的に追加するリマインダー。配列の先頭から順に追加する。
        init(
            interval: Duration = .seconds(1.5),
            reminders: [RAReminder],
        ) {
            self.interval = interval
            pendingReminders = reminders
        }
    }
    
    enum FailureOperation {
        case create, fetch, setCompletion
    }
    
    /// 現在ストアが保持しているリマインダー。
    private var reminders: [RAReminder]
    /// リマインダーを作成できる編集可能なリスト。
    private let editableLists: [RAReminderList]
    /// 新規リマインダーの作成先として扱うデフォルトリストのID。
    private let defaultListIdentifier: String?
    
    /// fetchが結果を返すまでの待機時間。
    private let fetchDelay: Duration
    /// 一度だけ失敗させる操作。nilの場合は意図的なエラーを発生させない。
    private var oneTimeFailureOperation: FailureOperation?
    /// 定期的な追加の設定と実行状態。nilの場合は定期追加を行わない。
    private var scheduledAdditions: ScheduledAdditions?
    
    /// リマインダーの変更を通知するインスタンス固有の通知名。
    nonisolated let remindersMayHaveChangedNotification = Notification.Name(
        "remindersMayHaveChanged.\(UUID().uuidString)"
    )
    
    /// 指定された初期状態と振る舞いでFakeReminderStoreを生成する。
    /// - Parameters:
    ///   - reminders: 最初からストアが保持するリマインダー。
    ///   - editableLists: 編集可能なリスト。nilの場合は初期リマインダーと定期追加するリマインダーから生成する。
    ///   - defaultListIdentifier: デフォルトリストのID。nilの場合は利用可能なリストから決定する。
    ///   - fetchDelay: fetchが結果を返すまでの待機時間。
    ///   - oneTimeFailureOperation: 一度だけ失敗させる操作。nilの場合は意図的なエラーを発生させない。
    ///   - scheduledAdditions: 定期的なリマインダー追加の設定。nilの場合は定期追加を行わない。
    init(
        reminders: [RAReminder] = .init(RAReminderSample.samples[0...29]),
        editableLists: [RAReminderList]? = nil,
        defaultListIdentifier: String? = nil,
        fetchDelay: Duration = .seconds(0.75),
        oneTimeFailureOperation: FailureOperation? = nil,
        scheduledAdditions: ScheduledAdditions? = nil
    ) {
        let lists: [RAReminderList] = {
            if let editableLists {
                return editableLists
            } else {
                let scheduledReminders =
                scheduledAdditions?.pendingReminders ?? []
                let allReminders =
                reminders + scheduledReminders
                
                return .init(Set(allReminders.map(\.list)))
            }
        }()
        
        let defaultListIdentifier = defaultListIdentifier
        ?? editableLists?.first?.id
        ?? reminders.first?.list.id
        ?? scheduledAdditions?.pendingReminders.first?.list.id
        
        self.reminders = reminders
        self.editableLists = lists
        self.defaultListIdentifier = defaultListIdentifier
        self.fetchDelay = fetchDelay
        self.oneTimeFailureOperation = oneTimeFailureOperation
        self.scheduledAdditions = scheduledAdditions
        
        if scheduledAdditions != nil {
            Task { await startScheduledAdditions() }
        }
    }
    
    func create(_ request: CreateReminderRequest) async throws(ReminderStoreError) {
        try await operation(priority: .normal) { () async throws(ReminderStoreError) -> Void in
            try throwOneTimeErrorIfNeeded(for: .create)
            
            guard editableLists.contains(where: { editableList in
                editableList.calendarIdentifier == request.list.calendarIdentifier
            }) else {
                throw ReminderStoreError.listNotFound(
                    calendarIdentifier: request.list.calendarIdentifier
                )
            }
            
            let dueDate = JapaneseDateConverter().convert(from: request.deadline).map {
                Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: $0)
            }
            
            try checkCancel()
            guard let dueDate else { throw ReminderStoreError.deadlineConversionFailed }
            
            let now = Date.now
            let reminder = RAReminder(
                calendarItemIdentifier: UUID().uuidString,
                list: request.list,
                title: request.title,
                dueDateComponents: dueDate,
                priority: request.priority,
                notes: request.notes,
                creationDate: now,
                lastModifiedDate: now
            )
            
            reminders.append(reminder)
            notifyRemindersMayHaveChanged()
        }
    }
    
    func set(id: String, completion: Bool) async throws(ReminderStoreError) {
        try await operation(priority: .normal) { () async throws(ReminderStoreError) -> Void in
            try throwOneTimeErrorIfNeeded(for: .setCompletion)
            
            guard let index = reminders.firstIndex(where: { $0.id == id }) else {
                throw ReminderStoreError.reminderNotFound(
                    calendarItemIdentifier: id
                )
            }
            
            try checkCancel()
            let reminder = reminders[index]
            let now = Date.now
            reminders[index] = RAReminder(
                calendarItemIdentifier: reminder.calendarItemIdentifier,
                list: reminder.list,
                title: reminder.title,
                dueDateComponents: reminder.dueDateComponents,
                priority: reminder.priority,
                notes: reminder.notes,
                isCompleted: completion,
                creationDate: reminder.creationDate,
                lastModifiedDate: now,
                completionDate: completion ? now : nil
            )
            notifyRemindersMayHaveChanged()
        }
    }
    
    func fetch() async throws(ReminderStoreError) -> ReminderStoreFetchResult {
        try await operation(priority: .low) { () async throws(ReminderStoreError) -> ReminderStoreFetchResult in
            do {
                try await Task.sleep(for: fetchDelay)
            } catch {
                throw .cancelled
            }
            try checkCancel()
            try throwOneTimeErrorIfNeeded(for: .fetch)
            
            return .init(
                reminders: reminders.filter { reminder in
                    editableLists.contains { editableList in
                        editableList.calendarIdentifier == reminder.list.calendarIdentifier
                    }
                },
                editableLists: editableLists,
                defaultListIdentifier: defaultListIdentifier
            )
        }
    }
    
    private func startScheduledAdditions() {
        guard let scheduledAdditions,
              scheduledAdditions.pendingReminders.isEmpty == false else {
            return
        }
        
        Task.detached { [interval = scheduledAdditions.interval, weak self] in
            while true {
                do {
                    try await Task.sleep(for: interval)
                    guard let self else { return }
                    let didAddReminder = try await self.addNextScheduledReminder()
                    guard didAddReminder else { break }
                } catch {
                    assertionFailure("定期追加に失敗した: \(error)"); break
                }
            }
            
            print("✅ scheduledAdditionTask finished")
        }
    }
    
    private func addNextScheduledReminder() async throws(ReminderStoreError) -> Bool {
        try await operation(priority: .normal) { () async throws(ReminderStoreError) -> Bool in
            guard let reminder = scheduledAdditions?.pendingReminders.first else {
                return false
            }
            
            reminders.append(reminder)
            scheduledAdditions?.pendingReminders.removeFirst()
            notifyRemindersMayHaveChanged()
            return true
        }
    }
    
    private func notifyRemindersMayHaveChanged() {
        NotificationCenter.default.post(
            name: remindersMayHaveChangedNotification,
            object: nil
        )
    }
    
    private func throwOneTimeErrorIfNeeded(for operation: FailureOperation) throws(ReminderStoreError) {
        guard oneTimeFailureOperation == operation else { return }
        
        oneTimeFailureOperation = nil
        switch operation {
        case .create, .setCompletion:
            throw .saveFailed
        case .fetch:
            throw .fetchFailed
        }
    }
    
    private func checkCancel() throws(ReminderStoreError) {
        do {
            try Task.checkCancellation()
        } catch {
            throw .cancelled
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
