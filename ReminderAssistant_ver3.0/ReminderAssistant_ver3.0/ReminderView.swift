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
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                Button {
                                    let store = notes_TextField
                                    notes_TextField = ""
                                    focusState = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now()+0.03) {
                                        notes_TextField = store
                                    }
                                } label: {
                                    Text("完了")
                                }
                            }
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width*0.8)
                    .padding()
                    .background(.ultraThickMaterial)
                    .cornerRadius(15)
                    .padding(.top, 20)
                    .shadow(color: focusState == .notes ? .white : .clear, radius: 3)
                } // Group


                Button {
                    Task {
                        focusState = nil
                        await doTask(title: title_TextField, deadline: deadline_TextField)
                    }
                } label: {
                    Text("Create a reminder")
                        .bold().font(.title).foregroundColor(.white).padding()
                        .background((title_TextField != "") && (deadline_TextField != "") ? Color(red: 230/270, green: 121/270, blue: 40/270) : .gray)
                        .cornerRadius(100)
                        .padding(.top, 25)
                }


                Text("リマインダーの作成先：\(reminderList)")
                    .font(.callout).padding(.top, 5)

                if focusState == nil {
                    Spacer()
                }

            } // VStack

            if showCompletionAlert {
                Color.black.opacity(0.2).ignoresSafeArea()
                VStack {
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
                            Text("メモ：\(notes_TextField)")
                                .padding(.bottom, 5)
                        }
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 1.0))
                        .font(.footnote)
                    }
                    Button {
                        title_TextField = ""
                        deadline_TextField = ""
                        notes_TextField = ""
                        showCompletionAlert = false
                        date_str = ""
                    } label: {
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
                .frame(width: UIScreen.main.bounds.width*0.8)
                .background(.white)
                .cornerRadius(20)
                .shadow(radius: 20)
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
            if autofocus && phase == .active && focusState != .title {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                    focusState = .title
                }
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


        //リマインダーを作成
        if eventStore.getAuthorizationStatus() {
            eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes_TextField, listName: reminderList)
            date_str = myRegex.getFullDateString(date: deadline_Date!)
            DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                showCompletionAlert = true
            }

        } else {
            await eventStore.requestAccess()
            if eventStore.getAuthorizationStatus() {
                eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes_TextField, listName: reminderList)
                date_str = myRegex.getFullDateString(date: deadline_Date!)
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                    showCompletionAlert = true
                }

            } else {
                settingAlert = true
            }
        }

    } // doTask

} // ReminderView


















// UI改善前

//struct ReminderView: View {
//
//    // メモ機能
//    @State var notes_TextField = ""
//    @State var notesIsEditting = false
//
//    @Environment(\.scenePhase) private var scenePhase
//
//    // アップストレージ
//    @AppStorage("autofocus") var autofocus = false
//    @AppStorage("reminderList") var reminderList = "未設定"
//
//    @State var showCompletionAlert = false
//    @State var date_str = ""
//
//    // インスタンス
//    let myRegex = MyRegex()
//    let eventStore = EventStore()
//
//    // タイトルと期限
//    @State var title_TextField = ""
//    @State var titleIsEdditing = false
//    @State var deadline_TextField = ""
//    @State var deadlineIsEditting = false
//    @FocusState var focusState: FocusField?
//    enum FocusField {
//        case title
//        case deadline
//        case notes
//    }
//
//    // アラート
//    @State var alert: Alert?
//    @State var showingAlert = false
//    func showAlert(alert: Alert) {
//        self.alert = alert
//        self.showingAlert = true
//    }
//    @State var settingAlert = false
//
//
//
//
//
//    var body: some View {
//        ZStack {
//
//            VStack {
//
//                Text("Let's create reminders").padding(.bottom).frame(width: UIScreen.main.bounds.width).bold().font(.largeTitle).foregroundColor(.white).background((focusState == nil) ? .indigo : .clear)
//
//                Spacer()
//
//                VStack(alignment: .leading) {
//
//
//                    Text("Title").font(.title).bold()
//
//                    TextField(
//                        "買い物に行く",
//                        text: $title_TextField,
//                        onEditingChanged: { isEditting in
//                            if isEditting {
//                                titleIsEdditing = true
//                            } else {
//                                titleIsEdditing = false
//                            }})
//                    .focused($focusState, equals: .title)
//                    .shadow(color: titleIsEdditing ? .blue : .clear, radius: 3)
//                    .textFieldStyle(.roundedBorder)
//                    .frame(width: 300)
//                    .modifier(TextFieldClearButton(text: $title_TextField))
//                    .padding(.bottom)
//
//                    Text("Deadline").font(.title).bold()
//
//                    TextField("2018年4月15日10時00分", text: $deadline_TextField, onEditingChanged: { isEditting in
//                        if isEditting {
//                            deadlineIsEditting = true
//                        } else {
//                            deadlineIsEditting = false
//                        }
//                    })
//                    .focused($focusState, equals: .deadline)
//                    .shadow(color: deadlineIsEditting ? .blue : .clear, radius: 3)
//                    .textFieldStyle(.roundedBorder)
//                    .frame(width: 300)
//                    .modifier(TextFieldClearButton(text: $deadline_TextField))
//                    .padding(.bottom)
//
//                    Text("Notes").font(.title).bold()
//                    TextField("メモ（オプション）", text: $notes_TextField) { isEditting in
//                        if isEditting {
//                            notesIsEditting = true
//                        } else {
//                            notesIsEditting = false
//                        }
//                    }
//                    .focused($focusState, equals: .notes)
//                    .shadow(color: notesIsEditting ? .blue : .clear, radius: 3)
//                    .textFieldStyle(.roundedBorder)
//                    .frame(width: 300)
//                    .modifier(TextFieldClearButton(text: $notes_TextField))
//                    .padding(.bottom)
//                }
//
//
//
//
//
//
//                Button {
//                    Task {
//                        focusState = nil
//                        await doTask(title: title_TextField, deadline: deadline_TextField)
//                    }
//                } label: {
//                    Text("リマインダーを作成")
//                        .bold()
//                        .padding(.all)
//                        .frame(width: 280)
//                        .font(.title2)
//                        .foregroundColor(.white)
//                        .background((title_TextField != "") && (deadline_TextField != "") ? .blue : .gray)
//                        .cornerRadius(10)
//                        .padding(.top)
//                }
//
//                Group {
//                    Text("リマインダーの作成先：\(reminderList)")
//                        .font(.callout).padding(.top)
//                    Text("(作成先が未設定の場合、デフォルトリストに追加されます。)")
//                        .font(.caption).padding(.bottom, 50)
//                }
//            }
//
//            if showCompletionAlert {
//                Color.black.opacity(0.2).ignoresSafeArea()
//                VStack {
//                    Group {
//                        Image("checkmark")
//                            .resizable()
//                            .scaledToFit()
//                            .scaleEffect(0.8)
//                        Text("リマインダー作成完了").bold().font(.title2)
//                        Group {
//                            Text("タイトル：\(title_TextField)")
//                                .padding(.top, 1)
//                            Text("期限：\(date_str)")
//                                .padding(.bottom, 5)
//                            Text("メモ：\(notes_TextField)")
//                                .padding(.bottom, 5)
//                        }
//                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 1.0))
//                        .font(.footnote)
//                    }
//                    Button {
//                        title_TextField = ""
//                        deadline_TextField = ""
//                        notes_TextField = ""
//                        showCompletionAlert = false
//                        date_str = ""
//                    } label: {
//                        Text("閉じる")
//                            .frame(width: UIScreen.main.bounds.width*0.6)
//                            .bold()
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(.blue)
//                            .cornerRadius(10)
//                            .padding()
//                    }
//                }
//                .frame(width: UIScreen.main.bounds.width*0.8)
//                .background(.white)
//                .cornerRadius(20)
//                .shadow(radius: 20)
//            }
//        }
//        .toolbar {
////            ToolbarItem(placement: .keyboard) {
////
////                if focusState == .title {
////                    Button {
////                        focusState = .deadline
////                    } label: {
////                        Text("期限に移動")
////                    }
////                } else if focusState == .deadline {
////                    Button {
////                        focusState = .title
////                    } label: {
////                        Text("タイトルに移動")
////                    }
////                }
////            }
//            ToolbarItemGroup(placement: .keyboard) {
//                Spacer()
//                if focusState == .title {
//                    Button {
//                        focusState = .deadline
//                    } label: {
//                        Text("期限に移動")
//                    }
//                } else if focusState == .deadline {
//                    Button {
//                        focusState = .title
//                    } label: {
//                        Text("タイトルに移動")
//                    }
//                }
//                Spacer()
//            }
//        }
//        .alert(isPresented: $showingAlert) {
//            alert ?? Alert(title: Text("アラートが設定されていません。"))
//        }
//        .alert("リマインダーへのアクセスを許可してください。", isPresented: $settingAlert) {
//            Button {
//                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
//                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                }
//            } label: {
//                Text("設定を開く")
//            }
//
//        }
//        .onAppear {
//            print("リマインダービューにてオンアピアメソッドが実行")
//            reminderList = UserDefaults.standard.string(forKey: "reminderList") ?? "未設定"
//            if autofocus && focusState != .title {
//                DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
//                    focusState = .title
//                }
//            }
//        }
//        .onChange(of: scenePhase) { phase in
//            print("リマインダービューにてオンチェンジメソッドが実行")
//            if autofocus && phase == .active && focusState != .title {
//                DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
//                    focusState = .title
//                }
//            }
//        }
//    }
//
//
//
//    // クリアボタン定義
//    struct TextFieldClearButton: ViewModifier {
//
//        @Binding var text: String
//
//        func body(content: Content) -> some View {
//            ZStack(alignment: .trailing)
//            {
//                content
//                if !text.isEmpty {
//                    Button(
//                        action: {
//                            self.text = ""
//                        })
//                    {
//                        Image(systemName: "delete.left")
//                            .foregroundColor(Color(UIColor.opaqueSeparator))
//                    }
//                    .padding(.trailing, 8)
//                }
//            }
//        }
//    }
//
//
//    // リマインダー作成の関数
//    private func doTask(title: String, deadline: String) async {
//
//        // 1. 整形された"deadline_String"の作成する
//        let deadline_String = myRegex.getFormattedDeadline(deadline: deadline)
//
//        // 2. 整形された"deadline_String"から当てはまる「regex」と「unicode35」探す
//        var matchUnicode35 = ""
//        myRegex.patterns.forEach { pattern in
//            guard (pattern["regex"] != nil) && (pattern["unicode35"] != nil) else {
//                showAlert(alert: Alert(title: Text("リマインダー作成失敗"), message: Text("エラーが発生しました。処理を中断します。\nErrorID: 37281")))
//                return
//            }
//            if myRegex.matchOrNot(dateString: deadline_String, regex: pattern["regex"]!) {
//                matchUnicode35 = pattern["unicode35"]!
//            }
//        }
//        guard matchUnicode35 != "" else {
//            showAlert(alert: Alert(title: Text("リマインダー作成失敗"), message: Text("当てはまる正規表現が見つかりませんでした。期限の記述におかしな点はないか確認してください。")))
//            return
//        }
//
//
//        // 3. Date型の期限を作成する
//        let deadline_Date = myRegex.getDateFromString(deadline: deadline_String, unicode35: matchUnicode35)
//        guard deadline_Date != nil else {
//            showAlert(alert: Alert(title: Text("リマインダー作成失敗"), message: Text("エラーが発生しました。処理を中断します。\nErrorID: 86428")))
//            return
//        }
//
//
//        //リマインダーを作成
//        if eventStore.getAuthorizationStatus() {
//            eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes_TextField, listName: reminderList)
//            date_str = myRegex.getFullDateString(date: deadline_Date!)
//            showCompletionAlert = true
//
//        } else {
//            await eventStore.requestAccess()
//            if eventStore.getAuthorizationStatus() {
//                eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes_TextField, listName: reminderList)
//
//                date_str = myRegex.getFullDateString(date: deadline_Date!)
//                showCompletionAlert = true
//            } else {
//                settingAlert = true
//            }
//        }
//
//    }
//}





















// プレビュープロバイダー
struct ReminderView_Previews: PreviewProvider {
    static var previews: some View {
        //        ReminderView(reminderList: "サンプルリストA")
        ReminderView()
    }
}
