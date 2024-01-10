//
//  ContentView.swift
//  MacApp
//
//  Created by Masaki Doi on 2023/03/14.
//

import SwiftUI
import EventKit

struct ContentView: View {
    
    // アップストレージ
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @AppStorage("reminderList") var reminderListForNewReminder = "未設定"

    // インスタンス
    @ObservedObject var eventStore: EventStore
    @ObservedObject var myRegex: MyRegex
    
    // その他
    @State var allReminderLists: [String] = []
    @State var title = ""
    @State var deadline = ""
    @State var deadlineOfCreatedReminder = ""

    // アラート
    @State var showCompletionAlert = false
    @State var showSettingAlert = false
    @State var noMatchAlert = false
    @State var unknownErrorAlert = false
    
    // カラー
    @Environment(\.colorScheme) var colorScheme
    var bgColor: Color {
        switch colorScheme {
        case .light:
            return Color.white
        case .dark:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        @unknown default:
            fatalError()
        }
    }
    
    // フォーカス
    @FocusState var focus: Focus?
    enum Focus {
        case title
        case deadline
    }
    
    

    var body: some View {
        ZStack {

            bgColor.ignoresSafeArea()
                .onTapGesture {
                    focus = nil
                }

            VStack(spacing: 0) {

                TextField("Title", text: $title)
                    .focused($focus, equals: .title)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                TextField("Deadline", text: $deadline)
                    .focused($focus, equals: .deadline)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Picker(selection: $reminderListForNewReminder) {
                    if reminderListForNewReminder == "未設定" {
                        Text("未設定").tag("未設定")
                    }
                    ForEach(allReminderLists, id: \.self) { list in
                        Text(list).tag(list)
                    }
                } label: {
                        Text("リマインダーの作成先：")
                }.padding()

                Button("Create a reminder") {
                    print("Create button pushed")
                    createReminder(title: title, deadline: deadline)
                    showCompletionAlert = true
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .padding()
                .disabled(title.isEmpty || deadline.isEmpty ? true : false)
                .help("⌘ + Return")
            }
        }
        .frame(minWidth: 16*30, minHeight: 9*30)
        .alert("Completed!!", isPresented: $showCompletionAlert) {
            Button("Close") {
                print("Close button pushed")
                title.removeAll()
                deadline.removeAll()
            }
        } message: {
            Text("\(title)\n(\(deadlineOfCreatedReminder))")
        }
        .alert("Reminder Access", isPresented: $showSettingAlert) {
            Button("Open Preference") {
                print("Close button pushed")
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
                    NSWorkspace.shared.open(url)
                }
            }
        } message: {
            Text("This is message area.")
        }
        .alert("Error", isPresented: $noMatchAlert) {
            Button("OK") {
                print("pushed")
            }
        } message: {
            Text("\n期限の記述をご確認ください！\n")
        }
        .alert("Error", isPresented: $unknownErrorAlert, actions: {
            Button("OK") {
                print("pushed")
            }
        }, message: {
            Text("\n予期せぬエラーが発生しました。\n")
        })
        .onAppear {
            
//            reminderListForNewReminder = UserDefaults.standard.string(forKey: "reminderList") ?? "未設定"
            
            if isFirstLaunch {
                Task {
                    isFirstLaunch = false
                    await eventStore.firstRequestAccess()
                    allReminderLists = eventStore.getLists()
                }
            } else {
                guard EKEventStore.authorizationStatus(for: .reminder) == .authorized else {
                    showSettingAlert = true
                    return
                }
                allReminderLists = eventStore.getLists()
            }
            

            
        }
    }
}




struct ContentView_Previews: PreviewProvider {
    static var eventStore = EventStore()
    static var myRegex = MyRegex()
    static var previews: some View {
        ContentView(eventStore: eventStore, myRegex: myRegex)
    }
}
