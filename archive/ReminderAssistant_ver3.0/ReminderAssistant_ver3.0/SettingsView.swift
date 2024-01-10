//
//  SettingsView.swift
//  ReminderAssistant_ver3.0
//
//  Created by Masaki Doi on 2023/02/21.
//

import SwiftUI

struct SettingsView: View {

    @AppStorage("autofocus") var autofocus = false
    @AppStorage("reminderList") var reminderListForNewReminder = "未設定"
    
    @State var allReminderLists: [String] = []

    @State var settingAlert = false

    let eventStore = EventStore()

    var body: some View {

        NavigationView {

            List {
                Section {
                    Picker(selection: $reminderListForNewReminder) {
                        if reminderListForNewReminder == "未設定" {
                            Text("未設定").tag(reminderListForNewReminder)
                        }
                        ForEach(0 ..< allReminderLists.count, id: \.self) { index in
                            Text(allReminderLists[index]).tag(allReminderLists[index])
                        }
                    } label: {
                        Text("リマインダー作成先")
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("")
                } footer: {
                    Text("未設定の場合はデフォルトに設定されているリストに作成します。")
                }

                Section {
                    Toggle(isOn: $autofocus) {
                        Text("オートフォーカス")
                    }.tint(.green)
                } footer: {
                    Text("リマインダーの作成画面が表示されたときに、入力フォームに自動でフォーカスします。")
                }
            }
            .navigationTitle("Settings")
        } // NavigationView
        .navigationViewStyle(.stack)
        .onAppear {
            print("SettingViewにてonApperメソッドが実行")
            if eventStore.getAuthorizationStatus() {
                allReminderLists = eventStore.getLists()
            } else {
                settingAlert = true
            }
        }
        .alert("リマインダーへのアクセスを許可してください。", isPresented: $settingAlert) {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }




    } // body
} // SettingView

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
