import UIKit
import GameController

enum InterfaceIdiom {
    case phone, pad(isPhysicalKeyboardConnected: Bool), mac

    static var current: Self {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            .mac
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            .pad(isPhysicalKeyboardConnected: GCKeyboard.coalesced != nil)
        } else {
            .phone
        }
    }
}
