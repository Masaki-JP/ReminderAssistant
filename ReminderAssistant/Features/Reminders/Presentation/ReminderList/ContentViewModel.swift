import SwiftUI

@Observable
final class ContentViewModel<ReminderStoreType: ReminderStoreProtocol> {
    private(set) var reminders: [Reminder] = []
    private(set) var editableLists: [ReminderList] = []
    private(set) var defaultListIdentifier: String?
    
    private(set) var error: ContentViewModelError? = nil
    var errorBinding: Binding<Bool> {
        .init(
            get: { self.error != nil },
            set: { if $0 == false { self.error = nil } }
        )
    }
    
    private var reminderOperations: [ReminderOperation] = .init()
    private var hasReadInitialCache = false
    private var shouldReloadAfterCompletionToggleFailure = false
    
    private let reminderStore: ReminderStoreType
    private let reminderStoreCache: ReminderStoreCache?
    private var notificationToken: (any NSObjectProtocol)? = nil
    
    private let reminderAccessRevokedHandler: () -> Void
    
    var isLoading: Bool {
        (reminderOperations.first).map { operation in
            if case .load = operation { true } else { false }
        } ?? false
    }
    
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
        if let notificationToken {
            NotificationCenter.default.removeObserver(notificationToken)
        }
        
        /// 作成と更新の処理が完了しないリスクは許容する。
        reminderOperations.removeAll { operation in
            operation.cancel(); return true
        }
    }
    
    // MARK: - Reminder Creation
    
    func createReminder(
        title: String,
        deadline: String,
        priority: Reminder.Priority,
        notes: String,
        listIdentifier: String?,
    ) async throws(CreateReminderError) {
        let operationID = UUID()
        let task = Task { [weak self] () -> Result<Void, CreateReminderError> in
            defer { self?.finishReminderMutation(with: .create(operationID)) }
            
            do {
                guard let list = self?.editableLists.first(where: { $0.calendarIdentifier == listIdentifier }) else {
                    throw ContentViewModelError.reminderDestinationListUnavailable
                }
                
                try await self?.reminderStore.create(.init(
                    title: title,
                    deadline: deadline,
                    priority: priority,
                    notes: notes,
                    list: list,
                ))
            } catch {
                guard let self else { return .failure(.cancelled) }
                let createReminderError = self.resolveCreateReminderError(error)
                
                switch createReminderError {
                case .cancelled: break
                default: UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
                
                return .failure(createReminderError)
            }
            
            guard self != nil else { return .failure(.cancelled) }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return .success(())
        }
        
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
    
    // MARK: - Reminder Loading
    
    func loadReminders() {
        cancelLoad()
        
        let shouldReadInitialCache = hasReadInitialCache == false
        hasReadInitialCache = true
        
        let operationID = UUID()
        let task = Task { [weak self, reminderStore = self.reminderStore, reminderStoreCache = self.reminderStoreCache] in
            defer { self?.reminderOperations.removeOperation(with: .load(operationID)) }
            
            do {
                async let fetchedResult = reminderStore.fetch()
                
                if shouldReadInitialCache,
                   let cachedResult = await reminderStoreCache?.fetch() {
                    try Task.checkCancellation()
                    self?.apply(cachedResult)
                }
                
                let fetchResult = try await fetchedResult
                try Task.checkCancellation()
                self?.apply(fetchResult)
                await reminderStoreCache?.save(fetchResult)
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
    
    private func apply(_ result: ReminderStoreFetchResult) {
        reminders = result.reminders
        editableLists = result.editableLists
        defaultListIdentifier = result.defaultListIdentifier
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
        reminders[index].setDisplayedIsCompleted(newValue)
    }
    
    private func reminderIndex(for reminder: Reminder) -> [Reminder].Index? {
        reminders.firstIndex { $0.id == reminder.id }
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
                self?.reminders[index].setIsCompleted(completion)
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
            shouldReloadAfterCompletionToggleFailure = false
            reminderOperations.removeAll { operation in
                operation.cancel(); return true
            }
            reminderAccessRevokedHandler(); return nil
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

/// リマインダー一覧画面で表示するエラー。
enum ContentViewModelError: Error {
    case createReminderFailed
    case loadRemindersFailed
    case toggleCompletionFailed
    case reminderDestinationListUnavailable

    enum RecoveryAction {
        case dismiss
        case reload
    }

    var title: String {
        switch self {
        case .createReminderFailed:
            "作成失敗"
        case .loadRemindersFailed:
            "読み込み失敗"
        case .toggleCompletionFailed:
            "更新失敗"
        case .reminderDestinationListUnavailable:
            "作成先を選択してください"
        }
    }

    var message: String {
        switch self {
        case .createReminderFailed:
            "新規リマインダーを作成できませんでした。もう一度お試しください。"
        case .loadRemindersFailed:
            "リマインダーを読み込めませんでした。もう一度お試しください。"
        case .toggleCompletionFailed:
            "完了状態を更新できませんでした。最新の状態を再読み込みします。"
        case .reminderDestinationListUnavailable:
            "新規リマインダーの作成先を設定画面で選択してください。"
        }
    }

    var recoveryAction: RecoveryAction {
        switch self {
        case .loadRemindersFailed:
            .reload
        case .createReminderFailed, .toggleCompletionFailed, .reminderDestinationListUnavailable:
            .dismiss
        }
    }
}

/// リマインダー作成画面へ通知するエラー。
enum CreateReminderError: Error {
    case invalidDeadline
    case destinationListUnavailable
    case saveFailed
    case cancelled
}
