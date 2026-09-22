import SwiftUI
import ReminderCore

struct MixListCollectionView: View {
    /// 既存のミックスリスト。
    @Binding var mixLists: [MixReminderList]
    /// ミックスリストの構成元として選択できる通常リスト。
    let lists: [ReminderList]
    
    var body: some View {
        List {
            if mixLists.isEmpty == false {
                Section {
                    ForEach(mixLists) { mixList in
                        NavigationLink {
                            MixListFormView(mixList: mixList, selectableLists: lists, mixLists: mixLists, onSave: save)
                        } label: {
                            VStack(alignment: .leading, spacing: nil) {
                                Text(mixList.title)
                                Text(memberListNames(for: mixList))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { mixLists.remove(atOffsets: $0) }
                } header: { Text("登録済み") } footer: { text }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay {
            if mixLists.isEmpty == true {
                ContentUnavailableView("ミックスリストを作成しましょう", systemImage: "rectangle.3.group", description: text)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    MixListFormView(selectableLists: lists, mixLists: mixLists, onSave: save)
                } label: {
                    Label("ミックスリストを作成", systemImage: "plus")
                }
                .disabled(lists.count < 2)
            }
        }
    }
    
    var text: Text {
        Text("2つ以上のリストを組み合わせて、リマインダーをまとめて表示できます。ミックスリストを削除しても、元のリストやリマインダーは削除されません。")
    }
}

extension MixListCollectionView {
    func memberListNames(for mixList: MixReminderList) -> String {
        let titles = lists.filter { mixList.listIDs.contains($0.id) }.map(\.title)
        return titles.isEmpty ? "利用できるリストがありません" : titles.joined(separator: "・")
    }
    
    func save(_ mixList: MixReminderList) {
        if let index = mixLists.firstIndex(where: { $0.id == mixList.id }) {
            mixLists[index] = mixList
        } else {
            mixLists.append(mixList)
        }
    }
}

#Preview {
    @Previewable @State var mixLists: [MixReminderList] = [.init(title: "ミックスリスト", listIDs: ["work", "home"])]
    
    List { Text("Hello, world.") }
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                List { Text("Hello, world.") }
                    .navigationDestination(isPresented: .constant(true)) {
                        MixListCollectionView(mixLists: $mixLists, lists: [
                            .init(id: "work", title: "仕事", isDefault: true, reminders: []),
                            .init(id: "home", title: "家事", isDefault: false, reminders: []),
                        ])
                        .navigationTitle("ミックスリスト")
                        .navigationBarTitleDisplayMode(.inline)
                    }
            }
        }
}
