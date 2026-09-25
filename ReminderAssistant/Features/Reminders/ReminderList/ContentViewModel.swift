import SwiftUI
import ReminderCore

@Observable
final class ContentViewModel<ReminderRepositoryType: ReminderRepositoryProtocol> {
    private(set) var editableLists: [ReminderList] = []
    var reminders: [Reminder] { editableLists.flatMap(\.reminders) }
    
    private(set) var error: ContentViewModelError? = nil
    var errorBinding: Binding<Bool> {
        .init(
            get: { self.error != nil },
            set: { if $0 == false { self.error = nil } }
        )
    }
    
    /// リマインダー一覧の取得の実行状態を表す。（`ReminderStore`の仕様上、実際に取得を行なっている最中だけでなく、待機中も実行中と評価されることに注意。）
    var isLoading: Bool {
        reminderOperations.contains { if case .load = $0 { true } else { false } }
    }
    /// 保存・完了状態更新・削除のいずれかが予約または実行中かどうか。
    private var hasPendingMutation: Bool {
        reminderOperations.contains { operation in
            switch operation {
            case .save, .toggleCompletion, .delete: true
            case .load: false
            }
        }
    }
    
    /// 予約・実行中のリマインダー取得・保存・完了状態更新・削除を追加順に保持する操作一覧。
    private var reminderOperations: [ReminderOperation] = .init()
    /// 完了状態をリポジトリへ保存中で、再度の切り替えを禁止するリマインダーのID。
    private var completionToggleLockedReminderIDs: Set<Reminder.ID> = []
    /// 初回キャッシュの読み込みを試行済みかどうか。
    private var hasReadInitialCache = false
    /// 進行中の変更操作がすべて終了した際に再読み込みするかどうか。
    private var shouldReloadAfterMutation = false
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
                guard let self else { return }
                // エラー表示中は通知を起点に再取得せず、利用者によるエラーの確認や回復操作を待つ。
                guard self.error == nil else { return }
                // 変更操作中でなければ再読み込み、変更操作中であれば再読み込みを予約する。
                if self.hasPendingMutation == true {
                    self.shouldReloadAfterMutation = true
                } else {
                    self.loadReminders()
                }
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
    
    /// 古い取得結果が後から表示やキャッシュを上書きしないよう、実行中のリマインダー取得をすべてキャンセルし、キャンセルしたかどうかを返す。
    @discardableResult
    private func cancelLoad() -> Bool {
        var hasCancelledLoad = false
        
        reminderOperations.removeAll { operation in
            if case .load(_, let loadTask) = operation {
                hasCancelledLoad = true
                loadTask.cancel(); return true
            } else {
                return false
            }
        }
        
        return hasCancelledLoad
    }
    
    // MARK: - Reminder Saving
    
    /// モードに応じて作成・編集を実行し、失敗した場合はシートに表示するエラーを送出する。
    /// 古い取得結果が保存後の状態を上書きしないよう、進行中の取得をキャンセルしてから保存結果を待つ。
    /// 作成先の設定は作成時だけ使用し、編集時は元のリマインダーの所属リストを保持する。
    func saveReminder(
        _ draft: ReminderDraft,
        mode: ReminderEditorMode,
        listIdentifier: String?,
    ) async throws(ReminderEditorError) {
        let operationID = UUID()
        let task = saveReminderTask(draft: draft, mode: mode, listIdentifier: listIdentifier, operationID: operationID)
        
        reminderOperations.append(.save(id: operationID, task: task))
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
    
    /// リマインダーの保存と、その結果に応じた後処理を実行するタスクを作成する。
    private func saveReminderTask(
        draft: ReminderDraft,
        mode: ReminderEditorMode,
        listIdentifier: String?,
        operationID: UUID,
    ) -> Task<Result<Void, ReminderEditorError>, Never> {
        Task { [weak self] () -> Result<Void, ReminderEditorError> in
            defer { self?.finishReminderMutation(with: operationID) }
            
            do {
                switch mode {
                case .create:
                    guard let list = try self?.reminderDestinationList(for: listIdentifier) else {
                        return .failure(.cancelled)
                    }
                    try await self?.reminderRepository.create(
                        title: draft.title, deadline: draft.deadline, priority: draft.priority, notes: draft.notes, list: list,
                    )
                case .edit(let reminder):
                    let notes: String?? = if draft.notes == (reminder.notes ?? "") {
                        nil
                    } else {
                        .some(draft.notes.isEmpty ? nil : draft.notes)
                    }
                    try await self?.reminderRepository.update(
                        id: reminder.id,
                        title: draft.title == reminder.title ? nil : draft.title,
                        deadline: draft.deadlineUpdate,
                        priority: draft.priority == reminder.priority ? nil : draft.priority,
                        notes: notes,
                    )
                }
            } catch {
                guard let self else { return .failure(.cancelled) }
                return .failure(self.handleSaveReminderError(error))
            }
            
            guard self != nil else { return .failure(.cancelled) }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return .success(())
        }
    }
    
    /// 指定された識別子に対応する、作成先の編集可能なリストを返す。
    private func reminderDestinationList(for listIdentifier: String?) throws(ContentViewModelError) -> ReminderList {
        if let list = editableLists.first(where: { $0.id == listIdentifier }) {
            return list
        } else {
            throw .reminderDestinationListUnavailable
        }
    }
    
    /// リマインダー保存エラーを画面用のエラーへ変換し、必要に応じて失敗の触覚フィードバックを発生させる。
    private func handleSaveReminderError(_ error: any Error) -> ReminderEditorError {
        let saveReminderError = resolveSaveReminderError(error)
        
        switch saveReminderError {
        case .cancelled: break
        default: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        return saveReminderError
    }
    
    /// リマインダー保存時のエラーを、作成・編集画面で扱うエラーに解決する。
    private func resolveSaveReminderError(_ error: any Error) -> ReminderEditorError {
        guard let resolvedError = resolveError(error, as: .saveReminderFailed) else {
            return .cancelled
        }
        
        return if (error as? ReminderRepositoryError) == .invalidTitle {
            .invalidTitle
        } else if (error as? ReminderRepositoryError) == .deadlineConversionFailed {
            .invalidDeadline
        } else if let repositoryError = error as? ReminderRepositoryError,
                  case .reminderNotFound = repositoryError {
            .reminderUnavailable
        } else if case .reminderDestinationListUnavailable = resolvedError {
            .destinationListUnavailable
        } else {
            .saveFailed
        }
    }
    
    // MARK: - Reminder Completion
    
    /// 操作を画面へ即時に反映し、リマインダーの完了状態をリポジトリへ保存する。
    ///
    /// `onToggleCompletion(_:)` は同じリマインダーの完了状態をリポジトリへ保存中であれば操作を受け付けない。
    /// 保存前の待機中であれば `cancelCompletionToggle(for:)` で取り消し、更新がなければ `requestCompletionToggle(for:)` で保存を予約する。
    /// 取り消しによって短時間の反対操作を相殺し、リポジトリへの往復更新を避ける。
    /// その後、`reminderIndex(for:)` で対象の位置を取得し、保存の完了を待たずに画面上の完了状態を切り替える。
    /// `requestCompletionToggle(for:)` は反対操作で相殺できるよう1.5秒待機した後、再度の切り替えを禁止して
    /// `reminderRepository.set(id:completion:)` で保存し、処理の終了時に禁止を解除する。
    /// また、`cancelLoad()` で進行中の取得を止め、変更前・変更途中の取得結果が後から表示やキャッシュを上書きすることを防ぐ。
    /// 保存に成功すると `setIsCompleted(_:)` で実値を確定し、失敗すると `handleError(_:as:)` でエラーを表示して
    /// `shouldReloadAfterMutation` を有効にし、すべての変更操作が終わった後の再取得を予約する。
    
    /// リマインダーの完了状態の更新を予約または取り消し、画面表示を即時に切り替える。
    func onToggleCompletion(_ reminder: Reminder) {
        guard completionToggleLockedReminderIDs.contains(reminder.id) == false,
              let index = reminderIndex(for: reminder),
              editableLists[index.list].reminders[index.reminder].isMarkedForDeletion == false
        else { return }
        
        let isPending = hasPendingCompletionToggle(for: reminder)
        
        if isPending == false {
            requestCompletionToggle(for: reminder)
        } else {
            cancelCompletionToggle(for: reminder)
        }
        
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
    /// 取得をキャンセルした場合は、完了状態の更新が取り消されても最新状態を取得できるよう、変更操作終了後の再取得を予約する。
    private func requestCompletionToggle(for reminder: Reminder) {
        let operationID = UUID()
        let completion = !reminder.isCompleted
        let task = Task { [weak self] in
            defer { self?.finishReminderMutation(with: operationID) }
            
            do {
                try await Task.sleep(for: .seconds(1.5))
                defer { self?.completionToggleLockedReminderIDs.remove(reminder.id) }
                self?.completionToggleLockedReminderIDs.insert(reminder.id)
                
                try await self?.reminderRepository.set(id: reminder.id, completion: completion)
                guard let index = self?.reminderIndex(for: reminder) else { return }
                self?.editableLists[index.list].reminders[index.reminder].setIsCompleted(completion)
            } catch {
                guard let self else { return }
                guard handleError(error, as: .toggleCompletionFailed) == true else { return }
                shouldReloadAfterMutation = true
            }
        }
        
        reminderOperations.append(
            .toggleCompletion(id: operationID, reminderID: reminder.id, task: task)
        )
        if cancelLoad() == true {
            shouldReloadAfterMutation = true
        }
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
    
    // MARK: - Reminder Deletion
    
    /// 削除状態を画面へ即時に反映し、リマインダーをリポジトリから削除する。
    ///
    /// 削除予定としてマーク済みの場合は重複した削除を行わない。
    /// 対象の完了状態更新と進行中の取得をキャンセルし、削除前の取得結果による表示の上書きを防ぐ。
    /// 削除に成功した対象は表示中の一覧から取り除き、リポジトリの変更通知を受けて一覧を再取得する。
    /// 失敗した場合はエラーを表示し、すべての変更操作が終了してから最新状態を再取得する。
    
    /// 指定リマインダーを削除予定としてマークし、削除タスクを登録する。
    func deleteReminder(id: String) {
        guard let reminder = reminders.first(where: { $0.id == id }),
              let index = reminderIndex(for: reminder),
              reminder.isMarkedForDeletion == false else { return }
        
        editableLists[index.list].reminders[index.reminder].markForDeletion()
        cancelCompletionToggle(for: reminder)
        cancelLoad()
        
        let operationID = UUID()
        let task = Task { [weak self] in
            defer { self?.finishReminderMutation(with: operationID) }
            
            do {
                try await self?.reminderRepository.delete(id: id)
                guard let index = self?.reminderIndex(for: reminder) else { return }
                self?.editableLists[index.list].reminders.remove(at: index.reminder)
            } catch {
                guard let self else { return }
                guard handleError(error, as: .deleteReminderFailed) == true else { return }
                shouldReloadAfterMutation = true
            }
        }
        
        reminderOperations.append(.delete(id: operationID, reminderID: id, task: task))
    }
    
    // MARK: - Reminder Mutation Coordination
    
    /// 複数の変更操作の終了と、変更通知または失敗後に実行する再取得を調整する。
    ///
    /// `finishReminderMutation(with:)` は終了した保存・完了状態更新・削除を `reminderOperations.remove(with:)` で取り除き、
    /// 続けて `reloadRemindersAfterMutationIfNeeded()` を呼び出す。
    /// `reloadRemindersAfterMutationIfNeeded()` は再取得が予約され、かつ `.save`・`.toggleCompletion`・`.delete` が
    /// 一つも残っていない場合だけ予約を解除して `loadReminders()` を呼ぶ。
    /// これにより、変更途中に通知から取得した一覧が楽観的に更新した表示を上書きしたり、その一覧がキャッシュへ保存されたりすることを防ぎ、
    /// すべての変更を反映した状態を一度だけ取得する。
    
    /// 保存・完了状態更新・削除の終了を記録し、必要であれば再読み込みする。
    private func finishReminderMutation(with operationID: UUID) {
        reminderOperations.remove(with: operationID)
        reloadRemindersAfterMutationIfNeeded()
    }
    
    /// 再読み込みが予約され、かつ進行中の変更操作がなければ最新状態を再読み込む。
    private func reloadRemindersAfterMutationIfNeeded() {
        guard shouldReloadAfterMutation == true else { return }
        guard hasPendingMutation == false else { return }
        
        shouldReloadAfterMutation = false
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
        shouldReloadAfterMutation = false
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
/// 各操作は実行単位のUUIDで識別し、完了状態更新と削除は対象のリマインダーIDも保持する。
private enum ReminderOperation {
    case save(id: UUID, task: Task<Result<Void, ReminderEditorError>, Never>)
    case toggleCompletion(id: UUID, reminderID: Reminder.ID, task: Task<Void, Never>)
    case delete(id: UUID, reminderID: Reminder.ID, task: Task<Void, Never>)
    case load(id: UUID, task: Task<Void, Never>)
    
    /// この操作を一意に識別するID。
    var id: UUID {
        switch self {
        case .save(let id, _), .toggleCompletion(let id, _, _), .delete(let id, _, _), .load(let id, _): id
        }
    }
    
    /// この操作に紐づくTaskをキャンセルする。
    func cancel() {
        switch self {
        case .save(_, let task): task.cancel()
        case .toggleCompletion(_, _, let task), .delete(_, _, let task), .load(_, let task): task.cancel()
        }
    }
}

private extension Array<ReminderOperation> {
    /// 指定されたIDを用いて、完了した操作を管理対象から削除する。
    mutating func remove(with operationID: UUID) {
        removeAll { $0.id == operationID }
    }
}
