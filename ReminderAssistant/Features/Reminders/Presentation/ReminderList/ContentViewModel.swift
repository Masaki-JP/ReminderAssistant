import SwiftUI

@Observable
final class ContentViewModel<ReminderStoreType: ReminderStoreProtocol> {
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
    
    /// 実行中のリマインダー取得・作成・完了状態更新の操作。
    private var reminderOperations: [ReminderOperation] = .init()
    /// 初回のリマインダー取得時にキャッシュを読み込み済みかどうか。
    private var hasReadInitialCache = false
    /// 完了状態更新の失敗後、進行中の更新がすべて終了した際に再読み込みするかどうか。
    private var shouldReloadAfterCompletionToggleFailure = false
    /// リマインダーの変更通知を解除するためのトークン。
    private var notificationToken: (any NSObjectProtocol)? = nil
    /// リマインダーを取得・作成・更新するストア。
    private let reminderStore: ReminderStoreType
    /// リマインダー一覧をローカルに保存するキャッシュ。
    private let reminderStoreCache: ReminderStoreCache?
    /// リマインダーへのアクセス権限が失効した際の処理。
    private let reminderAccessRevokedHandler: () -> Void
    
    init(
        reminderStore: ReminderStoreType,
        reminderStoreCache: ReminderStoreCache?,
        onReminderAccessRevoked: @escaping () -> Void,
    ) {
        self.reminderStore = reminderStore
        self.reminderStoreCache = reminderStoreCache
        self.reminderAccessRevokedHandler = onReminderAccessRevoked
        
        notificationToken = NotificationCenter.default.addObserver(
            forName: reminderStore.remindersMayHaveChangedNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                guard self?.error == nil else { return }
                self?.loadReminders()
            }
        }
    }
    
    isolated deinit {
        notificationToken.map { NotificationCenter.default.removeObserver($0) }
        reminderOperations.removeAll { $0.cancel(); return true } // ※1
    }
    
    // MARK: - Reminder Creation
    
    func createReminder(_ request: CreateReminderRequest) async throws(CreateReminderError) {
        let operationID = UUID()
        let task = createReminderTask(request: request, operationID: operationID)
        
        reminderOperations.append(.create(operationID: operationID, task: task))
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
    
    private func createReminderTask(
        request: CreateReminderRequest,
        operationID: UUID,
    ) -> Task<Result<Void, CreateReminderError>, Never> {
        Task { [weak self] () -> Result<Void, CreateReminderError> in
            defer { self?.finishReminderMutation(with: .create(operationID)) }
            
            do {
                guard let list = try self?.reminderDestinationList(for: request.listIdentifier) else {
                    return .failure(.cancelled)
                }
                
                try await self?.reminderStore.create(
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
    
    private func reminderDestinationList(for listIdentifier: String?) throws(ContentViewModelError) -> ReminderList {
        if let list = editableLists.first(where: { $0.calendarIdentifier == listIdentifier }) {
            return list
        } else {
            throw .reminderDestinationListUnavailable
        }
    }
    
    private func handleCreateReminderError(_ error: any Error) -> CreateReminderError {
        let createReminderError = resolveCreateReminderError(error)
        
        switch createReminderError {
        case .cancelled: break
        default: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        return createReminderError
    }
    
    // MARK: - Reminder Loading
    
    func loadReminders() {
        cancelLoad()
        
        let shouldReadInitialCache = hasReadInitialCache == false
        hasReadInitialCache = true
        
        let operationID = UUID()
        let task = Task { [weak self, reminderStore = self.reminderStore, reminderStoreCache = self.reminderStoreCache] in
            defer { self?.reminderOperations.removeOperation(with: .load(operationID)) }
            
            do {
                async let fetchedLists = reminderStore.fetch()
                
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
        
        reminderOperations.append(.load(operationID: operationID, task: task))
    }
    
    private func cancelLoad() {
        reminderOperations.removeAll { operation in
            if case .load(_, let loadTask) = operation {
                loadTask.cancel(); return true
            } else {
                return false
            }
        }
    }
    
    // MARK: - Reminder Completion
    
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
    
    private func reminderIndex(for reminder: Reminder) -> (list: Int, reminder: Int)? {
        for listIndex in editableLists.indices {
            if let reminderIndex = editableLists[listIndex].reminders.firstIndex(where: { $0.id == reminder.id }) {
                return (listIndex, reminderIndex)
            }
        }
        return nil
    }
    
    private func hasPendingCompletionToggle(for reminder: Reminder) -> Bool {
        reminderOperations.contains { operation in
            if case .toggleCompletion(let id, _) = operation, id == reminder.id { true } else { false }
        }
    }
    
    private func requestCompletionToggle(for reminder: Reminder) {
        let completion = !reminder.isCompleted
        let task = Task { [weak self] in
            defer { self?.finishReminderMutation(with: .toggleCompletion(reminder.id)) }
            
            try? await Task.sleep(for: .seconds(0.3))
            
            do {
                try await self?.reminderStore.set(id: reminder.id, completion: completion)
                
                guard let index = self?.reminderIndex(for: reminder) else { return }
                self?.editableLists[index.list].reminders[index.reminder].setIsCompleted(completion)
            } catch {
                guard let self else { return }
                guard handleError(error, as: .toggleCompletionFailed) == true else { return }
                shouldReloadAfterCompletionToggleFailure = true
            }
        }
        
        reminderOperations.append(.toggleCompletion(reminderID: reminder.id, task: task))
        cancelLoad()
    }
    
    private func cancelCompletionToggle(for reminder: Reminder) {
        reminderOperations.removeAll { operation in
            if case let .toggleCompletion(id, task) = operation, id == reminder.id {
                task.cancel(); return true
            } else {
                return false
            }
        }
    }
    
    /// 作成・完了状態更新の終了を記録し、必要であれば再読み込みする。
    private func finishReminderMutation(with id: ReminderOperation.ID) {
        reminderOperations.removeOperation(with: id)
        reloadRemindersAfterCompletionToggleFailureIfNeeded()
    }
    
    /// 進行中の作成・完了状態更新がなくなった後、最新状態を再読み込みする。
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
    
    /// リマインダー作成時のエラーを、作成画面で扱うエラーに解決する。
    private func resolveCreateReminderError(_ error: any Error) -> CreateReminderError {
        guard let resolvedError = resolveError(error, as: .createReminderFailed) else {
            return .cancelled
        }
        
        return if (error as? ReminderStoreError) == .deadlineConversionFailed {
            .invalidDeadline
        } else if case .reminderDestinationListUnavailable = resolvedError {
            .destinationListUnavailable
        } else {
            .saveFailed
        }
    }
    
    /// 権限失効とキャンセルを処理し、それ以外を画面表示用エラーに解決する。
    private func resolveError(
        _ error: any Error,
        as fallbackError: ContentViewModelError
    ) -> ContentViewModelError? {
        if (error as? ReminderStoreError) == .accessNotAuthorized {
            handleReminderAccessRevoked()
            return nil
        }
        
        if error is CancellationError || (error as? ReminderStoreError) == .cancelled {
            return nil
        }
        
        return if let contentViewModelError = error as? ContentViewModelError {
            contentViewModelError
        } else if let reminderStoreError = error as? ReminderStoreError, case .listNotFound = reminderStoreError {
            .reminderDestinationListUnavailable
        } else {
            fallbackError
        }
    }
    
    /// 再読み込み予約を解除し、すべての操作をキャンセルして権限失効を通知する。
    private func handleReminderAccessRevoked() {
        shouldReloadAfterCompletionToggleFailure = false
        reminderOperations.removeAll { operation in
            operation.cancel(); return true
        }
        reminderAccessRevokedHandler()
    }
    
    /// エラーを保持し、エラー用の触覚フィードバックを発生させる。
    private func presentError(_ error: ContentViewModelError) {
        self.error = error
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

private enum ReminderOperation {
    enum ID {
        case create(UUID)
        case toggleCompletion(Reminder.ID)
        case load(UUID)
    }
    
    case create(operationID: UUID, task: Task<Result<Void, CreateReminderError>, Never>)
    case toggleCompletion(reminderID: Reminder.ID, task: Task<Void, Never>)
    case load(operationID: UUID, task: Task<Void, Never>)
    
    func cancel() {
        switch self {
        case .create(_, let task):
            task.cancel()
        case .toggleCompletion(_, let task), .load(_, let task):
            task.cancel()
        }
    }
}

private extension Array<ReminderOperation> {
    mutating func removeOperation(with id: ReminderOperation.ID) {
        removeAll { operation in
            switch (operation, id) {
            case let (.create(operationID, _), .create(id)):
                operationID == id
            case let (.toggleCompletion(reminderID, _), .toggleCompletion(id)):
                reminderID == id
            case let (.load(operationID, _), .load(id)):
                operationID == id
            default:
                false
            }
        }
    }
}

/*
 ※1: 作成と更新の処理が完了しないリスクは許容する。
 */
