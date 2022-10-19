//
//  ContentView.swift
//  ReminderAssistant_ver2.0
//
//  Created by 土井正貴 on 2022/10/08.
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
    func showAlert(alert: Alert) {
        self.alert = alert
        self.showingAlert = true
    }


    var body: some View {

        ZStack {

            Color(red: 0.69, green: 0.769, blue: 0.871, opacity: 1.0).ignoresSafeArea()

            VStack {

                VStack(alignment: .leading) {
                    Text("Title").font(.title3).bold()
                    TextField("プレースホルダー", text: $title_TextField)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                        .padding(.bottom)
                    Text("Deadline").font(.title3).bold()
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
        }
        .alert(isPresented: $showingAlert) {
            alert ?? Alert(title: Text("アラートが設定されていません。"))
        }
    }







    private func doTask(title: String, deadline: String) async {

        // 1. 整形された"deadline_String"の作成する
        let deadline_String = myRegex.getFormattedDeadline(deadline: deadline)

        // 2. 整形された"deadline_String"から当てはまる「regex」と「unicode35」探す
        var matchUnicode35 = ""
        myRegex.patterns.forEach { pattern in
            guard (pattern["regex"] != nil) && (pattern["unicode35"] != nil) else {
                showAlert(alert: Alert(title: Text("リマインダー作成失敗"), message: Text("エラーが発生しました。処理を中断します。\nErrorID: 37281")))
                return
            }
            if myRegex.matchOrNot(dateString: deadline_String, regexPattern: pattern["regex"]!) {
                matchUnicode35 = pattern["unicode35"]!
            }
        }
        guard matchUnicode35 != "" else {
            showAlert(alert: Alert(title: Text("リマインダー作成失敗"), message: Text("当てはまる正規表現が見つかりませんでした。期限の記述におかしな点はないか確認してください。")))
            return
        }


        // 3. Date型の期限を作成する
        let deadline_DateType = myRegex.getDateFromString(deadline: deadline_String, unicode35: matchUnicode35)
        guard deadline_DateType != nil else {
            showAlert(alert: Alert(title: Text("リマインダー作成失敗"), message: Text("エラーが発生しました。処理を中断します。\nErrorID: 86428")))
            return
        }


        //リマインダーを作成
        if eventStore.getAuthorizationStatus() {
            eventStore.createReminder(title: title, deadLine: deadline_DateType!)
            showAlert(alert: Alert(title: Text("リマインダー作成完了"),   dismissButton: .default(Text("閉じる"),  action: {
                title_TextField = ""
                deadline_TextField = ""})))
        } else {
            await eventStore.requestAccess()
            if eventStore.getAuthorizationStatus() {
                eventStore.createReminder(title: title, deadLine: deadline_DateType!)
                showAlert(alert: Alert(title: Text("リマインダー作成完了"), dismissButton: .default(Text("閉じる"), action: {
                    title_TextField = ""
                    deadline_TextField = ""})))
            } else {
                showAlert(alert: Alert(title: Text("リマインダーへのアクセスを許可してください。")))
            }
        }
    }
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
