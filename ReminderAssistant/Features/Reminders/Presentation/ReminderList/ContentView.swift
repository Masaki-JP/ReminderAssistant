import SwiftUI

struct ContentView<ReminderStoreType: ReminderStoreProtocol>: View {
    @State var viewModel: ContentViewModel<ReminderStoreType>
    @State var sortOrder = ReminderSortOrder()
    @State var filter = ReminderFilter()
    @State var searchText = ""
    @State var isCreateReminderSheetPresented = false
    @State var isSettingsViewPresented = false
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @AppStorage("lastSelectedListID") var selectedListID: String?
    @AppStorage("reminderDestinationListID") var reminderDestinationListID: String?
    @AppStorage("hasInitializedReminderDestinationList") var hasInitializedReminderDestinationList = false
    
    private let isAccessRequestPreview: Bool

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
            self.isAccessRequestPreview = false
        case .accessRequestPreview(let reminderStore):
            _viewModel = .init(
                wrappedValue: .init(
                    reminderStore: reminderStore,
                    reminderStoreCache: nil,
                    onReminderAccessRevoked: {},
                )
            )
            self.isAccessRequestPreview = true
        }
    }
    
    var selectedList: RAReminderList? {
        viewModel.editableLists.first { $0.id == selectedListID }
    }
    
    var displayedReminders: [RAReminder] {
        sortOrder.sorted(
            viewModel.reminders.filter { reminder in
                let matchesSearchAndFilter =
                (searchText.isEmpty || reminder.title.localizedCaseInsensitiveContains(searchText))
                && filter.matches(reminder)
                
                let matchesSelectedList =
                isAccessRequestPreview || selectedListID.map { reminder.list.id == $0 } ?? true
                
                return matchesSelectedList && matchesSearchAndFilter
            }
        )
    }
    
    var reminderSections: [ReminderListSection] {
        ReminderSectionBuilder(reminders: displayedReminders, sortOrder: sortOrder).build()
    }
    
    var isReminderListEmpty: Bool {
        reminderSections.allSatisfy { $0.reminders.isEmpty }
    }
    
    var body: some View {
        NavigationStack {
            ReminderList(
                sections: reminderSections,
                onToggleCompletion: { reminder in
                    guard isAccessRequestPreview == false else { return }
                    viewModel.onToggleCompletion(reminder)
                },
            )
            .privacySensitive(isAccessRequestPreview)
            .redacted(reason: isAccessRequestPreview ? .privacy : [])
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
                CreateReminderSheet { title, deadline, priority, notes in
                    guard isAccessRequestPreview == false else { return }
                    
                    viewModel.createReminder(
                        title: title,
                        deadline: deadline,
                        priority: priority,
                        notes: notes,
                        listIdentifier: reminderDestinationListID
                    )
                }
            }
            .navigationTitle(selectedList?.title ?? "すべて")
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
                Picker("リスト選択", selection: $selectedListID) {
                    Text("すべて")
                        .tag(Optional<String>.none)
                    
                    ForEach(viewModel.editableLists, id: \.self) { list in
                        Text(list.title)
                            .tag(Optional(list.id))
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "リマインダーを検索")
        .animation(.default, value: viewModel.reminders)
        .onChange(of: viewModel.editableLists) { _, lists in
            selectListIfNeeded(from: lists)
            selectReminderDestinationListIfNeeded(from: lists)
        }
        .task {
            viewModel.setup()
            viewModel.loadReminders()
        }
        .alert("エラー", isPresented: viewModel.errorBindng) {
            if viewModel.error == .reminderDestinationListUnavailable {
                Button("OK", role: .cancel) {}
            } else {
                Button("再読み込み") {
                    guard isAccessRequestPreview == false else { return }
                    viewModel.loadReminders()
                }
            }
        } message: {
            if viewModel.error == .reminderDestinationListUnavailable {
                Text("新規リマインダーの作成先を設定画面で選択してください。")
            }
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
            Text("フィルター条件を変更してみてください。")
        }
    }
}

extension ContentView {
    /// 一覧の表示対象が未設定、または現在の編集可能なリストに存在しない場合、デフォルトリストまたは「すべて」を選択する。
    func selectListIfNeeded(from lists: [RAReminderList]) {
        guard isAccessRequestPreview == false else { return }
        
        guard selectedListID.map({ selectedListID in
            lists.contains(where: { $0.id == selectedListID })
        }) == false else { return }
        
        if let defaultList = lists.first(where: { $0.id == viewModel.defaultListIdentifier }) {
            selectedListID = defaultList.id
        } else {
            selectedListID = nil
        }
    }
    
    /// 初回はデフォルトリストまたは先頭のリストを選択し、設定済みの作成先が無効な場合はエラーを通知する。
    func selectReminderDestinationListIfNeeded(from lists: [RAReminderList]) {
        guard isAccessRequestPreview == false else { return }
        
        if hasInitializedReminderDestinationList == false {
            if reminderDestinationListID == nil {
                guard let list = lists.first(where: { $0.id == viewModel.defaultListIdentifier })
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

#Preview("Light") {
    ContentView(configuration: .production(
        reminderStore: FakeReminderStore(fetchDelay: .seconds(0.3)),
        reminderStoreCache: nil,
        onReminderAccessRevoked: {},
    ))
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView(configuration: .production(
        reminderStore: FakeReminderStore(fetchDelay: .seconds(0.3)),
        reminderStoreCache: nil,
        onReminderAccessRevoked: {},
    ))
    .preferredColorScheme(.dark)
}
