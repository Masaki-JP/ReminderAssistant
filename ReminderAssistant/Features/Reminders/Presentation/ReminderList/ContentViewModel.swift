import SwiftUI

@Observable
final class ContentViewModel<ReminderRepositoryType: ReminderRepository> {
    private(set) var editableLists: [ReminderList] = []
    var reminders: [Reminder] { editableLists.flatMap(\.reminders) }
    
    private(set) var error: ContentViewModelError? = nil
    var errorBinding: Binding<Bool> {
        .init(
            get: { self.error != nil },
            set: { if $0 == false { self.error = nil } }
        )
    }
    
    var isLoading: Bool {
        (reminderOperations.first).map { operation in
            if case .load = operation { true } else { false }
        } ?? false
    }
    
    /// 予約・実行中のリマインダー取得・作成・完了状態更新を追加順に保持する操作一覧。
    private var reminderOperations: [ReminderOperation] = .init()
    /// 初回キャッシュの読み込みを試行済みかどうか。
    private var hasReadInitialCache = false
    /// 完了状態更新の失敗後、進行中の作成・完了状態更新がすべて終了した際に再読み込みするかどうか。
    private var shouldReloadAfterCompletionToggleFailure = false
    /// リマインダーの変更通知を解除するためのトークン。
    private var notificationToken: (any NSObjectProtocol)? = nil
    /// リマインダーを取得・作成・更新するリポジトリ。
    private let reminderRepository: ReminderRepositoryType
    /// リマインダー一覧をローカルに保存するキャッシュ。
    private let reminderStoreCache: ReminderStoreCache?
    /// リマインダーへのアクセス権限が失効した際の処理。
    private let reminderAccessRevokedHandler: () -> Void
    
    /// リマインダーリポジトリとキャッシュを設定し、リマインダー変更通知の監視を開始する。
    init(
        reminderRepository: ReminderRepositoryType,
        reminderStoreCache: ReminderStoreCache?,
        onReminderAccessRevoked: @escaping () -> Void,
    ) {
        self.reminderRepository = reminderRepository
        self.reminderStoreCache = reminderStoreCache
        self.reminderAccessRevokedHandler = onReminderAccessRevoked
        
        notificationToken = NotificationCenter.default.addObserver(
            forName: reminderRepository.remindersMayHaveChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                // エラー表示中は通知を起点に再取得せず、利用者によるエラーの確認や回復操作を待つ。
                guard self?.error == nil else { return }
                self?.loadReminders()
            }
        }
    }
    
    /// 通知監視を解除し、予約・実行中の操作をキャンセルする。
    /// ViewModelの破棄後は処理結果を画面へ反映できないため、作成・更新が完了しない可能性を許容する。
    isolated deinit {
        notificationToken.map { NotificationCenter.default.removeObserver($0) }
        reminderOperations.removeAll { $0.cancel(); return true }
    }
    
    // MARK: - Reminder Loading
    
    /// リマインダー一覧を取得し、表示とキャッシュを最新の状態へ更新する。
    ///
    /// `loadReminders()` は最初に `cancelLoad()` を呼び、それ以前の取得結果が後から表示を上書きすることを防ぐ。
    /// 続いて `reminderRepository.fetch()` を開始し、初回のみ `reminderStoreCache.fetch()` の結果を先に `editableLists` へ反映する。
    /// リポジトリから最新の一覧を取得した後は、`editableLists` を更新して `reminderStoreCache.save(_:)` でキャッシュへ保存する。
    /// 取得タスクは終了時に `reminderOperations.remove(with:)` で管理対象から外れ、エラーは `handleError(_:as:)` で処理される。
    /// `cancelLoad()` によってキャンセルされた場合は、`handleError(_:as:)` がキャンセルを判定するため画面にエラーを表示しない。
    
    /// リマインダーを取得し、初回のみキャッシュを先に表示してから最新の取得結果で更新する。
    func loadReminders() {
        cancelLoad()
        
        let shouldReadInitialCache = hasReadInitialCache == false
        hasReadInitialCache = true
        
        let operationID = UUID()
        let task = Task { [weak self, reminderRepository = self.reminderRepository, reminderStoreCache = self.reminderStoreCache] in
            defer { self?.reminderOperations.remove(with: operationID) }
            
            do {
                async let fetchedLists = reminderRepository.fetch()
                
                if shouldReadInitialCache,
                   let cachedLists = await reminderStoreCache?.fetch() {
                    try Task.checkCancellation()
                    self?.editableLists = cachedLists
                }
                
                let lists = try await fetchedLists
                try Task.checkCancellation()
                self?.editableLists = lists
                await reminderStoreCache?.save(lists)
            } catch {
                self?.handleError(error, as: .loadRemindersFailed)
            }
        }
        
        reminderOperations.append(.load(id: operationID, task: task))
    }
    
    /// 古い取得結果が後から表示やキャッシュを上書きしないよう、実行中のリマインダー取得をすべてキャンセルする。
    private func cancelLoad() {
        reminderOperations.removeAll { operation in
            if case .load(_, let loadTask) = operation {
                loadTask.cancel(); return true
            } else {
                return false
            }
        }
    }
    
    // MARK: - Reminder Creation
    
    /// 作成先を確認し、新しいリマインダーをリポジトリに作成する。
    ///
    /// `createReminder(_:)` は `createReminderTask(request:operationID:)` で作成タスクを生成して `reminderOperations` へ登録し、
    /// `cancelLoad()` で進行中の取得を止めてから、キャンセルハンドラーを使用して作成結果を待つ。
    /// 取得を止めることで、作成前の取得結果が作成後に返り、表示やキャッシュを古い状態へ戻すことを防ぐ。
    /// 作成タスクは `reminderDestinationList(for:)` で作成先を取得し、`reminderRepository.create(...)` でリポジトリへ保存する。
    /// 保存に成功すると成功の触覚フィードバックを発生させ、失敗すると `handleCreateReminderError(_:)` を呼び出す。
    /// `handleCreateReminderError(_:)` と `resolveCreateReminderError(_:)` は、キャンセル・期限変換失敗・作成先なし・保存失敗を
    /// `CreateReminderError` へ変換し、キャンセル以外の場合にエラーの触覚フィードバックを発生させる。
    /// 作成タスクは成否にかかわらず `finishReminderMutation(with:)` を呼び、操作一覧から自身を取り除く。
    
    /// 指定された内容でリマインダーを作成し、作成に失敗した場合は画面用のエラーを送出する。
    func createReminder(_ request: CreateReminderRequest) async throws(CreateReminderError) {
        let operationID = UUID()
        let task = createReminderTask(request: request, operationID: operationID)
        
        reminderOperations.append(.create(id: operationID, task: task))
        cancelLoad()
        
        let result = await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        
        if case .failure(let error) = result {
            throw error
        }
    }
    
    /// リマインダー作成と、その結果に応じた後処理を実行するタスクを作成する。
    private func createReminderTask(
        request: CreateReminderRequest,
        operationID: UUID,
    ) -> Task<Result<Void, CreateReminderError>, Never> {
        Task { [weak self] () -> Result<Void, CreateReminderError> in
            defer { self?.finishReminderMutation(with: operationID) }
            
            do {
                guard let list = try self?.reminderDestinationList(for: request.listIdentifier) else {
                    return .failure(.cancelled)
                }
                
                try await self?.reminderRepository.create(
                    title: request.title, deadline: request.deadline, priority: request.priority, notes: request.notes, list: list,
                )
            } catch {
                guard let self else { return .failure(.cancelled) }
                return .failure(self.handleCreateReminderError(error))
            }
            
            guard self != nil else { return .failure(.cancelled) }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return .success(())
        }
    }
    
    /// 指定された識別子に対応する、作成先の編集可能なリストを返す。
    private func reminderDestinationList(for listIdentifier: String?) throws(ContentViewModelError) -> ReminderList {
        if let list = editableLists.first(where: { $0.calendarIdentifier == listIdentifier }) {
            return list
        } else {
            throw .reminderDestinationListUnavailable
        }
    }
    
    /// リマインダー作成エラーを画面用のエラーへ変換し、必要に応じて失敗の触覚フィードバックを発生させる。
    private func handleCreateReminderError(_ error: any Error) -> CreateReminderError {
        let createReminderError = resolveCreateReminderError(error)
        
        switch createReminderError {
        case .cancelled: break
        default: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        return createReminderError
    }
    
    /// リマインダー作成時のエラーを、作成画面で扱うエラーに解決する。
    private func resolveCreateReminderError(_ error: any Error) -> CreateReminderError {
        guard let resolvedError = resolveError(error, as: .createReminderFailed) else {
            return .cancelled
        }
        
        return if (error as? ReminderRepositoryError) == .deadlineConversionFailed {
            .invalidDeadline
        } else if case .reminderDestinationListUnavailable = resolvedError {
            .destinationListUnavailable
        } else {
            .saveFailed
        }
    }
    
    // MARK: - Reminder Completion
    
    /// 操作を画面へ即時に反映し、リマインダーの完了状態をリポジトリへ保存する。
    ///
    /// `onToggleCompletion(_:)` は `hasPendingCompletionToggle(for:)` で同じリマインダーの更新が進行中か確認する。
    /// 更新がなければ `requestCompletionToggle(for:)` で保存を予約し、更新中であれば `cancelCompletionToggle(for:)` で取り消す。
    /// 取り消しによって短時間の反対操作を相殺し、リポジトリへの往復更新を避ける。
    /// その後、`reminderIndex(for:)` で対象の位置を取得し、保存の完了を待たずに画面上の完了状態を切り替える。
    /// `requestCompletionToggle(for:)` は反対操作で相殺できるよう0.3秒待機した後、`reminderRepository.set(id:completion:)` で保存する。
    /// また、`cancelLoad()` で進行中の取得を止め、変更前・変更途中の取得結果が後から表示やキャッシュを上書きすることを防ぐ。
    /// 保存に成功すると `setIsCompleted(_:)` で実値を確定し、失敗すると `handleError(_:as:)` でエラーを表示して
    /// `shouldReloadAfterCompletionToggleFailure` を有効にし、すべての変更操作が終わった後の再取得を予約する。
    
    /// リマインダーの完了状態の更新を予約または取り消し、画面表示を即時に切り替える。
    func onToggleCompletion(_ reminder: Reminder) {
        let isPending = hasPendingCompletionToggle(for: reminder)
        
        if isPending == false {
            requestCompletionToggle(for: reminder)
        } else {
            cancelCompletionToggle(for: reminder)
        }
        
        guard let index = reminderIndex(for: reminder) else { return }
        let newValue = isPending ? reminder.isCompleted : !reminder.isCompleted
        editableLists[index.list].reminders[index.reminder].setDisplayedIsCompleted(newValue)
    }
    
    /// 指定リマインダーの完了状態更新が予約または実行中かどうかを返す。
    private func hasPendingCompletionToggle(for reminder: Reminder) -> Bool {
        reminderOperations.contains { operation in
            switch operation {
            case .toggleCompletion(_, let reminderID, _) where reminderID == reminder.id: true
            default: false
            }
        }
    }
    
    /// 完了状態の更新を予約し、変更前・変更途中の取得結果による上書きを防ぐため、進行中の取得をキャンセルする。
    private func requestCompletionToggle(for reminder: Reminder) {
        let operationID = UUID()
        let completion = !reminder.isCompleted
        let task = Task { [weak self] in
            defer { self?.finishReminderMutation(with: operationID) }
            
            do {
                try await Task.sleep(for: .seconds(0.3))
                try await self?.reminderRepository.set(id: reminder.id, completion: completion)
                guard let index = self?.reminderIndex(for: reminder) else { return }
                self?.editableLists[index.list].reminders[index.reminder].setIsCompleted(completion)
            } catch {
                guard let self else { return }
                guard handleError(error, as: .toggleCompletionFailed) == true else { return }
                shouldReloadAfterCompletionToggleFailure = true
            }
        }
        
        reminderOperations.append(
            .toggleCompletion(id: operationID, reminderID: reminder.id, task: task)
        )
        cancelLoad()
    }
    
    /// 短時間の反対操作を相殺して不要なリポジトリ更新を避けるため、予約されている完了状態更新をキャンセルする。
    private func cancelCompletionToggle(for reminder: Reminder) {
        reminderOperations.removeAll { operation in
            if case let .toggleCompletion(_, reminderID, task) = operation, reminderID == reminder.id {
                task.cancel(); return true
            } else {
                return false
            }
        }
    }
    
    /// 編集可能なリスト内における指定リマインダーの位置を返す。
    private func reminderIndex(for reminder: Reminder) -> (list: Int, reminder: Int)? {
        for listIndex in editableLists.indices {
            if let reminderIndex = editableLists[listIndex].reminders.firstIndex(where: { $0.id == reminder.id }) {
                return (listIndex, reminderIndex)
            }
        }
        return nil
    }
    
    // MARK: - Reminder Mutation Coordination
    
    /// 複数の変更操作の終了と、失敗後に実行する再取得を調整する。
    ///
    /// `finishReminderMutation(with:)` は終了した作成または完了状態更新を `reminderOperations.remove(with:)` で取り除き、
    /// 続けて `reloadRemindersAfterCompletionToggleFailureIfNeeded()` を呼び出す。
    /// `reloadRemindersAfterCompletionToggleFailureIfNeeded()` は再取得が予約され、かつ `.create` と `.toggleCompletion` が
    /// 一つも残っていない場合だけ予約を解除して `loadReminders()` を呼ぶ。
    /// これにより、変更途中に取得した一覧が楽観的に更新した表示を上書きしたり、その一覧がキャッシュへ保存されたりすることを防ぎ、
    /// すべての変更を反映した状態を一度だけ取得する。
    
    /// 作成・完了状態更新の終了を記録し、必要であれば再読み込みする。
    private func finishReminderMutation(with operationID: UUID) {
        reminderOperations.remove(with: operationID)
        reloadRemindersAfterCompletionToggleFailureIfNeeded()
    }
    
    /// 完了状態更新の失敗後、進行中の作成・完了状態更新がすべて終了した時点で最新状態を再読み込みする。
    private func reloadRemindersAfterCompletionToggleFailureIfNeeded() {
        guard shouldReloadAfterCompletionToggleFailure == true else { return }
        
        let hasPendingMutation = reminderOperations.contains { operation in
            switch operation {
            case .create, .toggleCompletion: true
            case .load: false
            }
        }
        guard hasPendingMutation == false else { return }
        
        shouldReloadAfterCompletionToggleFailure = false
        loadReminders()
    }
    
    // MARK: - Error Handling
    
    /// 発生したエラーを分類し、画面表示または権限失効時の処理へつなげる。
    ///
    /// `reportReminderDestinationListUnavailable()` は作成先がないエラーを `presentError(_:)` で直接表示する。
    /// `handleError(_:as:)` は `resolveError(_:as:)` でエラーを分類し、表示対象が返された場合だけ `presentError(_:)` を呼ぶ。
    /// `resolveError(_:as:)` はキャンセルを表示対象から除外し、権限失効時は `handleReminderAccessRevoked()` に処理を委譲する。
    /// それ以外は既存の `ContentViewModelError` を維持し、リストが見つからない場合は作成先なしへ変換して、
    /// 分類できないエラーには呼び出し元が指定したフォールバックエラーを使用する。
    /// `handleReminderAccessRevoked()` は再取得の予約を解除して全操作をキャンセルし、`reminderAccessRevokedHandler` を実行する。
    /// `presentError(_:)` はエラーを `error` に保持し、エラー用の触覚フィードバックを発生させる。
    
    /// 作成先リストを利用できないことを、画面に表示するエラーとして通知する。
    func reportReminderDestinationListUnavailable() {
        presentError(.reminderDestinationListUnavailable)
    }
    
    /// 共通処理で解決したエラーを画面に表示し、表示したかどうかを返す。
    @discardableResult
    private func handleError(_ error: any Error, as fallbackError: ContentViewModelError) -> Bool {
        guard let error = resolveError(error, as: fallbackError) else { return false }
        presentError(error)
        return true
    }
    
    /// 権限失効とキャンセルを処理し、それ以外を画面表示用エラーに解決する。
    private func resolveError(
        _ error: any Error,
        as fallbackError: ContentViewModelError
    ) -> ContentViewModelError? {
        if (error as? ReminderRepositoryError) == .accessNotAuthorized {
            handleReminderAccessRevoked()
            return nil
        }
        
        if error is CancellationError || (error as? ReminderRepositoryError) == .cancelled {
            return nil
        }
        
        return if let contentViewModelError = error as? ContentViewModelError {
            contentViewModelError
        } else if let reminderRepositoryError = error as? ReminderRepositoryError,
                  case .listNotFound = reminderRepositoryError {
            .reminderDestinationListUnavailable
        } else {
            fallbackError
        }
    }
    
    /// 再読み込み予約を解除し、すべての操作をキャンセルして権限失効を通知する。
    private func handleReminderAccessRevoked() {
        shouldReloadAfterCompletionToggleFailure = false
        reminderOperations.removeAll { $0.cancel(); return true }
        reminderAccessRevokedHandler()
    }
    
    /// エラーを保持し、エラー用の触覚フィードバックを発生させる。
    private func presentError(_ error: ContentViewModelError) {
        self.error = error
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

/// ViewModelが管理する操作と、その操作を実行するタスク。
/// 各操作は実行単位のUUIDで識別し、完了状態更新は対象のリマインダーIDも保持する。
private enum ReminderOperation {
    case create(id: UUID, task: Task<Result<Void, CreateReminderError>, Never>)
    case toggleCompletion(id: UUID, reminderID: Reminder.ID, task: Task<Void, Never>)
    case load(id: UUID, task: Task<Void, Never>)
    
    /// この操作を一意に識別するID。
    var id: UUID {
        switch self {
        case .create(let id, _): id
        case .toggleCompletion(let id, _, _): id
        case .load(let id, _): id
        }
    }
    
    /// この操作に紐づくTaskをキャンセルする。
    func cancel() {
        switch self {
        case .create(_, let task): task.cancel()
        case .toggleCompletion(_, _, let task), .load(_, let task): task.cancel()
        }
    }
}

private extension Array<ReminderOperation> {
    /// 指定されたIDを用いて、完了した操作を管理対象から削除する。
    mutating func remove(with operationID: UUID) {
        removeAll { $0.id == operationID }
    }
}
