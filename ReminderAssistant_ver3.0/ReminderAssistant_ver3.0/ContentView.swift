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
//    @State var alert: Alert?
//    @State var requestAccessAlert = false
//    func showAlert(alert: Alert) {
//        self.alert = alert
//        self.requestAccessAlert = true
//    }
    
    @State var settingAlert = false
    @State var noMatchAlert = false
    @State var unknownErrorAlert = false
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
        
       
//        .alert(isPresented: $requestAccessAlert) {
//            alert ?? Alert(title: Text("アラートが設定されていません。"))
//        }
        
        
        .alert("Error", isPresented: $settingAlert, actions: {
            Button("設定を開く") {
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }, message: {
            Text("\nリマインダーアプリへのアクセスを許可してください！\n")
        })
        
        .alert("Error", isPresented: $noMatchAlert, actions: {
            Button("OK") {
                print("pushed")
            }
        }, message: {
            Text("\n期限の記述をご確認ください！\n")
        })
        .alert("Error", isPresented: $unknownErrorAlert, actions: {
            Button("OK") {
                print("pushed")
            }
        }, message: {
            Text("\n予期せぬエラーが発生しました。\n")
        })
        .toolbar {
            //            ToolbarItemGroup(placement: .keyboard) {
            //                Spacer()
            //                switch focus {
            //                case .title:
            //                    Button("期限に移動") {
            //                        focus = .deadline
            //                    }
            //                case .deadline:
            //                    Button("名前に移動") {
            //                        focus = .title
            //                    }
            //                case .notes:
            //                    Button("キーボードを閉じる") {
            //                        let store = notes; notes = ""; focus = nil;
            //                        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            //                            notes = store
            //                        }
            //                    }
            //                default:
            //                    EmptyView()
            //                }
            //                Spacer()
            //            }
        
            
            ToolbarItemGroup(placement: .keyboard) {
                
                // ライトモードはまだ
                
                let scaleEffect: CGFloat = 0.75
                
                // キーボード非表示
                Button {
                    
                    if focus == .notes {
                        let store = notes
                        notes = ""
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                            notes = store
                        }
                        focus = nil
                    } else {
                        focus = nil
                    }
                    
                  
                } label: {
                    Image(systemName: "arrow.down")
                        .scaleEffect(scaleEffect)
                }
                .opacity(colorScheme == .light ? 1.0 : 0.8)
                .padding(.leading, -12)
                
                Spacer()
                
                // 名前
                Button {
                    focus = .title
                } label: {
                    HStack(spacing: 0) {
                        Image(systemName: "list.bullet.clipboard")
                            .scaleEffect(scaleEffect)
                        Text("名前")
                    }
                }
                .padding(.trailing, 5)
                .opacity(colorScheme == .dark && focus != .title ? 0.8 : 1.0)
                .fontWeight(focus == .title ? .bold : .regular)
                
                Text("-")
                    .foregroundColor(.blue)
                    .opacity(colorScheme == .light ? 1.0 : 0.8)
                
                // 期限
                Button {
                    focus = .deadline
                } label: {
                    HStack(spacing: 0) {
                        Image(systemName: "clock")
                            .scaleEffect(scaleEffect)
                        Text("期限")
                    }
                }
                .padding(.horizontal, 5)
                .opacity(colorScheme == .dark && focus != .deadline ? 0.8 : 1.0)
                .fontWeight(focus == .deadline ? .bold : .regular)
                
                Text("-")
                    .foregroundColor(.blue)
                    .opacity(colorScheme == .light ? 1.0 : 0.8)
                
                // 注釈
                Button {
                    focus = .notes
                } label: {
                    HStack(spacing: 0) {
                        Image(systemName: "note.text")
                            .scaleEffect(scaleEffect)
                        Text("注釈")
                    }
                }
                .padding(.leading, 5)
                .opacity(colorScheme == .dark && focus != .notes ? 0.8 : 1.0)
                .fontWeight(focus == .notes ? .bold : .regular)
                
                Spacer()
                
                // キーボード非表示
                Button {
                    
                    if focus == .notes {
                        let store = notes
                        notes = ""
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                            notes = store
                        }
                        focus = nil
                    } else {
                        focus = nil
                    }
                    
                  
                } label: {
                    Image(systemName: "arrow.down")
                        .scaleEffect(scaleEffect)
                }
                .opacity(colorScheme == .light ? 1.0 : 0.8)
                .padding(.trailing, -12)
                
            } // toolbarItemGroup
            
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
