import SwiftUI

@Observable
final class ContentViewModel<ReminderStoreType: ReminderStoreProtocol, ReminderStoreCacheType: ReminderStoreCacheProtocol> {
    private(set) var reminders: [RAReminder] = []
    private(set) var editableLists: [RAReminderList] = []
    private(set) var defaultListIdentifier: String?
    
    private(set) var error: ContentViewModelError? = nil
    var errorBindng: Binding<Bool> {
        .init(
            get: { self.error != nil },
            set: { if $0 == false { self.error = nil } }
        )
    }
    
    private var reminderOperations: [ReminderOperation] = .init()
    private var hasReadInitialCache = false
    
    private let reminderStore: ReminderStoreType
    private let reminderStoreCache: ReminderStoreCacheType?
    private var notificationToken: (any NSObjectProtocol)? = nil
    
    var isLoading: Bool {
        reminderOperations.contains {
            if case .load = $0 { return true }
            return false
        }
    }
    
    init(
        reminderStore: ReminderStoreType = ReminderStore.shared,
        reminderStoreCache: ReminderStoreCacheType? = nil
    ) {
        self.reminderStore = reminderStore
        self.reminderStoreCache = reminderStoreCache
    }
    
    isolated deinit {
        if let notificationToken {
            NotificationCenter.default.removeObserver(notificationToken)
        }

        /// 作成と更新の処理が完了しないリスクは許容する。
        reminderOperations.removeAll { operation in
            operation.cancel()
            return true
        }
    }
    
    func createReminder(
        title: String,
        deadline: String,
        priority: RAReminder.Priority,
        notes: String,
        listIdentifier: String?,
    ) {
        let operationID = UUID()
        let task = Task {
            defer { reminderOperations.removeOperation(with: .create(operationID)) }
            
            do {
                guard let list = editableLists.first(where: { $0.calendarIdentifier == listIdentifier }) else {
                    throw ContentViewModelError.reminderDestinationListUnavailable
                }
                
                try await reminderStore.create(.init(
                    title: title,
                    deadline: deadline,
                    priority: priority,
                    notes: notes,
                    list: list,
                ))
            } catch {
                handleError(error, as: .createReminderFailed)
            }
        }
        
        reminderOperations.append(.create(operationID: operationID, task: task))
        cancelLoad()
    }
    
    func onToggleCompletion(_ reminder: RAReminder) {
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
    
    func loadReminders() {
        cancelLoad()
        
        let shouldReadInitialCache = hasReadInitialCache == false
        hasReadInitialCache = true
        
        let operationID = UUID()
        let task = Task {
            defer { reminderOperations.removeOperation(with: .load(operationID)) }
            
            do {
                async let fetchedResult = reminderStore.fetch()
                
                if shouldReadInitialCache,
                   let cachedResult = await reminderStoreCache?.fetch() {
                    try Task.checkCancellation()
                    apply(cachedResult)
                }
                
                let fetchResult = try await fetchedResult
                try Task.checkCancellation()
                apply(fetchResult)
                await reminderStoreCache?.save(fetchResult)
            } catch {
                handleError(error, as: .loadRemindersFailed)
            }
        }
        
        reminderOperations.append(.load(operationID: operationID, task: task))
    }
    
    private func apply(_ result: ReminderStoreFetchResult) {
        reminders = result.reminders
        editableLists = result.editableLists
        defaultListIdentifier = result.defaultListIdentifier
    }
    
    private func reminderIndex(for reminder: RAReminder) -> [RAReminder].Index? {
        reminders.firstIndex { $0.id == reminder.id }
    }
    
    private func hasPendingCompletionToggle(for reminder: RAReminder) -> Bool {
        reminderOperations.contains { operation in
            if case .toggleCompletion(let id, _) = operation, id == reminder.id { true } else { false }
        }
    }
    
    private func requestCompletionToggle(for reminder: RAReminder) {
        let completion = !reminder.isCompleted
        let task = Task {
            defer { reminderOperations.removeOperation(with: .toggleCompletion(reminder.id)) }
            
            try? await Task.sleep(for: .seconds(0.3))
            
            do {
                try await reminderStore.set(id: reminder.id, completion: completion)
                
                guard let index = reminderIndex(for: reminder) else { return }
                reminders[index].setIsCompleted(completion)
            } catch {
                handleError(error, as: .toggleCompletionFailed)
            }
        }
        
        reminderOperations.append(.toggleCompletion(reminderID: reminder.id, task: task))
        cancelLoad()
    }
    
    private func cancelCompletionToggle(for reminder: RAReminder) {
        reminderOperations.removeAll { operation in
            if case let .toggleCompletion(id, task) = operation, id == reminder.id {
                task.cancel()
                return true
            } else {
                return false
            }
        }
    }
    
    func cancelLoad() {
        reminderOperations.removeAll { operation in
            if case .load(_, let loadTask) = operation {
                loadTask.cancel()
                return true
            } else {
                return false
            }
        }
    }

    func reportReminderDestinationListUnavailable() {
        error = .reminderDestinationListUnavailable
    }
    
    private func handleError(_ error: any Error, as fallbackError: ContentViewModelError) {
        if error is CancellationError || (error as? ReminderStoreError) == .cancelled {
            return
        }
        
        reminderOperations.removeAll { operation in
            operation.cancel()
            return true
        }
        
        if let contentViewModelError = error as? ContentViewModelError {
            self.error = contentViewModelError
        } else if let reminderStoreError = error as? ReminderStoreError, case .listNotFound = reminderStoreError {
            self.error = .reminderDestinationListUnavailable
        } else {
            self.error = fallbackError
        }
    }
    
    func setup() {
        guard notificationToken == nil else { return }
        
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
}

enum ReminderOperation {
    enum ID {
        case create(UUID)
        case toggleCompletion(RAReminder.ID)
        case load(UUID)
    }

    case create(operationID: UUID, task: Task<Void, Never>)
    case toggleCompletion(reminderID: RAReminder.ID, task: Task<Void, Never>)
    case load(operationID: UUID, task: Task<Void, Never>)
    
    func cancel() {
        switch self {
        case .create(_, let task), .toggleCompletion(_, let task), .load(_, let task):
            task.cancel()
        }
    }
}

extension Array<ReminderOperation> {
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

enum ContentViewModelError: Error, Equatable {
    case createReminderFailed
    case loadRemindersFailed
    case toggleCompletionFailed
    case reminderDestinationListUnavailable
}
