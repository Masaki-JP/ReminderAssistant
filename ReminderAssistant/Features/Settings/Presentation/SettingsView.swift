import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    @Binding var reminderDestinationListID: String?
    let lists: [RAReminderList]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("作成先", selection: $reminderDestinationListID) {
                        if reminderDestinationListID == nil {
                            Text("未設定").tag(String?.none)
                        }
                        
                        ForEach(lists) { list in
                            Text(list.title).tag(list.id)
                        }
                    }
                    .disabled(lists.isEmpty)
                    
                    Toggle(isOn: .constant(true)) {
                        Text("クイック作成")
                        Text("アプリ表示時に作成画面に遷移します。")
                    }
                } header: {
                    Text("作成")
                }
                
                Section {
                    Picker("外観モード", selection: .constant("システム")) {
                        ForEach(["ライト", "ダーク", "システム"], id: \.self) { mode in
                            Text(mode).tag(mode)
                        }
                    }
                } header: {
                    Text("外観")
                }
                
                Section {
                    LabeledContent("バージョン", value: "4.2.5")
                    LabeledContent("ビルド", value: "32")
                } header: {
                    Text("アプリ情報")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .contentMargins(.vertical, .zero)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close, action: dismiss.callAsFunction)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var reminderDestinationListID: String? = "shopping"
    
    Button("設定を開く") {
        isPresented = true
    }
    .sheet(isPresented: $isPresented) {
        SettingsView(
            reminderDestinationListID: $reminderDestinationListID,
            lists: [
                .init(calendarIdentifier: "assistant", title: "Reminder Assistant"),
                .init(calendarIdentifier: "shopping", title: "買い物リスト"),
                .init(calendarIdentifier: "todo", title: "やることリスト"),
            ]
        )
    }
}
