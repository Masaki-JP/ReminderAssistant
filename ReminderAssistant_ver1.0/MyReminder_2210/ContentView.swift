//
//  ContentView.swift
//  MyReminder_2210
//
//  Created by 土井正貴 on 2022/10/05.
//

import SwiftUI

struct ContentView: View {


    // インスタンスの作成
    let myRegex = MyRegex()
    let eventStore = EventStore()

    // タイトルと期限の定義
    @State var title_TextField = "Test by MyReminder_2210"
    @State var deadline_TextField = ""

    // アラート関連の変数と関数の定義
    @State var alert: Alert?
    @State var showingAlert = false
    func showAlert(alertDestination: inout Alert?, showingStatus: inout Bool, alert: Alert) {
        alertDestination = alert
        showingStatus = true
    }







    var body: some View {

        VStack {

            VStack(alignment: .leading) {
                Text("リマインダーのタイトル")
                TextField("プレースホルダー", text: $title_TextField)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .padding(.bottom)
                Text("リマインダーの期限")
                TextField("2018年4月15日10時10分", text: $deadline_TextField)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .padding(.bottom)
            }

            Button {
                Task {
                    await doTask(title: title_TextField, deadline: deadline_TextField)
                }
            } label: {
                Text("リマインダーを作成")
                    .padding(.all)
                    .frame(width: 300)
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(.blue)
                    .cornerRadius(10)
            }

        }
        .alert(isPresented: $showingAlert) {
            alert ?? Alert(title: Text("アラートが設定されていません。"))
        }
    }







    private func doTask(title: String, deadline: String) async {

        var deadline_StringType = deadline

        // 期限を整形する。
        deadline_StringType = myRegex.getFormattedDeadline(deadline: deadline_StringType)

        // 整形された期限から当てはまる「regex」を検索し、「unicode35」を得る。
        var matchUnicode35 = ""
        myRegex.absolutePatterns_221007.forEach { pattern in
            guard (pattern["regex"] != nil) && (pattern["unicode35"] != nil) else {
                showAlert(alertDestination: &alert, showingStatus: &showingAlert, alert: Alert(title: Text("リマインダー作成失敗"), message: Text("エラーが発生しました。処理を中断します。\nErrorID: 37281")))
                return
            }
            if myRegex.matchOrNot(dateString: deadline_StringType, regexPattern: pattern["regex"]!) {
                matchUnicode35 = pattern["unicode35"]!
            }
        }
        guard matchUnicode35 != "" else {
            showAlert(alertDestination: &alert, showingStatus: &showingAlert, alert: Alert(title: Text("リマインダー作成失敗"), message: Text("当てはまる正規表現が見つかりませんでした。期限の記述におかしな点はないか確認してください。")))
            return
        }


        // Date型の期限を作成する
        let deadline_DateType = myRegex.getDateFromString(unicode35: matchUnicode35, deadline: deadline_StringType)
        guard deadline_DateType != nil else {
            showAlert(alertDestination: &alert, showingStatus: &showingAlert, alert: Alert(title: Text("リマインダー作成失敗"), message: Text("エラーが発生しました。処理を中断します。\nErrorID: 86428")))
            return
        }


        //リマインダーを作成
        if eventStore.getAuthorizationStatus() {
            eventStore.createReminder(title: title, deadLine: deadline_DateType!)
            //            completionAlert = true
            showAlert(
                alertDestination: &alert,
                showingStatus: &showingAlert,
                alert: Alert(title: Text("リマインダー作成完了"),dismissButton: .default(Text("閉じる"), action: {
                    deadline_TextField = ""
                }))
            )
        } else {
            await eventStore.requestAccess()
            if eventStore.getAuthorizationStatus() {
                eventStore.createReminder(title: title, deadLine: deadline_DateType!)
                showAlert(
                    alertDestination: &alert,
                    showingStatus: &showingAlert,
                    alert: Alert(title: Text("リマインダー作成完了"), dismissButton: .default(Text("閉じる"), action: {
                        deadline_TextField = ""}))
                )
            } else {
                showAlert(alertDestination: &alert, showingStatus: &showingAlert, alert: Alert(title: Text("リマインダーへのアクセスを許可してください。")))
            }
        } // ここを関数にしたり、うまいこと修正できないか？
    }
}









struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
