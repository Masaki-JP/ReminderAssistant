import SwiftUI
import ReminderCore

struct CustomListCollectionView: View {
    /// 既存のカスタムリスト。
    @Binding var customLists: [CustomReminderList]
    /// カスタムリストの構成元として選択できる通常リスト。
    let lists: [ReminderList]
    
    var body: some View {
        List {
            if customLists.isEmpty == false {
                Section {
                    ForEach(customLists) { customList in
                        NavigationLink {
                            CustomListFormView(customList: customList, selectableLists: lists, customLists: customLists, onSave: save)
                        } label: {
                            VStack(alignment: .leading, spacing: nil) {
                                Text(customList.title)
                                Text(memberListNames(for: customList))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { customLists.remove(atOffsets: $0) }
                } header: { Text("登録済み") } footer: { text }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay {
            if customLists.isEmpty == true {
                ContentUnavailableView("カスタムリストを作成しましょう", systemImage: "rectangle.3.group", description: text)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CustomListFormView(selectableLists: lists, customLists: customLists, onSave: save)
                } label: {
                    Label("カスタムリストを作成", systemImage: "plus")
                }
                .disabled(lists.count < 2)
            }
        }
    }
    
    var text: Text {
        Text("2つ以上のリストを組み合わせて、リマインダーをまとめて表示できます。カスタムリストを削除しても、元のリストやリマインダーは削除されません。")
    }
}

extension CustomListCollectionView {
    func memberListNames(for customList: CustomReminderList) -> String {
        let titles = lists.filter { customList.listIDs.contains($0.id) }.map(\.title)
        return titles.isEmpty ? "利用できるリストがありません" : titles.joined(separator: "・")
    }
    
    func save(_ customList: CustomReminderList) {
        if let index = customLists.firstIndex(where: { $0.id == customList.id }) {
            customLists[index] = customList
        } else {
            customLists.append(customList)
        }
    }
}

#Preview {
    @Previewable @State var customLists: [CustomReminderList] = [.init(title: "ミックスリスト", listIDs: ["work", "home"])]
    
    List { Text("Hello, world.") }
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                List { Text("Hello, world.") }
                    .navigationDestination(isPresented: .constant(true)) {
                        CustomListCollectionView(customLists: $customLists, lists: [
                            .init(id: "work", title: "仕事", isDefault: true, reminders: []),
                            .init(id: "home", title: "家事", isDefault: false, reminders: []),
                        ])
                        .navigationTitle("カスタムリスト")
                        .navigationBarTitleDisplayMode(.inline)
                    }
            }
        }
}
