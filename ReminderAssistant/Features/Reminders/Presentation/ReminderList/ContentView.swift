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
            .overlay { reminderListOverlay }
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
            .toolbar { toolbar }
            .toolbarTitleMenu { reminderListPicker }
        }
        .searchable(text: $searchText, prompt: "リマインダーを検索")
        .animation(.default, value: viewModel.reminders)
        .task(viewModel.loadReminders)
        .onChange(of: viewModel.editableLists) { _, lists in
            ensureDisplayedList(from: lists)
            ensureReminderDestinationList(from: lists)
        }
        .alert(viewModel.error?.title ?? "エラー", isPresented: viewModel.errorBinding) {
            errorAlertActions
        } message: {
            Text(viewModel.error?.message ?? "")
        }
        .focusedSceneValue(\.presentCreateReminderSheetAction, presentCreateReminderSheetAction)
    }
    
    @ViewBuilder
    var reminderListOverlay: some View {
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
    
    var toolbar: Toolbar {
        Toolbar(
            sortOrder: $sortOrder,
            filter: $filter,
            isCreateReminderSheetPresented: $isCreateReminderSheetPresented,
            isSettingsViewPresented: $isSettingsViewPresented,
            isCreateReminderDisabled: viewModel.editableLists.isEmpty,
            isLoading: viewModel.isLoading,
        )
    }
    
    var reminderListPicker: some View {
        Picker("リスト選択", selection: $displayedListID) {
            Text("すべて")
                .tag(Optional<String>.none)
            
            ForEach(viewModel.editableLists) { list in
                Text(list.title)
                    .tag(Optional(list.id))
            }
        }
    }
    
    @ViewBuilder
    var errorAlertActions: some View {
        switch viewModel.error?.recoveryAction {
        case .reload:
            Button("再読み込み") {
                guard isPlaceholder == false else { return }
                viewModel.loadReminders()
            }
        case .dismiss, nil:
            Button("OK", role: .cancel) {}
        }
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
            Text("絞り込み条件を変更してみてください。")
        }
    }
}

extension ContentView {
    func createReminder(_ request: CreateReminderRequest) async throws(CreateReminderError) {
        guard isPlaceholder == false else { throw .cancelled }
        
        var request = request
        request.listIdentifier = reminderDestinationListID
        try await viewModel.createReminder(request)
    }
    
    /// 表示対象のリスト（``displayedListID``）が未設定、または現在の編集可能なリストに存在しない場合、表示対象のリストにデフォルトリスト、または「すべて（`nil`）」を設定する。
    ///
    func ensureDisplayedList(from lists: [ReminderList]) {
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
    func ensureReminderDestinationList(from lists: [ReminderList]) {
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
