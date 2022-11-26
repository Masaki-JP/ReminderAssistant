//
//  SettingView.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/11/07.
//

import SwiftUI

struct SettingView: View {

    @AppStorage("autofocus") var autofocus = false
    @AppStorage("reminderList") var reminderList = "未設定"

    @State var lists: [String] = []

    @State var settingAlert = false

    let eventStore = EventStore()

    var body: some View {

        NavigationView {

            List {
                Section {
                    Picker(selection: $reminderList) {
                        if reminderList == "未設定" {
                            Text("未設定").tag(reminderList)
                        }
                        ForEach(0 ..< lists.count, id: \.self) { index in
                            Text(lists[index]).tag(lists[index])
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
            .navigationTitle("設定")
        } // NavigationView
        .navigationViewStyle(.stack)
        .onAppear {
            print("SettingViewにてonApperメソッドが実行")
            if eventStore.getAuthorizationStatus() {
                lists = eventStore.getLists()
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





















struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
