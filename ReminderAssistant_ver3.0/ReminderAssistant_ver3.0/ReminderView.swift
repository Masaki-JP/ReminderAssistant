//
//  ReminderView.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/11/11.
//

import SwiftUI

struct ReminderView: View {



    // アップストレージ
    @AppStorage("autofocus") var autofocus = false
    @AppStorage("reminderList") var reminderList = "未設定"

    // インスタンス
    let myRegex = MyRegex()
    let eventStore = EventStore()

    // テキストフィールド
    @State var title_TextField = ""
    @State var deadline_TextField = ""
    @State var notes_TextField = ""
    @FocusState var focusState: FocusField?
    enum FocusField {
        case title
        case deadline
        case notes
    }

    // アラート
    @State var alert: Alert?
    @State var showingAlert = false
    func showAlert(alert: Alert) {
        self.alert = alert
        self.showingAlert = true
    }
    @State var settingAlert = false
    @State var showCompletionAlert = false

    // その他
    @Environment(\.scenePhase) private var scenePhase
    @State var date_str = ""



    var body: some View {
        ZStack {

            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()

            VStack {

                if focusState == nil {
                    Text("Let's create reminders")
                        .bold().foregroundColor(.white).font(.largeTitle)
                        .frame(width: UIScreen.main.bounds.width)
                        .padding(.vertical)
                        .background(Color(red: 0.075, green: 0.075, blue: 0.075))
                    Spacer()
                }

                Group {

                    HStack {
                        TextField("Reminder title", text: $title_TextField)
                        .focused($focusState, equals: .title)

                        if focusState == .title && title_TextField != "" {
                            Button {
                                title_TextField = ""
                            } label: {
                                Image(systemName: "clear").foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width*0.8)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .shadow(color: focusState == .title ? .white : .clear, radius: 3)


                    HStack {
                        TextField("Deadline", text: $deadline_TextField)
                        .focused($focusState, equals: .deadline)

                        if focusState == .deadline && deadline_TextField != "" {
                            Button {
                                deadline_TextField = ""
                            } label: {
                                Image(systemName: "clear").foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width*0.8)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .padding(.top, 20)
                    .shadow(color: focusState == .deadline ? .white : .clear, radius: 3)


                    HStack {
                        TextField("Notes (option)", text: $notes_TextField, axis: .vertical)
                        .focused($focusState, equals: .notes)
                        .lineLimit(4)
                    }
                    .frame(width: UIScreen.main.bounds.width*0.8)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .padding(.top, 20)
                    .shadow(color: focusState == .notes ? .white : .clear, radius: 3)
                } // Group


//                Button {
//                    Task {
//                        focusState = nil
//                        await doTask(title: title_TextField, deadline: deadline_TextField)
//                    }
//                } label: {
//                    Text("Create a reminder")
//                        .bold().font(.title).foregroundColor(.white).padding()
//                        .background((title_TextField != "") && (deadline_TextField != "") ? Color(red: 230/270, green: 121/270, blue: 40/270) : .gray)
//                        .cornerRadius(100)
//                        .padding(.top, 25)
//                }

                Button("Create a reminder") {
                    Task {
                        focusState = nil
                        await doTask(title: title_TextField, deadline: deadline_TextField)
                    }
                }
                .bold().font(.title).foregroundColor(.white).padding()
                .background((title_TextField != "") && (deadline_TextField != "") ? Color(red: 230/270, green: 121/270, blue: 40/270) : .gray)
                .cornerRadius(100)
                .padding(.top, 25)


                Text("リマインダー作成先：\(reminderList)")
                    .font(.callout).padding(.top, 5)

                if focusState == nil {
                    Spacer()
                }

            } // VStack

            if showCompletionAlert {
                VStack {
                    Group {
                        Image("pngwing.com")
                            .resizable()
                            .frame(width: 200, height: 200)
                            .padding(.top)
                        Text("Completed!").bold().font(.largeTitle)
                            .padding(.bottom, 15)
                    }

                    Group {
                        Text(title_TextField)
                            .font(.headline)
                            .lineLimit(1)
                        Text(date_str)
                            .padding(.bottom, 15)
                            .font(.callout)
                    }
                    .frame(width: UIScreen.main.bounds.width*0.7)

                    Button {
                        closeButtonAction()
                    } label: {
                        Text("閉じる")
                            .frame(width: UIScreen.main.bounds.width*0.625)
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .background(.blue)
                            .cornerRadius(10)
                            .padding(.bottom, 13)
                    }
                }
                .frame(width: UIScreen.main.bounds.width*0.8)
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .cornerRadius(20)
            } // showCompletionAlert

        } // ZStack
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                if focusState == .title {
                    Button {
                        focusState = .deadline
                    } label: {
                        Text("期限に移動")
                    }
                } else if focusState == .deadline {
                    Button {
                        focusState = .title
                    } label: {
                        Text("タイトルに移動")
                    }
                } else if focusState == .notes {
                    Button {
                        let store = notes_TextField
                        notes_TextField = ""
                        focusState = nil
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                            notes_TextField = store
                        }
                    } label: {
                        Text("キーボードを閉じる")
                    }
                }
                Spacer()
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
        .onAppear {
            print("リマインダービューにてオンアピアメソッドが実行")
            reminderList = UserDefaults.standard.string(forKey: "reminderList") ?? "未設定"
            if autofocus && focusState != .title {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                    focusState = .title
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            print("リマインダービューにてオンチェンジメソッドが実行")

            switch phase {
            case .active:
                if autofocus && focusState != .title {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                        focusState = .title
                    }
                }
            case .inactive:
                closeButtonAction()
            case .background:
                closeButtonAction()
            @unknown default:
                fatalError()
            }



        }

    } // body




    // リマインダー作成の関数
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


        // 4. リマインダーを作成
        if eventStore.getAuthorizationStatus() {
            eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes_TextField, listName: reminderList)
            date_str = myRegex.getFullDateString(date: deadline_Date!)
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                showCompletionAlert = true
            }
        } else {
            await eventStore.requestAccess()
            if eventStore.getAuthorizationStatus() {
                eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes_TextField, listName: reminderList)
                date_str = myRegex.getFullDateString(date: deadline_Date!)
                DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                    showCompletionAlert = true
                }

            } else {
                settingAlert = true
            }
        }

    } // doTask

    private func closeButtonAction() {
        title_TextField = ""
        deadline_TextField = ""
        notes_TextField = ""
        showCompletionAlert = false
        date_str = ""
    }

} // ReminderView

































// プレビュープロバイダー
struct ReminderView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderView()
    }
}

