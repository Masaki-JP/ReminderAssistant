import Foundation

nonisolated
extension Calendar {
    /// 指定したタイムゾーンのグレゴリオ暦を返す。
    static func gregorianCalendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
