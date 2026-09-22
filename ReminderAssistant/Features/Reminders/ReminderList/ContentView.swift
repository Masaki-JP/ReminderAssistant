import SwiftUI
import ReminderCore

struct ContentView<ReminderRepositoryType: ReminderRepositoryProtocol>: View {
    @State var viewModel: ContentViewModel<ReminderRepositoryType>
    @State var sortOrder = ReminderSortOrder()
    @State var filter = ReminderFilter()
    @State var searchText = ""
    @State var reminderEditorMode: ReminderEditorMode?
    @State var isSettingsViewPresented = false
    @State var isCustomListStorageErrorPresented = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let isPlaceholder: Bool
    
    @AppStorage(UserDefaultsKey.AppStorageKey.lastDisplayedListID.rawValue)
    var displayedListID: String?
    @AppStorage(UserDefaultsKey.AppStorageKey.customReminderLists.rawValue)
    var customListsData = Data()
    @AppStorage(UserDefaultsKey.AppStorageKey.reminderDestinationListID.rawValue)
    var reminderDestinationListID: String?
    @AppStorage(UserDefaultsKey.AppStorageKey.hasInitializedReminderDestinationList.rawValue)
    var hasInitializedReminderDestinationList = UserDefaultsKey.AppStorageDefaultValue.hasInitializedReminderDestinationList
    
    init(configuration: Configuration) {
        switch configuration {
        case .production(let reminderRepository, let reminderStoreCache, let onReminderAccessRevoked):
            _viewModel = .init(
                wrappedValue: .init(
                    reminderRepository: reminderRepository,
                    reminderStoreCache: reminderStoreCache,
                    onReminderAccessRevoked: onReminderAccessRevoked,
                )
            )
            self.isPlaceholder = false
        case .placeholder(let reminderRepository):
            _viewModel = .init(
                wrappedValue: .init(
                    reminderRepository: reminderRepository,
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

    var customLists: [CustomReminderList] {
        (try? CustomReminderListStorage.decode(customListsData)) ?? []
    }

    var customListsBinding: Binding<[CustomReminderList]> {
        .init(
            get: { customLists },
            set: { lists in
                do {
                    // 既存データが読み込めない場合、書き込みを行わない。
                    _ = try CustomReminderListStorage.decode(customListsData)
                    customListsData = try CustomReminderListStorage.encode(lists)
                } catch {
                    isCustomListStorageErrorPresented = true
                }
            }
        )
    }

    var displayedCustomList: CustomReminderList? {
        guard isPlaceholder == false else { return nil }
        return customLists.first { $0.id.uuidString == displayedListID }
    }

    var selectedReminders: [Reminder] {
        if isPlaceholder || displayedListID == nil {
            viewModel.reminders
        } else if let displayedCustomList {
            displayedCustomList.reminders(in: viewModel.editableLists)
        } else {
            displayedList?.reminders ?? []
        }
    }
    
    var displayedReminders: [Reminder] {
        sortOrder.sorted(
            selectedReminders.filter { reminder in
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
              reminderEditorMode == nil else { return nil }
        
        return { reminderEditorMode = .create }
    }
    
    var body: some View {
        NavigationStack {
            ReminderListView(
                sections: reminderSections,
                onToggleCompletion: { reminder in
                    guard isPlaceholder == false else { return }
                    viewModel.onToggleCompletion(reminder)
                },
                onEdit: { reminder in
                    guard isPlaceholder == false else { return }
                    reminderEditorMode = .edit(reminder)
                },
                onDelete: { id in
                    guard isPlaceholder == false else { return }
                    viewModel.deleteReminder(id: id)
                },
            )
            .privacySensitive(isPlaceholder)
            .redacted(reason: isPlaceholder ? .privacy : [])
            .contentMargins(.top, 8, for: .scrollContent)
            .overlay { reminderListOverlay }
            .sheet(isPresented: $isSettingsViewPresented) {
                SettingsView(
                    reminderDestinationListID: $reminderDestinationListID,
                    customLists: customListsBinding,
                    lists: viewModel.editableLists,
                )
                .preferredColorScheme(colorScheme)
            }
            .sheet(item: $reminderEditorMode) { mode in
                ReminderFormView(
                    mode: mode,
                    destinationLists: viewModel.editableLists,
                    destinationListID: reminderDestinationListID
                ) { draft, destinationListID async throws(ReminderEditorError) in
                    try await saveReminder(draft, mode: mode, destinationListID: destinationListID)
                }
            }
            .navigationTitle(displayedCustomList?.title ?? displayedList?.title ?? "すべて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarTitleMenu { reminderListPicker }
        }
        .searchable(text: $searchText, prompt: "リマインダーを検索")
        .animation(.default, value: viewModel.reminders)
        .task(viewModel.loadReminders)
        .onAppear(perform: validateCustomReminderListsData)
        .onChange(of: viewModel.editableLists) { _, lists in
            ensureDisplayedList(from: lists)
            ensureReminderDestinationList(from: lists)
        }
        .onChange(of: customLists) { oldLists, newLists in
            // 選択していたカスタムリストを削除した場合は「すべて」に戻す。
            if oldLists.contains(where: { $0.id.uuidString == displayedListID }) == true,
               newLists.contains(where: { $0.id.uuidString == displayedListID }) == false {
                displayedListID = nil
            }
        }
        .alert(viewModel.error?.title ?? "エラー", isPresented: viewModel.errorBinding) {
            errorAlertActions
        } message: {
            Text(viewModel.error?.message ?? "")
        }
        .alert("カスタムリストを読み込めません", isPresented: $isCustomListStorageErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("保存済みデータは上書きせずに保持しています。")
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
    
    var toolbar: Self.Toolbar {
        .init(
            sortOrder: $sortOrder,
            filter: $filter,
            reminderEditorMode: $reminderEditorMode,
            isSettingsViewPresented: $isSettingsViewPresented,
            isCreateReminderDisabled: viewModel.editableLists.isEmpty,
            isLoading: viewModel.isLoading,
        )
    }
    
    var reminderListPicker: some View {
        Picker("リスト選択", selection: $displayedListID) {
            Text("すべて").tag(Optional<String>.none)
            
            ForEach(viewModel.editableLists) { list in
                Text(list.title).tag(Optional(list.id))
            }

            if !customLists.isEmpty && !isPlaceholder {
                Section("カスタムリスト") {
                    ForEach(customLists) { list in
                        Label(list.title, systemImage: "square.stack")
                            .tag(Optional(list.id.uuidString))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var errorAlertActions: some View {
        switch viewModel.error?.recoveryBehavior {
        case .retryLoading:
            Button("再読み込み") {
                guard isPlaceholder == false else { return }
                viewModel.loadReminders()
            }
        case .openSettings:
            Button("設定を開く") {
                guard isPlaceholder == false else { return }
                isSettingsViewPresented = true
            }
        case .acknowledge, nil:
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
    func validateCustomReminderListsData() {
        do {
            _ = try CustomReminderListStorage.decode(customListsData)
        } catch {
            isCustomListStorageErrorPresented = true
        }
    }

    func saveReminder(
        _ draft: ReminderDraft,
        mode: ReminderEditorMode,
        destinationListID: ReminderList.ID?,
    ) async throws(ReminderEditorError) {
        guard isPlaceholder == false else { throw .cancelled }
        try await viewModel.saveReminder(draft, mode: mode, listIdentifier: destinationListID)
    }
    
    /// 選択中の通常リストが利用できない場合、デフォルトリストまたは「すべて」に戻す。カスタムリストは構成元が利用できなくても選択を保持する。
    ///
    func ensureDisplayedList(from lists: [ReminderList]) {
        guard isPlaceholder == false else { return }
        guard displayedCustomList == nil else { return }
        
        // 選択中のリストが指定されたリスト群（[ReminderList]）に含まれている場合は終了する。
        guard displayedListID.map({ displayedListID in
            lists.contains(where: { $0.id == displayedListID })
        }) == false else { return }
        
        // 選択中のリストがない、または利用できなくなった場合は、デフォルトリストを選択する。デフォルトリストがない場合は「すべて」を選択する。
        displayedListID = if let defaultList = lists.first(where: \.isDefault) {
            defaultList.id
        } else {
            nil
        }
    }
    
    /// 初回はリマインダーの作成先のリスト（``reminderDestinationListID``）をデフォルトリスト、または先頭のリストに設定する。設定済みのリマインダー作成先が無効な場合はエラーを通知する。
    ///
    func ensureReminderDestinationList(from lists: [ReminderList]) {
        guard isPlaceholder == false else { return }
        
        // 初回のみ実行する。作成先が未設定であればデフォルトリスト、または先頭のリストを作成先に設定する。
        if hasInitializedReminderDestinationList == false {
            if reminderDestinationListID == nil {
                guard let list = lists.first(where: \.isDefault) ?? lists.first else { return }
                reminderDestinationListID = list.id
            }
            
            hasInitializedReminderDestinationList = true
        }
        
        // 作成先が未設定、または指定されたリスト群（[ReminderList]）に存在しない場合は、エラーを通知する。
        guard reminderDestinationListID.map({ reminderDestinationListID in
            lists.contains(where: { $0.id == reminderDestinationListID })
        }) == false else { return }
        
        // 無効な作成先をクリアし、作成先の再選択を促す。
        reminderDestinationListID = nil
        viewModel.reportReminderDestinationListUnavailable()
    }
}

#if DEBUG
private let previewContent = ContentView(configuration: .production(
    reminderRepository: FakeReminderRepository(fetchDelay: .seconds(0.3)),
    reminderStoreCache: nil,
    onReminderAccessRevoked: {},
))

#Preview("Light") { previewContent.preferredColorScheme(.light) }
#Preview("Dark") { previewContent.preferredColorScheme(.dark) }
#endif
