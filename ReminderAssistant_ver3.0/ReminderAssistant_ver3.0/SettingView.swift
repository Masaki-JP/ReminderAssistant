//
//  SettingView.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/11/07.
//

import SwiftUI

struct SettingView: View {

    @AppStorage("reminderList") var reminderList = "未設定"
    @State var lists: [String] = []
    var store: EventStore

    var body: some View {
        List {
                ForEach(0 ..< lists.count, id: \.self) { index in
                    if lists[index] == reminderList {
                        HStack {
                            Text(lists[index]).font(.headline)
                            Spacer()
                            Image(systemName: "checkmark").foregroundColor(.green)
                        }
                    } else {
                        Button {
                            reminderList = lists[index]
                        } label: {
                            Text(lists[index]).foregroundColor(.primary)
                        }

                    }
                }
        }
        .onAppear {
            lists = store.getLists()
        }
    }
}





//struct SettingView_Previews: PreviewProvider {
//    let store = EventStore()
//    static var previews: some View {
//        SettingView(reminderList: "aaa", store: )
//    }
//}
