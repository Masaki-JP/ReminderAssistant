import SwiftUI
import ReminderCore

struct CustomListFormView: View {
    /// フォームで編集中のカスタムリスト名。
    @State var customListTitle: String
    /// フォームで編集中の構成元リスト ID。
    @State var sourceListIDs: Set<String>
    /// 保存後にフォームを閉じるためのアクション。
    @Environment(\.dismiss) var dismiss
    /// 編集するカスタムリスト。nil の場合は新規作成する。
    let customList: CustomReminderList?
    /// カスタムリストの構成元として選択できる通常リスト。
    let selectableLists: [ReminderList]
    /// 重複する名前を検証するための既存のカスタムリスト。
    let customLists: [CustomReminderList]
    /// 保存するカスタムリストを呼び出し元へ渡すアクション。
    let saveAction: (CustomReminderList) -> Void
    
    init(
        customList: CustomReminderList? = nil,
        selectableLists: [ReminderList],
        customLists: [CustomReminderList],
        onSave: @escaping (CustomReminderList) -> Void,
    ) {
        self._customListTitle = .init(initialValue: customList?.title ?? "")
        self._sourceListIDs = .init(initialValue: customList?.listIDs ?? [])
        self.customList = customList
        self.selectableLists = selectableLists
        self.customLists = customLists
        self.saveAction = onSave
    }
    
    var isCreatingNewCustomList: Bool { customList == nil }

    var unavailableListIDs: Set<String> { sourceListIDs.subtracting(selectableLists.map(\.id)) }

    var hasDuplicateTitle: Bool {
        CustomReminderList.hasDuplicateTitle(customListTitle, in: customLists, excludingListID: customList?.id)
    }

    var canSave: Bool {
        CustomReminderList.canSave(
            title: customListTitle,
            listIDs: sourceListIDs,
            in: selectableLists,
            customLists: customLists,
            excludingListID: customList?.id,
        )
    }
    
    var body: some View {
        Form {
            Section {
                TextField("マイカスタムリスト", text: $customListTitle)
            } header: {
                Text("名前")
            } footer: {
                if hasDuplicateTitle == true {
                    Text("同名のカスタムリストがあります。別の名前を設定してください。")
                        .foregroundStyle(.red)
                }
            }

            Section {
                ForEach(selectableLists) { list in
                    Toggle(list.title, isOn: selectionBinding(for: list.id))
                }
            } header: {
                Text("対象リスト")
            } footer: {
                Text("表示するリストを2つ以上選択してください。")
            }

            if unavailableListIDs.isEmpty == false {
                Section {
                    Button("利用できないリストを組み合わせから外す", role: .destructive) {
                        sourceListIDs.subtract(unavailableListIDs)
                    }
                } footer: {
                    Text("選択したリストのうち\(unavailableListIDs.count)件が利用できません。再び利用可能になると表示に含まれます。")
                }
            }
        }
        .navigationTitle(isCreatingNewCustomList ? "新規作成" : "編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .confirm, action: save)
                    .accessibilityLabel("保存")
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(canSave == false)
            }
        }
    }
}

extension CustomListFormView {
    func selectionBinding(for listID: String) -> Binding<Bool> {
        .init(
            get: { sourceListIDs.contains(listID) },
            set: { if $0 { sourceListIDs.insert(listID) } else { sourceListIDs.remove(listID) } }
        )
    }
    
    func save() {
        guard canSave == true else { return }
        saveAction(.init(id: customList?.id ?? .init(), title: customListTitle.trimmingCharacters(in: .whitespacesAndNewlines), listIDs: sourceListIDs))
        dismiss()
    }
}

#Preview {
    CustomListFormView(selectableLists: [
        .init(id: "a", title: "リストA", isDefault: true, reminders: []),
        .init(id: "b", title: "リストB", isDefault: false, reminders: []),
        .init(id: "c", title: "リストC", isDefault: false, reminders: []),
    ], customLists: []) { _ in }
}
