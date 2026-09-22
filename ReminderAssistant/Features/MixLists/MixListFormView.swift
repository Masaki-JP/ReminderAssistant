import SwiftUI
import ReminderCore

struct MixListFormView: View {
    /// フォームで編集中のミックスリスト名。
    @State var mixListTitle: String
    /// フォームで編集中の構成元リスト ID。
    @State var sourceListIDs: Set<String>
    /// 保存後にフォームを閉じるためのアクション。
    @Environment(\.dismiss) var dismiss
    /// 編集するミックスリスト。nil の場合は新規作成する。
    let mixList: MixReminderList?
    /// ミックスリストの構成元として選択できる通常リスト。
    let selectableLists: [ReminderList]
    /// 重複する名前を検証するための既存のミックスリスト。
    let mixLists: [MixReminderList]
    /// 保存するミックスリストを呼び出し元へ渡すアクション。
    let saveAction: (MixReminderList) -> Void
    
    init(
        mixList: MixReminderList? = nil,
        selectableLists: [ReminderList],
        mixLists: [MixReminderList],
        onSave: @escaping (MixReminderList) -> Void,
    ) {
        self._mixListTitle = .init(initialValue: mixList?.title ?? "")
        self._sourceListIDs = .init(initialValue: mixList?.listIDs ?? [])
        self.mixList = mixList
        self.selectableLists = selectableLists
        self.mixLists = mixLists
        self.saveAction = onSave
    }
    
    var isCreatingNewMixList: Bool { mixList == nil }

    var unavailableListIDs: Set<String> { sourceListIDs.subtracting(selectableLists.map(\.id)) }

    var hasDuplicateTitle: Bool {
        MixReminderList.hasDuplicateTitle(mixListTitle, in: mixLists, excludingListID: mixList?.id)
    }

    var canSave: Bool {
        MixReminderList.canSave(
            title: mixListTitle,
            listIDs: sourceListIDs,
            in: selectableLists,
            mixLists: mixLists,
            excludingListID: mixList?.id,
        )
    }
    
    var body: some View {
        Form {
            Section {
                TextField("マイミックスリスト", text: $mixListTitle)
            } header: {
                Text("名前")
            } footer: {
                if hasDuplicateTitle == true {
                    Text("同名のミックスリストがあります。別の名前を設定してください。")
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
        .navigationTitle(isCreatingNewMixList ? "新規作成" : "編集")
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

extension MixListFormView {
    func selectionBinding(for listID: String) -> Binding<Bool> {
        .init(
            get: { sourceListIDs.contains(listID) },
            set: { if $0 { sourceListIDs.insert(listID) } else { sourceListIDs.remove(listID) } }
        )
    }
    
    func save() {
        guard canSave == true else { return }
        saveAction(.init(id: mixList?.id ?? .init(), title: mixListTitle.trimmingCharacters(in: .whitespacesAndNewlines), listIDs: sourceListIDs))
        dismiss()
    }
}

#Preview {
    MixListFormView(selectableLists: [
        .init(id: "a", title: "リストA", isDefault: true, reminders: []),
        .init(id: "b", title: "リストB", isDefault: false, reminders: []),
        .init(id: "c", title: "リストC", isDefault: false, reminders: []),
    ], mixLists: []) { _ in }
}
