import Foundation

nonisolated
struct JapaneseDateConverter {
    func convert(_ dateString: String) -> DateComponents? {
        Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: .now.addingTimeInterval(30)
        )
    }
}
