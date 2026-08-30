import SwiftUI

extension ContentView {
    struct Toolbar: ToolbarContent {
        @Binding var sortOrder: ReminderSortOrder
        @Binding var filter: ReminderFilter
        @Binding var isCreateReminderSheetPresented: Bool
        @Binding var isSettingsViewPresented: Bool
        let isCreateReminderDisabled: Bool
        
        var body: some ToolbarContent {
            if UIDevice.current.userInterfaceIdiom == .phone {
                phoneToolbarContent
            } else {
                padToolbarContent
            }
        }
        
        @ToolbarContentBuilder
        var phoneToolbarContent: some ToolbarContent {
            // MARK: - topBarLeading
            
            ToolbarItemGroup(placement: .topBarLeading) {
                SortMenu(sortOrder: $sortOrder)
                
                FilterMenu(filter: $filter)
            }
            .sharedBackgroundVisibility(.hidden)
            
            // MARK: - topBarTrailing
            
            ToolbarItem(placement: .topBarTrailing) {
                settingsButton
            }
            .sharedBackgroundVisibility(.hidden)
            
            // MARK: - bottomBar
            
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            
            ToolbarItem(placement: .bottomBar) {
                createReminderButton
            }
        }
        
        @ToolbarContentBuilder
        var padToolbarContent: some ToolbarContent {
            // MARK: - topBarLeading
            
            ToolbarItemGroup(placement: .topBarLeading) {
                settingsButton
                
                SortMenu(sortOrder: $sortOrder)
                
                FilterMenu(filter: $filter)
            }
            
            // MARK: - bottomBar
            
            ToolbarSpacer(.flexible, placement: .bottomBar)
            
            ToolbarItem(placement: .bottomBar) {
                createReminderButton
            }
        }
        
        var settingsButton: some View {
            Button("設定", systemImage: "gearshape") {
                isSettingsViewPresented = true
            }
        }
        
        var createReminderButton: some View {
            Button("作成", systemImage: "plus") {
                isCreateReminderSheetPresented = true
            }
            .buttonStyle(.glassProminent)
            .disabled(isCreateReminderDisabled)
        }
    }
}

private struct SortMenu: View {
    @Binding var sortOrder: ReminderSortOrder
    
    var body: some View {
        Menu("並び替え", systemImage: "arrow.up.arrow.down") {
            Picker("並び替えの基準", selection: $sortOrder.field) {
                ForEach(ReminderSortOrder.Field.allCases) { field in
                    Text(field.displayName).tag(field)
                }
            }
            
            Picker("順序", selection: $sortOrder.direction) {
                ForEach(ReminderSortOrder.Direction.allCases) { direction in
                    Text(direction.displayName).tag(direction)
                }
            }
            
            Divider()
            
            Button("リセット", role: .destructive) {
                sortOrder = .defaultValue
            }
            .disabled(sortOrder.isDefault)
        }
        .menuActionDismissBehavior(.disabled)
    }
}

private struct FilterMenu: View {
    @Binding var filter: ReminderFilter
    
    var body: some View {
        Menu("絞り込み", systemImage: "line.3.horizontal.decrease") {
            Picker("完了状態", selection: $filter.completionStatus) {
                ForEach(ReminderFilter.CompletionStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }
            .labelsVisibility(.visible)
            
            Picker("期限", selection: $filter.dueDateCondition) {
                ForEach(ReminderFilter.DueDateCondition.allCases) { condition in
                    Text(condition.displayName).tag(condition)
                }
            }
            .labelsVisibility(.visible)
            
            Divider()
            
            Section {
                ForEach(RAReminder.Priority.allCases) { priority in
                    Toggle(priority.displayName, isOn: priorityBinding(for: priority))
                }
            } header: {
                Text("優先度")
            }
            
            Divider()
            
            Picker("備考", selection: $filter.notesAvailability) {
                ForEach(ReminderFilter.NotesAvailability.allCases) { availability in
                    Text(availability.displayName).tag(availability)
                }
            }
            .pickerStyle(.menu)
            
            dateConditionPicker(title: "作成日時", selection: $filter.creationDateCondition)
            
            dateConditionPicker(title: "更新日時", selection: $filter.lastModifiedDateCondition)
            
            dateConditionPicker(title: "完了日時", selection: $filter.completionDateCondition)
            
            Divider()
            
            Button("リセット", role: .destructive) {
                filter = .defaultValue
            }
            .disabled(filter.isDefault)
        }
        .menuActionDismissBehavior(.disabled)
        .badge(filter.isDefault ? 0 : activeFilterCount)
    }
    
    var activeFilterCount: Int {
        [
            filter.completionStatus != ReminderFilter.defaultValue.completionStatus,
            filter.dueDateCondition != ReminderFilter.defaultValue.dueDateCondition,
            filter.notesAvailability != ReminderFilter.defaultValue.notesAvailability,
            filter.priorities.isEmpty == false,
            filter.creationDateCondition != ReminderFilter.defaultValue.creationDateCondition,
            filter.lastModifiedDateCondition != ReminderFilter.defaultValue.lastModifiedDateCondition,
            filter.completionDateCondition != ReminderFilter.defaultValue.completionDateCondition
        ]
            .count { $0 }
    }
    
    func priorityBinding(for priority: RAReminder.Priority) -> Binding<Bool> {
        .init(
            get: { filter.priorities.contains(priority) },
            set: { if $0 { filter.priorities.insert(priority) } else { filter.priorities.remove(priority) } }
        )
    }
    
    func dateConditionPicker(
        title: String,
        selection: Binding<ReminderFilter.DateCondition>
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(ReminderFilter.DateCondition.allCases) { condition in
                Text(condition.displayName).tag(condition)
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    ContentView()
}
