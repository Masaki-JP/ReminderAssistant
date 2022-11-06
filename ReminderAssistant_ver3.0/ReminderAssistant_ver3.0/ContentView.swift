//
//  ContentView.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/10/11.
//

import SwiftUI

struct ContentView: View {

    @State var isShow = false
    @State var date_str = ""

    // インスタンスの作成
    let myRegex = MyRegex()
    let eventStore = EventStore()

    // タイトルと期限の定義
    @State var title_TextField = ""
    @State var deadline_TextField = ""

    // アラート関連の変数と関数の定義
    @State var alert: Alert?
    @State var showingAlert = false
    func showAlert(alert: Alert) {
        self.alert = alert
        self.showingAlert = true
    }
    @State var settingAlert = false


    var body: some View {

        ZStack {

            Color(red: 1.0, green: 0.8941, blue: 0.8824, opacity: 1.0).ignoresSafeArea()

            VStack {

                VStack(alignment: .leading) {
                    Text("Title").font(.title3).bold()
                    TextField("買い物に行く", text: $title_TextField)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 280)
                        .modifier(TextFieldClearButton(text: $title_TextField))
                        .padding(.bottom)
                    Text("Deadline").font(.title3).bold()
                    TextField("2018年4月15日10時10分", text: $deadline_TextField)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 280)
                        .modifier(TextFieldClearButton(text: $deadline_TextField))
                        .padding(.bottom)
                }

                Button {
                    Task {
                        await doTask(title: title_TextField, deadline: deadline_TextField)
                    }
                } label: {
                    Text("リマインダーを作成")
                        .bold()
                        .padding(.all)
                        .frame(width: 280)
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(.pink)
                        .cornerRadius(10)
                        .padding(.top)
                }
                Text("ReminderAssistant ver 3.0")
            }

            if isShow {
                Color.black.opacity(0.2).ignoresSafeArea()
                VStack {
//                    Group {
//                        Image(systemName: "checkmark.rectangle")
//                            .foregroundColor(.green)
//                            .scaleEffect(10)
//                            .frame(height: 180)
//                        Text("リマインダー作成完了").bold().font(.title2)
//                        Text("タイトル")
//                        Text(title_TextField)
//                        Text("期限")
//                        Text(date_str)
//                    }
                    Group {
                        Image("checkmark")
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(0.8)
                        Text("リマインダー作成完了").bold().font(.title2)
                        Group {
                            Text("タイトル：\(title_TextField)")
                                .padding(.top, 1)
                            Text("期限：\(date_str)")
                                .padding(.bottom, 5)
                        }
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 1.0))
                        .font(.footnote)
                    }
                    Button {
                        title_TextField = ""
                        deadline_TextField = ""
                        isShow = false
                        date_str = ""
                    } label: {
//                        Text("閉じる")
//                            .frame(width: 250)
//                            .bold()
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(.blue)
//                            .cornerRadius(10)
                        Text("閉じる")
                            .frame(width: UIScreen.main.bounds.width*0.6)
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .background(.blue)
                            .cornerRadius(10)
                            .padding()
                    }
                }
//                .padding(10)
//                .background(.white)
//                .cornerRadius(20)
//                .shadow(radius: 20)
                .frame(width: UIScreen.main.bounds.width*0.8)
                .background(.white)
                .cornerRadius(20)
                .shadow(radius: 20)
            }
        }
        .alert(isPresented: $showingAlert) {
            alert ?? Alert(title: Text("アラートが設定されていません。"))
        }
        .alert("リマインダーへのアクセスを許可してください。", isPresented: $settingAlert) {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            } label: {
                Text("設定を開く")
            }

        }

    }





    struct TextFieldClearButton: ViewModifier {

        @Binding var text: String

        func body(content: Content) -> some View {
            ZStack(alignment: .trailing)
            {
                content
                if !text.isEmpty {
                    Button(
                        action: {
                            self.text = ""
                        })
                    {
                        Image(systemName: "delete.left")
                            .foregroundColor(Color(UIColor.opaqueSeparator))
                    }
                    .padding(.trailing, 8)
                }
            }
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
            if myRegex.matchOrNot(dateString: deadline_String, regex: pattern["regex"]!) {
                matchUnicode35 = pattern["unicode35"]!
            }
        }
        guard matchUnicode35 != "" else {
            showAlert(alert: Alert(title: Text("リマインダー作成失敗"), message: Text("当てはまる正規表現が見つかりませんでした。期限の記述におかしな点はないか確認してください。")))
            return
        }


        // 3. Date型の期限を作成する
        let deadline_Date = myRegex.getDateFromString(deadline: deadline_String, unicode35: matchUnicode35)
        guard deadline_Date != nil else {
            showAlert(alert: Alert(title: Text("リマインダー作成失敗"), message: Text("エラーが発生しました。処理を中断します。\nErrorID: 86428")))
            return
        }


        //リマインダーを作成
        if eventStore.getAuthorizationStatus() {
            eventStore.createReminder(title: title, deadLine: deadline_Date!)
//            showAlert(alert: Alert(title: Text("リマインダー作成完了"), message: Text("タイトル：\(title)\n期限：\(myRegex.getFullDateString(date: deadline_Date!))"), dismissButton: .default(Text("閉じる"), action: {
//                title_TextField = ""
//                deadline_TextField = ""})))
            date_str = myRegex.getFullDateString(date: deadline_Date!)
            isShow = true

        } else {
            await eventStore.requestAccess()
            if eventStore.getAuthorizationStatus() {
                eventStore.createReminder(title: title, deadLine: deadline_Date!)
//                showAlert(alert: Alert(title: Text("リマインダー作成完了"), message: Text("タイトル：\(title)\n期限：\(myRegex.getFullDateString(date: deadline_Date!))"), dismissButton: .default(Text("閉じる"), action: {
//                    title_TextField = ""
//                    deadline_TextField = ""})))

                date_str = myRegex.getFullDateString(date: deadline_Date!)
                isShow = true
            } else {
               settingAlert = true
            }
        }
    }
}






struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
