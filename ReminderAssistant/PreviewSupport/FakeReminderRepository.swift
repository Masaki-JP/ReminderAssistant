import Foundation
import JapaneseDateConverter
import ReminderCore

actor FakeReminderRepository: ReminderRepositoryProtocol {
    struct ScheduledAdditions {
        /// リマインダーを追加する間隔。（``FakeReminderRepository/fetchDelay``より長い時間を指定するのが好ましい）
        fileprivate let interval: Duration
        /// 定期的に追加するリマインダー。配列の先頭から順に追加する。
        fileprivate var pendingReminders: [(listID: String, reminder: Reminder)]
        fileprivate let lists: [ReminderList]
        
        /// 定期的なリマインダー追加の設定を生成する。
        /// - Parameters:
        ///   - interval: リマインダーを追加する間隔。（`FakeReminderRepository/fetchDelay`より長い時間を指定するのが好ましい）
        ///   - lists: 定期的に追加するリマインダーを格納したリスト。リスト順・配列順に追加する。
        init(interval: Duration = .seconds(1.5), lists: [ReminderList]) {
            self.interval = interval
            self.lists = lists.map {
                ReminderList(id: $0.id, title: $0.title, isDefault: $0.isDefault, reminders: [])
            }
            pendingReminders = lists.flatMap { list in
                list.reminders.map { (list.id, $0) }
            }
        }
    }
    
    enum FailureOperation { case create, update, delete, fetch, setCompletion }
    
    /// リマインダーを作成できる編集可能なリスト。
    private var editableLists: [ReminderList]
    /// fetchが結果を返すまでの待機時間。
    private let fetchDelay: Duration
    /// 一度だけ失敗させる操作。`nil`の場合は意図的なエラーを発生させない。
    private var oneTimeFailureOperation: FailureOperation?
    /// 定期的な追加の設定と実行状態。`nil`の場合は定期追加を行わない。
    private var scheduledAdditions: ScheduledAdditions?
    
    /// リマインダーの変更を通知するインスタンス固有の通知名。
    nonisolated let remindersMayHaveChanged = Notification.Name(
        "remindersMayHaveChanged.\(UUID().uuidString)"
    )
    
    /// 指定された初期状態と振る舞いで``FakeReminderRepository``を生成する。
    /// - Parameters:
    ///   - editableLists: 最初からリポジトリが保持するリマインダーを格納した編集可能なリスト。
    ///   - fetchDelay: ``FakeReminderRepository/fetch()``が結果を返すまでの待機時間。
    ///   - oneTimeFailureOperation: 一度だけ失敗させる操作。`nil`の場合は意図的なエラーを発生させない。
    ///   - scheduledAdditions: 定期的なリマインダー追加の設定。`nil`の場合は定期追加を行わない。
    init(
        editableLists: [ReminderList] = {
            let reminderIDs = Set(Reminder.samples.prefix(30).map(\.id))
            return ReminderList.samples.map { list in
                var list = list
                list.reminders = list.reminders.filter { reminderIDs.contains($0.id) }
                return list
            }
        }(),
        fetchDelay: Duration = .seconds(0.75),
        oneTimeFailureOperation: FailureOperation? = nil,
        scheduledAdditions: ScheduledAdditions? = nil
    ) {
        var lists = editableLists
        for list in scheduledAdditions?.lists ?? [] where !lists.contains(where: { $0.id == list.id }) {
            lists.append(list)
        }
        self.editableLists = lists
        self.fetchDelay = fetchDelay
        self.oneTimeFailureOperation = oneTimeFailureOperation
        self.scheduledAdditions = scheduledAdditions
        
        if scheduledAdditions != nil { Task { await startScheduledAdditions() } }
    }
    
    func create(
        title: String, deadline: String, priority: Reminder.Priority, notes: String, list: ReminderList,
    ) async throws(ReminderRepositoryError) {
        try await operation(priority: .medium) { () async throws(ReminderRepositoryError) -> Void in
            try throwOneTimeErrorIfNeeded(for: .create)
            
            guard let listIndex = editableLists.firstIndex(where: { editableList in
                editableList.id == list.id
            }) else {
                throw ReminderRepositoryError.listNotFound(
                    id: list.id
                )
            }
            
            let dueDateCalendar = Calendar.gregorianCalendar()
            let dueDate = JapaneseDateConverter().convert(from: deadline).map {
                dueDateCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: $0)
            }
            
            try checkCancel()
            guard let dueDate else { throw ReminderRepositoryError.deadlineConversionFailed }
            
            let now = Date.now
            let reminder = Reminder(
                id: UUID().uuidString,
                title: title,
                dueDateComponents: dueDate,
                priority: priority,
                notes: notes,
                creationDate: now,
                lastModifiedDate: now
            )
            
            editableLists[listIndex].reminders.append(reminder)
            notifyRemindersMayHaveChanged()
        }
    }
    
    func update(
        id: String,
        title: String? = nil,
        deadline: String? = nil,
        priority: Reminder.Priority? = nil,
        notes: String?? = nil,
    ) async throws(ReminderRepositoryError) {
        try await operation(priority: .medium) { () async throws(ReminderRepositoryError) -> Void in
            guard let listIndex = editableLists.firstIndex(where: { $0.reminders.contains(where: { $0.id == id }) }),
                  let index = editableLists[listIndex].reminders.firstIndex(where: { $0.id == id }) else {
                throw .reminderNotFound(id: id)
            }
            guard title != nil || deadline != nil || priority != nil || notes != nil else { return }
            
            if let title, title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw .invalidTitle
            }
            let reminder = editableLists[listIndex].reminders[index]
            
            let dueDate = try deadline.map { deadline throws(ReminderRepositoryError) -> DateComponents in
                guard deadline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                      let date = JapaneseDateConverter().convert(from: deadline) else {
                    throw .deadlineConversionFailed
                }
                
                return Calendar.gregorianCalendar().dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: date
                )
            }
            
            try throwOneTimeErrorIfNeeded(for: .update)
            
            editableLists[listIndex].reminders[index] = Reminder(
                id: reminder.id,
                title: title ?? reminder.title,
                dueDateComponents: dueDate ?? reminder.dueDateComponents,
                priority: priority ?? reminder.priority,
                notes: notes ?? reminder.notes,
                isCompleted: reminder.isCompleted,
                creationDate: reminder.creationDate,
                lastModifiedDate: .now,
                completionDate: reminder.completionDate
            )
            notifyRemindersMayHaveChanged()
        }
    }
    
    func set(id: String, completion: Bool) async throws(ReminderRepositoryError) {
        try await operation(priority: .medium) { () async throws(ReminderRepositoryError) -> Void in
            try throwOneTimeErrorIfNeeded(for: .setCompletion)
            
            guard let listIndex = editableLists.firstIndex(where: { $0.reminders.contains(where: { $0.id == id }) }),
                  let index = editableLists[listIndex].reminders.firstIndex(where: { $0.id == id }) else {
                throw ReminderRepositoryError.reminderNotFound(
                    id: id
                )
            }
            
            try checkCancel()
            let reminder = editableLists[listIndex].reminders[index]
            let now = Date.now
            editableLists[listIndex].reminders[index] = Reminder(
                id: reminder.id,
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

    func delete(id: String) async throws(ReminderRepositoryError) {
        try await operation(priority: .medium) { () async throws(ReminderRepositoryError) -> Void in
            try throwOneTimeErrorIfNeeded(for: .delete)
            
            guard let listIndex = editableLists.firstIndex(where: { $0.reminders.contains(where: { $0.id == id }) }),
                  let reminderIndex = editableLists[listIndex].reminders.firstIndex(where: { $0.id == id }) else {
                throw ReminderRepositoryError.reminderNotFound(id: id)
            }
            
            editableLists[listIndex].reminders.remove(at: reminderIndex)
            notifyRemindersMayHaveChanged()
        }
    }
    
    func fetch() async throws(ReminderRepositoryError) -> [ReminderList] {
        try await operation(priority: .low) { () async throws(ReminderRepositoryError) -> [ReminderList] in
            do {
                try await Task.sleep(for: fetchDelay)
            } catch {
                throw .cancelled
            }
            try checkCancel()
            try throwOneTimeErrorIfNeeded(for: .fetch)
            
            return editableLists
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
    
    private func addNextScheduledReminder() async throws(ReminderRepositoryError) -> Bool {
        try await operation(priority: .medium) { () async throws(ReminderRepositoryError) -> Bool in
            guard let addition = scheduledAdditions?.pendingReminders.first,
                  let listIndex = editableLists.firstIndex(where: { $0.id == addition.listID }) else {
                return false
            }
            
            editableLists[listIndex].reminders.append(addition.reminder)
            scheduledAdditions?.pendingReminders.removeFirst()
            notifyRemindersMayHaveChanged()
            return true
        }
    }
    
    private func notifyRemindersMayHaveChanged() {
        NotificationCenter.default.post(name: remindersMayHaveChanged, object: nil)
    }
    
    private func throwOneTimeErrorIfNeeded(for operation: FailureOperation) throws(ReminderRepositoryError) {
        guard oneTimeFailureOperation == operation else { return }
        
        oneTimeFailureOperation = nil
        switch operation {
        case .create, .update, .setCompletion: throw .saveFailed
        case .delete: throw .deleteFailed
        case .fetch: throw .fetchFailed
        }
    }
    
    private func checkCancel() throws(ReminderRepositoryError) {
        do {
            try Task.checkCancellation()
        } catch {
            throw .cancelled
        }
    }
    
    // MARK: - Operation
    
    /// `operation`の`action`内から、`operation`を使用する別メソッドを呼ばない。
    /// 内側の`operation`は外側が保持しているロックの解放を待つが、外側の`operation`は内側の処理の完了を待つため、互いに待機してデッドロックする。
    @discardableResult
    private func operation<T>(
        priority: OperationPriority,
        action: () async throws(ReminderRepositoryError) -> T
    ) async throws(ReminderRepositoryError) -> T {
        await acquireOperation(priority: priority)
        defer { releaseOperation() }
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
