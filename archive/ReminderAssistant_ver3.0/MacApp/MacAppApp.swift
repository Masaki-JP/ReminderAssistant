//
//  MacAppApp.swift
//  MacApp
//
//  Created by Masaki Doi on 2023/03/14.
//

import SwiftUI
import EventKit

@main
struct MacAppApp: App {
    
    @StateObject var eventStore = EventStore()
    @StateObject var myRegex = MyRegex()
    
    var body: some Scene {
        WindowGroup {
            ContentView(eventStore: eventStore, myRegex: myRegex)
                .onDisappear {
                    NSApplication.shared.terminate(self)
                }
        }
    }
}
