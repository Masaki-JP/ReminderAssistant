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

//            SampleUI()
//                .tabItem {
//                    Image(systemName: "person.fill")
//                    Text("SampleUI")
//                }
//                .tag(3)

        } // TabView
        .tint(.white)

    } // body
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
        UITabBar.appearance().backgroundColor = UIColor(red: 0.075, green: 0.075, blue: 0.075, alpha: 1)
    }

} // ContentView





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
