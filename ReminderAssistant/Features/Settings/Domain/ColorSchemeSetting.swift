import SwiftUI

/// rawValueは@AppStorageによってUserDefaultsへの保存・復元に使用される。
enum ColorSchemeSetting: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    static let defaultValue = ColorSchemeSetting.system
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .system: "システム"
        case .light: "ライト"
        case .dark: "ダーク"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
