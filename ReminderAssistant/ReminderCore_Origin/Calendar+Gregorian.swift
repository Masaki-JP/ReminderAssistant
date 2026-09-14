import Foundation

nonisolated
extension Calendar {
    /// 指定したタイムゾーンのグレゴリオ暦を返す。
    static func gregorianCalendar(timeZone: TimeZone = .autoupdatingCurrent) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
