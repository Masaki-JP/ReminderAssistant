//
//  ContentView.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/10/11.
//

import SwiftUI

struct ContentView: View {

    @State var selectedTab: Int = 1

    var body: some View {

        TabView(selection: $selectedTab) {

            ReminderView()
                .tabItem {
                    Image(systemName: "checklist")
                    Text("Reminder")
                }
                .tag(1)

            SettingView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
    }
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
