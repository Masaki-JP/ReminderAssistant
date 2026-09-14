import EventKit
import JapaneseDateConverter

/// `EventKit`を使用して、リマインダーの作成・完了状態の更新・取得を行うストア。
///
/// ``ReminderStore``は、`EKEventStore`とアプリ内の``Reminder``および``ReminderList``の間を取り持つデータアクセス層。アプリ全体では``shared``から共有インスタンスを使用する。各操作でリマインダーへのフルアクセス権限を確認し、`EventKit`やキャンセルによる失敗を``ReminderStoreError``に変換する。アクセス権の要求はこのストアの責務に含めず、``ReminderAccessRequestView``が別インスタンスの`EKEventStore`を使用する。
///
/// ## アクターとしての責務
///
/// ストアをアクターとすることで、`EventKit`へのアクセスと操作の待機列をUIを担う`MainActor`から分離している。また、`EventKit`の変更通知を監視するオブザーバートークンもこのアクターが所有し、インスタンスの破棄時に解除する。
///
/// ## 操作の直列化
///
/// Swiftのアクターは、`await`によるサスペンド中に他の呼び出しが再入することを許可する。そのため、アクターによる状態の保護だけでは、``fetch()``がリマインダーの取得完了を待っている間に、``create(title:deadline:priority:notes:list:)``や``set(id:completion:)``などの別の操作が開始され、同じ`EKEventStore`が同時に使用される可能性がある。
///
/// `ReminderStore`は、同じ`EKEventStore`を同時に使用しないように、作成・完了状態の更新・取得を1つずつ実行するための待機列を内部に持つ。
///
/// ## 操作の優先度
///
/// 待機中の操作は高・中・低の3つの優先度に分け、実行中の操作が終了すると高い優先度の待機列から次の操作へ実行権を渡す。同じ優先度の操作は、待機列に追加された順に実行する。
///
/// 作成と完了状態の更新の優先度は中とし、取得の優先度は低とする。これにより、取得より後に作成や更新が待機した場合でも、ユーザー操作に直接応答する作成と更新を先に実行する。高優先度の待機列も持つが、現在の`ReminderStore`で高優先度を指定する操作はない。
///
/// - Important: 優先度は待機中の操作から次に実行する操作を選ぶためのもので、実行中の操作は中断しない。新しい操作は、実行中の操作が終了するまで待機する。
///
/// ## 変更通知
///
/// `EKEventStoreChanged`を受け取ると、``remindersMayHaveChanged``を通知する。この通知は変更の発生可能性だけを示し、変更後のリマインダー自体は含まない。最新の状態が必要な呼び出し側は、通知後に``fetch()``で再取得する。
///
/// ## 実行時間
///
/// 各操作のおおよその実行時間は以下の通り。
///
/// - 作成：約0.07秒
/// - 完了状態の更新：約0.1秒
/// - 取得：約0.8秒（初回は約2.0秒）
///
/// - Note: 2026年8月31日にiPhone 17で測定。
///
final actor ReminderStore: ReminderStoreProtocol {
    static let shared = ReminderStore()
    /// リマインダー（リスト）の変更を外部に伝えるための通知名。
    nonisolated let remindersMayHaveChanged: Notification.Name
    
    private let eventStore: EKEventStore
    /// `EventKit`の変更を監視するためのトークン。
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
    
    // MARK: - Reminder Creation
    
    /// 指定したリストにリマインダーを作成する。
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
    
    // MARK: - Reminder Completion
    
    /// 指定したリマインダーの完了状態を更新する。
    func set(id: String, completion: Bool) async throws(ReminderStoreError) {
        try await operation(priority: .medium) { () async throws(ReminderStoreError) -> Void in
            guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
                throw .reminderNotFound(calendarItemIdentifier: id)
            }
            
            reminder.isCompleted = completion
            try save(reminder)
        }
    }
    
    // MARK: - Reminder Fetching
    
    /// カレンダーID（リストID）ごとに、そのリストに含まれるリマインダーを保持する辞書型のタイプエイリアス。
    private typealias RemindersByCalendarIdentifier = [String: [Reminder]]
    
    /// 編集可能なリスト（リマインダー）を取得する。
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
    
    /// 指定したリストに含まれるリマインダーを取得し、リストIDごとに分類する。
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
    
    // MARK: - Helpers
    
    /// 現在の`Task`がキャンセルされている場合に、``ReminderStoreError/cancelled``を投げる。
    private func checkCancel() throws(ReminderStoreError) {
        do {
            try Task.checkCancellation()
        } catch {
            throw .cancelled
        }
    }
    
    /// リマインダーへのフルアクセス権限を確認する。
    private func checkAuthorization() throws(ReminderStoreError) {
        guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
            throw .accessNotAuthorized
        }
    }
    
    /// リマインダーを保存する。保存時のエラーは``ReminderStoreError``のエラーへ変換する。
    private func save(_ reminder: EKReminder) throws(ReminderStoreError) {
        do {
            try eventStore.save(reminder, commit: true)
        } catch let error as EKError where error.code == .eventStoreNotAuthorized {
            throw .accessNotAuthorized
        } catch {
            throw .saveFailed
        }
    }
    
    // MARK: - Operation Management
    
    /// 操作を直列化して実行する。
    ///
    /// - Important: `operation`の`action`内から、`operation`を使用する別メソッドを呼ばないこと。
    ///   内側の`operation`は外側が保持しているロックの解放を待つが、外側の`operation`は内側の処理の完了を待つため、互いに待機してデッドロックとなる。
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
    
    /// 操作の実行権を取得する。実行中の場合は優先度に応じた待機列へ追加する。
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
    
    /// 優先度に応じた次の操作に実行権を受け渡す。待機中の操作がなければ実行中状態を解除する。
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
