import Foundation
import ReminderCore

/// サンプルの日時を、相対日付と時刻の文字列から生成するための入力値。
///
/// `date` には「昨日」「今日」「明日」、または正の半角整数を使った「3日前」「3日後」の形式を指定する。`time` には「9:30」「09:30」のような `H:mm` または `HH:mm` 形式を指定し、時は0〜23、分は00〜59の範囲とする。全角数字、符号、余分な空白を含む値、および「0日前」「0日後」は指定できない。`time` を指定する場合は `date` も指定する。日時を指定しない場合は、`.init(date: nil, time: nil)` を使用する。
nonisolated struct DateInput {
    let date: String?; let time: String?
}

nonisolated private let sampleCalendar = Calendar.gregorianCalendar()

nonisolated extension Reminder {
    /// サンプルデータの各入力値を検証して、``Reminder``を生成する。
    ///
    /// 相対日時の文字列をアプリ内で扱う日時へ変換する。不正な入力値や日時の前後関係は、実行時エラーとして検出する。
    static func sample(
        id: String,
        title: String,
        dueDate: DateInput = .init(date: nil, time: nil),
        priority: Priority = .none,
        notes: String? = nil,
        isCompleted: Bool = false,
        creationDate: DateInput = .init(date: nil, time: nil),
        lastModifiedDate: DateInput = .init(date: nil, time: nil),
        completionDate: DateInput? = nil
    ) -> Self {
        guard id.isEmpty == false else {
            fatalError("リマインダーIDを入力してください。")
        }
        
        guard title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            fatalError("タイトルを入力してください。")
        }
        
        let dueDateComponents = makeDateComponents(dueDate)
        let convertedCreationDate = makeDate(creationDate)
        let convertedLastModifiedDate = makeDate(lastModifiedDate)
        let convertedCompletionDate: Date?
        if let completionDate {
            guard let date = makeDate(completionDate) else {
                fatalError("完了日時が不正です：日付「\(completionDate.date ?? "未指定")」、時刻「\(completionDate.time ?? "未指定")」。")
            }
            convertedCompletionDate = date
        } else {
            convertedCompletionDate = nil
        }
        
        guard isCompleted == (convertedCompletionDate != nil) else {
            fatalError("完了状態と完了日時が一致していません。")
        }
        
        if let convertedCreationDate, let convertedLastModifiedDate {
            guard convertedCreationDate <= convertedLastModifiedDate else {
                fatalError("作成日時は最終更新日時より後にできません。")
            }
        }
        
        if let convertedCompletionDate {
            if let convertedCreationDate {
                guard convertedCreationDate <= convertedCompletionDate else {
                    fatalError("完了日時は作成日時より前にできません。")
                }
            }
            
            if let convertedLastModifiedDate {
                guard convertedCompletionDate <= convertedLastModifiedDate else {
                    fatalError("完了日時は最終更新日時より後にできません。")
                }
            }
        }
        
        return Self(
            id: id,
            title: title,
            dueDateComponents: dueDateComponents,
            priority: priority,
            notes: notes,
            isCompleted: isCompleted,
            creationDate: convertedCreationDate,
            lastModifiedDate: convertedLastModifiedDate,
            completionDate: convertedCompletionDate
        )
    }
}

/// 相対日付と時刻の入力値を`DateComponents`へ変換する。
///
/// 日付のみの場合は年月日のみ、時刻も指定した場合は時分も設定する。 日付なしで時刻だけが指定された場合は、実行時エラーにする。
nonisolated private func makeDateComponents(_ value: DateInput) -> DateComponents? {
    guard value.date != nil || value.time == nil else {
        fatalError("日付を指定せずに時刻だけを指定することはできません。")
    }
    
    guard let date = makeRelativeDate(value.date) else { return nil }
    var components = sampleCalendar.dateComponents([.year, .month, .day], from: date)
    
    if let time = value.time {
        let (hour, minute) = parseTime(time)
        components.hour = hour
        components.minute = minute
    }
    
    return components
}

/// 相対日付と時刻の入力値を`Date`へ変換する。
///
/// 日付が指定されていない入力値は、`nil`として扱う。変換できない`DateComponents`が渡された場合は、実行時エラーにする。
nonisolated private func makeDate(_ value: DateInput) -> Date? {
    guard let components = makeDateComponents(value) else { return nil }
    guard let date = sampleCalendar.date(from: components) else {
        fatalError("指定された値から日時を作成できません。")
    }
    return date
}

/// 「今日」や「3日後」などの相対日付を`Date`へ変換する。
///
/// 基準日は、現在のカレンダーにおける今日の開始時刻。指定形式以外の文字列が渡された場合は、実行時エラーにする。
nonisolated private func makeRelativeDate(_ value: String?) -> Date? {
    guard let value else { return nil }
    
    let dayOffset: Int
    switch value {
    case "昨日": dayOffset = -1
    case "今日": dayOffset = 0
    case "明日": dayOffset = 1
    default:
        if value.hasSuffix("日前") {
            dayOffset = -parsePositiveDayCount(String(value.dropLast(2)))
        } else if value.hasSuffix("日後") {
            dayOffset = parsePositiveDayCount(String(value.dropLast(2)))
        } else {
            fatalError("相対日付が不正です: \(value)。")
        }
    }
    
    return sampleCalendar.date(
        byAdding: .day,
        value: dayOffset,
        to: sampleCalendar.startOfDay(for: .now)
    )
}

/// 正の整数で表された日数を解析する。
///
/// 「3日前」や「3日後」の日数部分を受け取ることを想定する。0・負数・数字以外を含む値は、実行時エラーにする。
nonisolated private func parsePositiveDayCount(_ value: String) -> Int {
    guard value.isEmpty == false,
          value.allSatisfy({ $0.isASCII && $0.isNumber }),
          let dayCount = Int(value),
          dayCount > 0 else {
        fatalError("相対日付の日数が不正です: \(value)。")
    }
    return dayCount
}

/// HH:mm形式の時刻を時と分に分解する。
///
/// 時は0〜23、分は0〜59の範囲で指定できる。形式または範囲が不正な値は、実行時エラーにする。
nonisolated private func parseTime(_ value: String) -> (hour: Int, minute: Int) {
    let parts = value.split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count == 2,
          (1...2).contains(parts[0].count),
          parts[1].count == 2,
          parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
          let hour = Int(parts[0]),
          let minute = Int(parts[1]),
          (0...23).contains(hour),
          (0...59).contains(minute) else {
        fatalError("時刻が不正です: \(value)。")
    }
    return (hour, minute)
}
