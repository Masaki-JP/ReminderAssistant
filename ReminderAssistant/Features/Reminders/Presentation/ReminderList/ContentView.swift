import SwiftUI

struct ContentView<ReminderStoreType: ReminderStoreProtocol>: View {
    @State var viewModel: ContentViewModel<ReminderStoreType>
    @State var sortOrder = ReminderSortOrder()
    @State var filter = ReminderFilter()
    @State var searchText = ""
    @State var isCreateReminderSheetPresented = false
    @State var isSettingsViewPresented = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let isPlaceholder: Bool
    
    @AppStorage(UserDefaultsKey.AppStorageKey.lastDisplayedListID.rawValue)
    var displayedListID: String?
    @AppStorage(UserDefaultsKey.AppStorageKey.reminderDestinationListID.rawValue)
    var reminderDestinationListID: String?
    @AppStorage(UserDefaultsKey.AppStorageKey.hasInitializedReminderDestinationList.rawValue)
    var hasInitializedReminderDestinationList = UserDefaultsKey.AppStorageDefaultValue.hasInitializedReminderDestinationList
    
    init(configuration: Configuration) {
        switch configuration {
        case .production(let reminderStore, let reminderStoreCache, let onReminderAccessRevoked):
            _viewModel = .init(
                wrappedValue: .init(
                    reminderStore: reminderStore,
                    reminderStoreCache: reminderStoreCache,
                    onReminderAccessRevoked: onReminderAccessRevoked,
                )
            )
            self.isPlaceholder = false
        case .placeholder(let reminderStore):
            _viewModel = .init(
                wrappedValue: .init(
                    reminderStore: reminderStore,
                    reminderStoreCache: nil,
                    onReminderAccessRevoked: {},
                )
            )
            self.isPlaceholder = true
        }
    }
    
    var displayedList: ReminderList? {
        viewModel.editableLists.first { $0.id == displayedListID }
    }
    
    var displayedReminders: [Reminder] {
        sortOrder.sorted(
            viewModel.editableLists.filter { list in
                isPlaceholder || displayedListID.map { list.id == $0 } ?? true
            }.flatMap(\.reminders).filter { reminder in
                (searchText.isEmpty || reminder.title.localizedCaseInsensitiveContains(searchText))
                && filter.matches(reminder)
            }
        )
    }
    
    var reminderSections: [ReminderListSection] {
        ReminderSectionBuilder(reminders: displayedReminders, sortOrder: sortOrder).build()
    }
    
    var isReminderListEmpty: Bool {
        reminderSections.allSatisfy { $0.reminders.isEmpty }
    }
    
    var presentCreateReminderSheetAction: (() -> Void)? {
        guard isPlaceholder == false,
              viewModel.editableLists.isEmpty == false,
              isSettingsViewPresented == false,
              isCreateReminderSheetPresented == false else { return nil }
        
        return { isCreateReminderSheetPresented = true }
    }
    
    var body: some View {
        NavigationStack {
            ReminderListView(
                sections: reminderSections,
                onToggleCompletion: { reminder in
                    guard isPlaceholder == false else { return }
                    viewModel.onToggleCompletion(reminder)
                },
            )
            .privacySensitive(isPlaceholder)
            .redacted(reason: isPlaceholder ? .privacy : [])
            .contentMargins(.top, 8, for: .scrollContent)
            .overlay {
                if viewModel.isLoading && viewModel.editableLists.isEmpty && viewModel.reminders.isEmpty {
                    ProgressView()
                } else if viewModel.editableLists.isEmpty == true {
                    noEditableReminderListsPlaceholder
                } else if viewModel.reminders.isEmpty == true {
                    emptyRemindersPlaceholder
                } else if isReminderListEmpty == true {
                    if searchText.isEmpty == false {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        noMatchingRemindersPlaceholder
                    }
                }
            }
            .sheet(isPresented: $isSettingsViewPresented) {
                SettingsView(
                    reminderDestinationListID: $reminderDestinationListID,
                    lists: viewModel.editableLists
                )
                .preferredColorScheme(colorScheme)
            }
            .sheet(isPresented: $isCreateReminderSheetPresented) {
                CreateReminderSheet(onConfirm: createReminder)
            }
            .navigationTitle(displayedList?.title ?? "すべて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Toolbar(
                    sortOrder: $sortOrder,
                    filter: $filter,
                    isCreateReminderSheetPresented: $isCreateReminderSheetPresented,
                    isSettingsViewPresented: $isSettingsViewPresented,
                    isCreateReminderDisabled: viewModel.editableLists.isEmpty,
                    isLoading: viewModel.isLoading,
                )
            }
            .toolbarTitleMenu {
                Picker("リスト選択", selection: $displayedListID) {
                    Text("すべて")
                        .tag(Optional<String>.none)
                    
                    ForEach(viewModel.editableLists) { list in
                        Text(list.title)
                            .tag(Optional(list.id))
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "リマインダーを検索")
        .animation(.default, value: viewModel.reminders)
        .task(viewModel.loadReminders)
        .onChange(of: viewModel.editableLists) { _, lists in
            selectListIfNeeded(from: lists)
            selectReminderDestinationListIfNeeded(from: lists)
        }
        .alert(viewModel.error?.title ?? "エラー", isPresented: viewModel.errorBinding) {
            switch viewModel.error?.recoveryAction {
            case .reload:
                Button("再読み込み") {
                    guard isPlaceholder == false else { return }
                    viewModel.loadReminders()
                }
            case .dismiss, nil:
                Button("OK", role: .cancel) {}
            }
        } message: {
            if let error = viewModel.error {
                Text(error.message)
            }
        }
        .focusedSceneValue(\.presentCreateReminderSheetAction, presentCreateReminderSheetAction)
    }
    
    var emptyRemindersPlaceholder: some View {
        ContentUnavailableView {
            Label("リマインダーはありません", systemImage: "checklist")
        } description: {
            Text("右下の＋ボタンからリマインダーを作成できます。")
        }
    }
    
    var noEditableReminderListsPlaceholder: some View {
        ContentUnavailableView {
            Label("編集可能なリストはありません", systemImage: "checklist")
        } description: {
            Text("リマインダーアプリで編集可能なリストを\n作成してください。")
        }
    }
    
    var noMatchingRemindersPlaceholder: some View {
        ContentUnavailableView {
            Label("該当なし", systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text("フィルター条件を変更してみてください。")
        }
    }
}

extension ContentView {
    func createReminder(
        _ title: String,
        _ deadline: String,
        _ priority: Reminder.Priority,
        _ notes: String
    ) async throws(CreateReminderError) {
        guard isPlaceholder == false else { throw .cancelled }
        
        try await viewModel.createReminder(
            title: title,
            deadline: deadline,
            priority: priority,
            notes: notes,
            listIdentifier: reminderDestinationListID
        )
    }
    
    /// 表示対象のリスト（``displayedListID``）が未設定、または現在の編集可能なリストに存在しない場合、表示対象のリストにデフォルトリスト、または「すべて（`nil`）」を設定する。
    ///
    func selectListIfNeeded(from lists: [ReminderList]) {
        guard isPlaceholder == false else { return }
        
        guard displayedListID.map({ displayedListID in
            lists.contains(where: { $0.id == displayedListID })
        }) == false else { return }
        
        if let defaultList = lists.first(where: \.isDefault) {
            displayedListID = defaultList.id
        } else {
            displayedListID = nil
        }
    }
    
    /// 初回はリマインダーの作成先のリスト（``reminderDestinationListID``）をデフォルトリスト、または先頭のリストに設定する。設定済みのリマインダー作成先が無効な場合はエラーを通知する。
    ///
    func selectReminderDestinationListIfNeeded(from lists: [ReminderList]) {
        guard isPlaceholder == false else { return }
        
        if hasInitializedReminderDestinationList == false {
            if reminderDestinationListID == nil {
                guard let list = lists.first(where: \.isDefault)
                        ?? lists.first else { return }
                
                reminderDestinationListID = list.id
            }
            
            hasInitializedReminderDestinationList = true
        }
        
        guard reminderDestinationListID.map({ reminderDestinationListID in
            lists.contains(where: { $0.id == reminderDestinationListID })
        }) == false else { return }
        
        reminderDestinationListID = nil
        viewModel.reportReminderDestinationListUnavailable()
    }
}

#if DEBUG
private let previewContent = ContentView(configuration: .production(
    reminderStore: FakeReminderStore(fetchDelay: .seconds(0.3)),
    reminderStoreCache: nil,
    onReminderAccessRevoked: {},
))

#Preview("Light") { previewContent.preferredColorScheme(.light) }
#Preview("Dark") { previewContent.preferredColorScheme(.dark) }
#endif
