//
//  ContentView.swift
//  ReminderAssistant_ver3.0
//
//  Created by Masaki Doi on 2023/02/21.
//

import SwiftUI

struct ContentView: View {
    
    // アップストレージ
    @AppStorage("reminderList") var reminderList = "未設定"
    @AppStorage("autofocus") var autofocus = false
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    
    // インスタンス
    let myRegex = MyRegex()
    let eventStore = EventStore()
    
    // テキストフィールド
    @State var title = ""
    @State var deadline = ""
    @State var notes = ""
    
    // フォーカス
    @FocusState var focus: Focus?
    @State var onFocus = false
    
    // アラート
    @State var alert: Alert?
    @State var requestAccessAlert = false
    func showAlert(alert: Alert) {
        self.alert = alert
        self.requestAccessAlert = true
    }
    @State var settingAlert = false
    @State var showNotificationView = false
    
    // その他
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    
    @State var showSettingsView = false
    @State var deadlineOfCreatedReminder = ""
    @State var imageWidth: CGFloat = 230
    @State var imageHeight: CGFloat = 230
    
    let textFieldAndButtonWidth: CGFloat = 320
    
    // カラー
    var coreColor: Color {
        if colorScheme == .light {
            return Color(red: 64/255, green: 123/255, blue: 255/255)
        } else {
            return Color(red: 64/255, green: 123/255, blue: 255/255)
        }
    }
    var bgColor: Color {
        if colorScheme == .light {
            return Color(.white)
        } else {
            return Color(red: 0.05, green: 0.05, blue: 0.15)
        }
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////
    
    
    var body: some View {
        ZStack {
            
            bgColor.ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        Spacer()
                            .frame(height: 20)
                        
                        Text("Let's Create Reminders.")
                            .foregroundColor(coreColor)
                            .font(.custom("SignPainter-HouseScript", size: 55))
                            .padding(.leading, 8)
                            .padding(.top)
                        
                        Image("MobileUser")
                            .resizable()
                            .frame(width: !onFocus ? imageWidth : 0, height: !onFocus ? imageHeight : 0)
                            .padding()
                        
                        MyTextField(labelName: "名前", width: textFieldAndButtonWidth, text: $title, coreColor: coreColor, bgColor: bgColor, focus: $focus, focusStateValue: .title)
                            .padding(.top)
                        
                        MyTextField(labelName: "期限", width: textFieldAndButtonWidth, text: $deadline, coreColor: coreColor, bgColor: bgColor, focus: $focus, focusStateValue: .deadline)
                            .padding(.top, 25)
                        
                        MyTextField(labelName: "注釈", width: textFieldAndButtonWidth, axix: .vertical, lineLimit: 4, text: $notes, coreColor: coreColor, bgColor: bgColor, focus: $focus, focusStateValue: .notes)
                            .padding(.top, 25)
                        
                        MyButton(text: "リマインダー作成", color: coreColor, width: textFieldAndButtonWidth) {
                            focus = nil
                            createReminder(title: title, deadline: deadline)
                        }
                        .padding(.top, 25)
                        
                        Spacer()
                        
                        if focus == nil {
                            Button {
                                showSettingsView = true
                            } label: {
                                Text("Show App Settings")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }.frame(minHeight: geometry.size.height)
                }
                .scrollDisabled(focus == nil)
                .frame(width: geometry.size.width)
            }
            
            NotificationView(showView: $showNotificationView, title: $title, deadline: $deadlineOfCreatedReminder)
            
            
        } // ZStack
        
        
        //////////////////////////////////////////////////////////////////////////////////////////////
        
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                //                if focus == .title {
                //                    Button {
                //                        focus = .deadline
                //                    } label: {
                //                        Text("期限に移動")
                //                    }
                //                } else if focus == .deadline {
                //                    Button {
                //                        focus = .title
                //                    } label: {
                //                        Text("タイトルに移動")
                //                    }
                //                } else if focus == .notes {
                //                    Button {
                //                        let store = notes
                //                        notes = ""
                //                        focus = nil
                //                        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                //                            notes = store
                //                        }
                //                    } label: {
                //                        Text("キーボードを閉じる")
                //                    }
                //                }
                switch focus {
                case .title:
                    Button("期限に移動") {
                        focus = .deadline
                    }
                case .deadline:
                    Button("名前に移動") {
                        focus = .title
                    }
                case .notes:
                    Button("キーボードを閉じる") {
                        let store = notes; notes = ""; focus = nil;
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                            notes = store
                        }
                    }
                default:
                    EmptyView()
                }
                Spacer()
            }
        }
        .alert(isPresented: $requestAccessAlert) {
            alert ?? Alert(title: Text("アラートが設定されていません。"))
        }
        .alert("リマインダーへのアクセスを許可してください。", isPresented: $settingAlert) {
            
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        .onChange(of: scenePhase) { newValue in
            switch newValue {
            case .active:
                if autofocus && focus != .title {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
                        focus = .title
                    }
                }
            case .inactive:
                if showNotificationView { actionWhenNotificationViewDisappear() }
            case .background:
                if showNotificationView { actionWhenNotificationViewDisappear() }
            @unknown default:
                fatalError()
            }
        }
        .onChange(of: focus) { newValue in
            if newValue != nil {
                withAnimation { onFocus = true }
            } else {
                withAnimation { onFocus = false }
            }
        }
        .onChange(of: showNotificationView) { newValue in
            if newValue == false {
                actionWhenNotificationViewDisappear()
            }
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        .onAppear {
            Task {
                await eventStore.firstRequestAccess()
            }
        }
//        .onAppear {
//
//            reminderList = UserDefaults.standard.string(forKey: "reminderList") ?? "未設定"
//
//            // アクセスが許可されていることを確認
//            guard eventStore.getAuthorizationStatus() else {
//
//                guard !isFirstLaunch else {
//                    isFirstLaunch = false
//                    return
//                }
//
//                settingAlert = true
//                return
//            }
//        }
        
    } // body
    
    
    
    
    
    
    
}












extension ContentView {
    
    // リマインダー作成の関数
    func createReminder(title: String, deadline: String) {
        
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
        guard eventStore.getAuthorizationStatus() else {
            settingAlert = true
            return
        }
        
        eventStore.createReminder(title: title, deadLine: deadline_Date!, Note: notes, listName: reminderList)
        deadlineOfCreatedReminder = myRegex.getFullDateString(date: deadline_Date!)
        DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
            showNotificationView = true
        }
        
    }
    
    
    // NotificationViewが非表示になる時の処理
    func actionWhenNotificationViewDisappear() {
        title.removeAll()
        deadline.removeAll()
        notes.removeAll()
        deadlineOfCreatedReminder.removeAll()
        showNotificationView = false
    }
}










struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
