//
//  SettingView.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/11/07.
//

import SwiftUI

struct SettingView: View {

    @AppStorage("reminderList") var reminderList = "未設定"

    var body: some View {
        VStack {
            Text("setting")
        }
        .onAppear {
            print("設定が開かれた")
        }
    }

}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
