import Foundation

/// サンプルの日時を、相対日付と時刻の文字列から生成するための入力値。
/// `date` には「今日」や「3日後」、`time` には「09:30」のような値を指定する。
/// 日時を指定しない場合は、`.init(date: nil, time: nil)` を使用する。
nonisolated
struct DateInput {
    let date: String?; let time: String?
}

nonisolated
let sampleCalendar = Calendar.gregorianCalendar()

/// サンプルデータの各入力値を検証して、RAReminderを生成する。
/// 相対日時の文字列をアプリ内で扱う日時へ変換する。
/// 不正な入力値や日時の前後関係は、実行時エラーとして検出する。
nonisolated
func makeSample(
    calendarItemIdentifier: String,
    list: RAReminderList,
    title: String,
    dueDate: DateInput = .init(date: nil, time: nil),
    priority: RAReminder.Priority = .none,
    notes: String? = nil,
    isCompleted: Bool = false,
    creationDate: DateInput = .init(date: nil, time: nil),
    lastModifiedDate: DateInput = .init(date: nil, time: nil),
    completionDate: DateInput? = nil
) -> RAReminder {
    guard calendarItemIdentifier.isEmpty == false else {
        fatalError("カレンダー項目IDを入力してください")
    }
    
    guard list.calendarIdentifier.isEmpty == false else {
        fatalError("リマインダーリストIDを入力してください")
    }
    
    guard list.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
        fatalError("リマインダーリスト名を入力してください")
    }
    
    guard title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
        fatalError("タイトルを入力してください")
    }
    
    let dueDateComponents = makeDateComponents(dueDate)
    let convertedCreationDate = makeDate(creationDate)
    let convertedLastModifiedDate = makeDate(lastModifiedDate)
    let convertedCompletionDate: Date?
    if let completionDate {
        guard let date = makeDate(completionDate) else {
            fatalError("完了日時が不正です：日付「\(completionDate.date ?? "未指定")」、時刻「\(completionDate.time ?? "未指定")」")
        }
        convertedCompletionDate = date
    } else {
        convertedCompletionDate = nil
    }
    
    guard isCompleted == (convertedCompletionDate != nil) else {
        fatalError("完了状態と完了日時が一致していません")
    }
    
    if let convertedCreationDate, let convertedLastModifiedDate {
        guard convertedCreationDate <= convertedLastModifiedDate else {
            fatalError("作成日時は最終更新日時より後にできません")
        }
    }
    
    if let convertedCompletionDate {
        if let convertedCreationDate {
            guard convertedCreationDate <= convertedCompletionDate else {
                fatalError("完了日時は作成日時より前にできません")
            }
        }
        
        if let convertedLastModifiedDate {
            guard convertedCompletionDate <= convertedLastModifiedDate else {
                fatalError("完了日時は最終更新日時より後にできません")
            }
        }
    }
    
    return RAReminder(
        calendarItemIdentifier: calendarItemIdentifier,
        list: list,
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

/// 相対日付と時刻の入力値をDateComponentsへ変換する。
/// 日付のみの場合は年月日のみ、時刻も指定した場合は時分も設定する。
/// 日付なしで時刻だけが指定された場合は、実行時エラーにする。
nonisolated
private func makeDateComponents(_ value: DateInput) -> DateComponents? {
    guard value.date != nil || value.time == nil else {
        fatalError("日付を指定せずに時刻だけを指定することはできません")
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

/// 相対日付と時刻の入力値をDateへ変換する。
/// 日付が指定されていない入力値は、nilとして扱う。
/// 変換できないDateComponentsが渡された場合は、実行時エラーにする。
nonisolated
private func makeDate(_ value: DateInput) -> Date? {
    guard let components = makeDateComponents(value) else { return nil }
    guard let date = sampleCalendar.date(from: components) else {
        fatalError("指定された値から日時を作成できません")
    }
    return date
}

/// 「今日」や「3日後」などの相対日付をDateへ変換する。
/// 基準日は、現在のカレンダーにおける今日の開始時刻。
/// 指定形式以外の文字列が渡された場合は、実行時エラーにする。
nonisolated
private func makeRelativeDate(_ value: String?) -> Date? {
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
            fatalError("相対日付が不正です: \(value)")
        }
    }
    
    return sampleCalendar.date(
        byAdding: .day,
        value: dayOffset,
        to: sampleCalendar.startOfDay(for: .now)
    )
}

/// 正の整数で表された日数を解析する。
/// 「3日前」や「3日後」の日数部分を受け取ることを想定する。
/// 0・負数・数字以外を含む値は、実行時エラーにする。
nonisolated
private func parsePositiveDayCount(_ value: String) -> Int {
    guard !value.isEmpty,
          value.allSatisfy({ $0.isASCII && $0.isNumber }),
          let dayCount = Int(value),
          dayCount > 0 else {
        fatalError("相対日付の日数が不正です: \(value)")
    }
    return dayCount
}

/// HH:mm形式の時刻を時と分に分解する。
/// 時は0〜23、分は0〜59の範囲で指定できる。
/// 形式または範囲が不正な値は、実行時エラーにする。
nonisolated
private func parseTime(_ value: String) -> (hour: Int, minute: Int) {
    let parts = value.split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count == 2,
          (1...2).contains(parts[0].count),
          parts[1].count == 2,
          parts.allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isNumber } }),
          let hour = Int(parts[0]),
          let minute = Int(parts[1]),
          (0...23).contains(hour),
          (0...59).contains(minute) else {
        fatalError("時刻が不正です: \(value)")
    }
    return (hour, minute)
}

nonisolated
enum RAReminderSample {
    private static let householdList = RAReminderList(
        calendarIdentifier: "00000000-0000-0000-0000-000000000101",
        title: "家事"
    )
    private static let personalTasksList = RAReminderList(
        calendarIdentifier: "00000000-0000-0000-0000-000000000102",
        title: "個人"
    )
    private static let workList = RAReminderList(
        calendarIdentifier: "00000000-0000-0000-0000-000000000103",
        title: "仕事"
    )
    private static let hobbyList = RAReminderList(
        calendarIdentifier: "00000000-0000-0000-0000-000000000104",
        title: "趣味"
    )
    private static let otherList = RAReminderList(
        calendarIdentifier: "00000000-0000-0000-0000-000000000105",
        title: "その他"
    )
    
    /*
     期限が設定されたサンプルは、期限が早い順に並んでいます。期限未設定のサンプルは末尾に配置しています。
     隣接する期限どうしは、最低でも21分空けています。
     */
    
    static let samples: [RAReminder] = [
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000001",
            list: Self.householdList,
            title: "家計簿をつける",
            dueDate: .init(date: "昨日", time: "7:38"),
            priority: .medium,
            notes: "サンプルメモ 01",
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "8:12"),
            lastModifiedDate: .init(date: "2日前", time: "12:12"),
            completionDate: .init(date: "2日前", time: "12:12")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000002",
            list: Self.personalTasksList,
            title: "財布の中身を確認する",
            dueDate: .init(date: "昨日", time: "8:00"),
            priority: .none,
            notes: "サンプルメモ 02",
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "8:12"),
            lastModifiedDate: .init(date: "2日前", time: "12:12"),
            completionDate: .init(date: "2日前", time: "12:12")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000003",
            list: Self.workList,
            title: "GitHubの通知を確認する",
            dueDate: .init(date: "昨日", time: "8:21"),
            priority: .high,
            notes: "サンプルメモ 03",
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "8:42"),
            lastModifiedDate: .init(date: "今日", time: "12:42"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000004",
            list: Self.personalTasksList,
            title: "明日の服を準備する",
            dueDate: .init(date: "昨日", time: "8:50"),
            priority: .medium,
            notes: "サンプルメモ 04",
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "8:42"),
            lastModifiedDate: .init(date: "今日", time: "12:42"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000005",
            list: Self.workList,
            title: "コードをリファクタリングする",
            dueDate: .init(date: "昨日", time: "9:11"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "9:07"),
            lastModifiedDate: .init(date: "昨日", time: "13:07"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000006",
            list: Self.personalTasksList,
            title: "寝る前にアラームを設定する",
            dueDate: .init(date: "昨日", time: "9:49"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "9:07"),
            lastModifiedDate: .init(date: "昨日", time: "13:07"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000007",
            list: Self.otherList,
            title: "不要なファイルを削除する",
            dueDate: .init(date: "昨日", time: "10:22"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "9:37"),
            lastModifiedDate: .init(date: "昨日", time: "13:37"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000008",
            list: Self.personalTasksList,
            title: "明日の予定を整理する",
            dueDate: .init(date: "昨日", time: "11:02"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "9:37"),
            lastModifiedDate: .init(date: "昨日", time: "13:37"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000009",
            list: Self.personalTasksList,
            title: "写真を整理する",
            dueDate: .init(date: "昨日", time: "11:23"),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "10:02"),
            lastModifiedDate: .init(date: "今日", time: "14:02"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000010",
            list: Self.personalTasksList,
            title: "カレンダーを確認する",
            dueDate: .init(date: "昨日", time: "12:06"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "10:02"),
            lastModifiedDate: .init(date: "今日", time: "14:02"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000011",
            list: Self.householdList,
            title: "エアコンのフィルターを掃除する",
            dueDate: .init(date: "昨日", time: "12:42"),
            priority: .medium,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "10:32"),
            lastModifiedDate: .init(date: "2日前", time: "14:32"),
            completionDate: .init(date: "2日前", time: "14:32")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000012",
            list: Self.personalTasksList,
            title: "メモを整理する",
            dueDate: .init(date: "昨日", time: "13:24"),
            priority: .high,
            notes: "サンプルメモ 12",
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "8:27"),
            lastModifiedDate: .init(date: "昨日", time: "12:27"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000013",
            list: Self.householdList,
            title: "自転車の空気を入れる",
            dueDate: .init(date: "昨日", time: "14:04"),
            priority: .medium,
            notes: "サンプルメモ 13",
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "8:27"),
            lastModifiedDate: .init(date: "昨日", time: "12:27"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000014",
            list: Self.householdList,
            title: "お風呂を掃除する",
            dueDate: .init(date: "昨日", time: "14:32"),
            priority: .none,
            notes: "サンプルメモ 14",
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "8:57"),
            lastModifiedDate: .init(date: "昨日", time: "12:57"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000015",
            list: Self.householdList,
            title: "服をたたむ",
            dueDate: .init(date: "昨日", time: "15:10"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "9:22"),
            lastModifiedDate: .init(date: "今日", time: "13:22"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000016",
            list: Self.workList,
            title: "テストコードを書く",
            dueDate: .init(date: "昨日", time: "15:55"),
            priority: .low,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "9:52"),
            lastModifiedDate: .init(date: "2日前", time: "13:52"),
            completionDate: .init(date: "2日前", time: "13:52")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000017",
            list: Self.householdList,
            title: "車を洗う",
            dueDate: .init(date: "昨日", time: "16:22"),
            priority: .low,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "9:52"),
            lastModifiedDate: .init(date: "2日前", time: "13:52"),
            completionDate: .init(date: "2日前", time: "13:52")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000018",
            list: Self.workList,
            title: "プルリクエストを確認する",
            dueDate: .init(date: "昨日", time: "16:52"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "10:17"),
            lastModifiedDate: .init(date: "昨日", time: "14:17"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000019",
            list: Self.householdList,
            title: "車にガソリンを入れる",
            dueDate: .init(date: "昨日", time: "17:33"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "10:17"),
            lastModifiedDate: .init(date: "昨日", time: "14:17"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000020",
            list: Self.householdList,
            title: "買い物リストを作る",
            dueDate: .init(date: "昨日", time: "17:57"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "10:47"),
            lastModifiedDate: .init(date: "昨日", time: "14:47"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000021",
            list: Self.personalTasksList,
            title: "ふるさと納税の書類を整理する",
            dueDate: .init(date: "今日", time: "7:51"),
            priority: .low,
            notes: "サンプルメモ 21",
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "8:09"),
            lastModifiedDate: .init(date: "昨日", time: "12:09"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000022",
            list: Self.hobbyList,
            title: "ストレッチをする",
            dueDate: .init(date: "今日", time: "8:29"),
            priority: .high,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "9:04"),
            lastModifiedDate: .init(date: "3日前", time: "13:04"),
            completionDate: .init(date: "3日前", time: "13:04")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000023",
            list: Self.otherList,
            title: "ケーブルを整理する",
            dueDate: .init(date: "今日", time: "8:52"),
            priority: .low,
            notes: "サンプルメモ 23",
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "8:09"),
            lastModifiedDate: .init(date: "昨日", time: "12:09"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000024",
            list: Self.personalTasksList,
            title: "健康診断を予約する",
            dueDate: .init(date: "今日", time: "9:19"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "10:14"),
            lastModifiedDate: .init(date: "今日", time: "14:14"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000025",
            list: Self.otherList,
            title: "スマホの写真をバックアップする",
            dueDate: .init(date: "今日", time: "10:04"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "9:19"),
            lastModifiedDate: .init(date: "昨日", time: "13:19"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000026",
            list: Self.hobbyList,
            title: "小説を読む",
            dueDate: .init(date: "今日", time: "10:29"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "10:14"),
            lastModifiedDate: .init(date: "今日", time: "14:14"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000027",
            list: Self.otherList,
            title: "充電器を持ち出す",
            dueDate: .init(date: "今日", time: "11:05"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "9:19"),
            lastModifiedDate: .init(date: "昨日", time: "13:19"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000028",
            list: Self.personalTasksList,
            title: "眼鏡を調整する",
            dueDate: .init(date: "今日", time: "11:34"),
            priority: .none,
            notes: "サンプルメモ 28",
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "8:24"),
            lastModifiedDate: .init(date: "3日前", time: "12:24"),
            completionDate: .init(date: "3日前", time: "12:24")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000029",
            list: Self.hobbyList,
            title: "筋トレをする",
            dueDate: .init(date: "今日", time: "11:56"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "10:29"),
            lastModifiedDate: .init(date: "昨日", time: "14:29"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000030",
            list: Self.hobbyList,
            title: "Swiftを勉強する",
            dueDate: .init(date: "今日", time: "12:30"),
            priority: .none,
            notes: "サンプルメモ 30",
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "8:24"),
            lastModifiedDate: .init(date: "3日前", time: "12:24"),
            completionDate: .init(date: "3日前", time: "12:24")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000031",
            list: Self.personalTasksList,
            title: "クレジットカードの明細を確認する",
            dueDate: .init(date: "今日", time: "13:05"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "9:34"),
            lastModifiedDate: .init(date: "今日", time: "13:34"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000032",
            list: Self.hobbyList,
            title: "近所を散歩する",
            dueDate: .init(date: "今日", time: "13:28"),
            priority: .none,
            notes: "サンプルメモ 32",
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "8:39"),
            lastModifiedDate: .init(date: "昨日", time: "12:39"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000033",
            list: Self.workList,
            title: "マウスを掃除する",
            dueDate: .init(date: "今日", time: "14:11"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "9:34"),
            lastModifiedDate: .init(date: "今日", time: "13:34"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000034",
            list: Self.personalTasksList,
            title: "美容院を予約する",
            dueDate: .init(date: "今日", time: "14:42"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "9:49"),
            lastModifiedDate: .init(date: "昨日", time: "13:49"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000035",
            list: Self.otherList,
            title: "パスワードを更新する",
            dueDate: .init(date: "今日", time: "15:27"),
            priority: .none,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "10:44"),
            lastModifiedDate: .init(date: "3日前", time: "14:44"),
            completionDate: .init(date: "3日前", time: "14:44")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000036",
            list: Self.hobbyList,
            title: "英単語を覚える",
            dueDate: .init(date: "今日", time: "16:03"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "9:49"),
            lastModifiedDate: .init(date: "昨日", time: "13:49"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000037",
            list: Self.workList,
            title: "モニターを拭く",
            dueDate: .init(date: "今日", time: "16:48"),
            priority: .low,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "10:44"),
            lastModifiedDate: .init(date: "3日前", time: "14:44"),
            completionDate: .init(date: "3日前", time: "14:44")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000038",
            list: Self.personalTasksList,
            title: "レンタル品を返却する",
            dueDate: .init(date: "今日", time: "17:25"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "10:59"),
            lastModifiedDate: .init(date: "昨日", time: "14:59"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000039",
            list: Self.householdList,
            title: "Wi-Fiルーターを再起動する",
            dueDate: .init(date: "今日", time: "18:06"),
            priority: .medium,
            notes: "サンプルメモ 39",
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "8:54"),
            lastModifiedDate: .init(date: "今日", time: "12:54"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000040",
            list: Self.workList,
            title: "デスク周りを片付ける",
            dueDate: .init(date: "今日", time: "18:41"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "10:59"),
            lastModifiedDate: .init(date: "昨日", time: "14:59"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000041",
            list: Self.householdList,
            title: "作り置きを準備する",
            dueDate: .init(date: "明日", time: "8:07"),
            priority: .medium,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "9:16"),
            lastModifiedDate: .init(date: "4日前", time: "13:16"),
            completionDate: .init(date: "4日前", time: "13:16")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000042",
            list: Self.workList,
            title: "次回の会議日程を調整する",
            dueDate: .init(date: "明日", time: "8:32"),
            priority: .none,
            notes: "サンプルメモ 42",
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "8:21"),
            lastModifiedDate: .init(date: "昨日", time: "12:21"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000043",
            list: Self.householdList,
            title: "粗大ゴミを申し込む",
            dueDate: .init(date: "明日", time: "9:00"),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "10:26"),
            lastModifiedDate: .init(date: "今日", time: "14:26"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000044",
            list: Self.householdList,
            title: "ペットボトルを分別する",
            dueDate: .init(date: "明日", time: "9:24"),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "9:01"),
            lastModifiedDate: .init(date: "昨日", time: "13:01"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000045",
            list: Self.householdList,
            title: "タオルを交換する",
            dueDate: .init(date: "明日", time: "9:53"),
            priority: .medium,
            notes: "サンプルメモ 45",
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "8:06"),
            lastModifiedDate: .init(date: "今日", time: "12:06"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000046",
            list: Self.householdList,
            title: "クローゼットを整理する",
            dueDate: .init(date: "明日", time: "10:19"),
            priority: .high,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "10:56"),
            lastModifiedDate: .init(date: "4日前", time: "14:56"),
            completionDate: .init(date: "4日前", time: "14:56")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000047",
            list: Self.householdList,
            title: "玄関の鍵を確認する",
            dueDate: .init(date: "明日", time: "10:52"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "10:41"),
            lastModifiedDate: .init(date: "昨日", time: "14:41"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000048",
            list: Self.personalTasksList,
            title: "履歴書を見直す",
            dueDate: .init(date: "明日", time: "11:28"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "9:46"),
            lastModifiedDate: .init(date: "今日", time: "13:46"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000049",
            list: Self.householdList,
            title: "トイレットペーパーを買う",
            dueDate: .init(date: "明日", time: "12:08"),
            priority: .low,
            notes: "サンプルメモ 49",
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "8:51"),
            lastModifiedDate: .init(date: "昨日", time: "12:51"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000050",
            list: Self.householdList,
            title: "本棚を整理する",
            dueDate: .init(date: "明日", time: "12:35"),
            priority: .none,
            notes: "サンプルメモ 50",
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "8:21"),
            lastModifiedDate: .init(date: "昨日", time: "12:21"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000051",
            list: Self.householdList,
            title: "コーヒー豆を買う",
            dueDate: .init(date: "明日", time: "13:19"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "10:26"),
            lastModifiedDate: .init(date: "今日", time: "14:26"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000052",
            list: Self.workList,
            title: "経費を精算する",
            dueDate: .init(date: "明日", time: "13:59"),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "9:31"),
            lastModifiedDate: .init(date: "昨日", time: "13:31"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000053",
            list: Self.householdList,
            title: "ベランダを掃除する",
            dueDate: .init(date: "明日", time: "14:26"),
            priority: .low,
            notes: "サンプルメモ 53",
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "8:06"),
            lastModifiedDate: .init(date: "今日", time: "12:06"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000054",
            list: Self.workList,
            title: "ポートフォリオを更新する",
            dueDate: .init(date: "明日", time: "14:49"),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "10:11"),
            lastModifiedDate: .init(date: "昨日", time: "14:11"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000055",
            list: Self.householdList,
            title: "洗面台を掃除する",
            dueDate: .init(date: "明日", time: "15:29"),
            priority: .low,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "9:16"),
            lastModifiedDate: .init(date: "4日前", time: "13:16"),
            completionDate: .init(date: "4日前", time: "13:16")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000056",
            list: Self.householdList,
            title: "お弁当のおかずを作る",
            dueDate: .init(date: "明日", time: "16:10"),
            priority: .high,
            notes: "サンプルメモ 56",
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "8:51"),
            lastModifiedDate: .init(date: "昨日", time: "12:51"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000057",
            list: Self.workList,
            title: "議事録を共有する",
            dueDate: .init(date: "明日", time: "16:38"),
            priority: .none,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "10:56"),
            lastModifiedDate: .init(date: "4日前", time: "14:56"),
            completionDate: .init(date: "4日前", time: "14:56")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000058",
            list: Self.householdList,
            title: "靴箱を掃除する",
            dueDate: .init(date: "明日", time: "17:21"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "9:31"),
            lastModifiedDate: .init(date: "昨日", time: "13:31"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000059",
            list: Self.householdList,
            title: "段ボールをまとめる",
            dueDate: .init(date: "明日", time: "17:50"),
            priority: .medium,
            notes: "サンプルメモ 59",
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "8:36"),
            lastModifiedDate: .init(date: "4日前", time: "12:36"),
            completionDate: .init(date: "4日前", time: "12:36")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000060",
            list: Self.householdList,
            title: "キッチンの排水口を掃除する",
            dueDate: .init(date: "明日", time: "18:17"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "10:41"),
            lastModifiedDate: .init(date: "昨日", time: "14:41"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000061",
            list: Self.personalTasksList,
            title: "家族に電話する",
            dueDate: .init(date: "2日後", time: "8:19"),
            priority: .low,
            notes: "サンプルメモ 61",
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "8:03"),
            lastModifiedDate: .init(date: "昨日", time: "12:03"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000062",
            list: Self.householdList,
            title: "洗剤を補充する",
            dueDate: .init(date: "2日後", time: "8:59"),
            priority: .medium,
            notes: "サンプルメモ 62",
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "8:03"),
            lastModifiedDate: .init(date: "昨日", time: "12:03"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000063",
            list: Self.householdList,
            title: "クリーニングを受け取る",
            dueDate: .init(date: "2日後", time: "9:28"),
            priority: .none,
            notes: "サンプルメモ 63",
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "8:18"),
            lastModifiedDate: .init(date: "今日", time: "12:18"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000064",
            list: Self.personalTasksList,
            title: "日記を書く",
            dueDate: .init(date: "2日後", time: "10:12"),
            priority: .medium,
            notes: "サンプルメモ 64",
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "8:33"),
            lastModifiedDate: .init(date: "昨日", time: "12:33"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000065",
            list: Self.personalTasksList,
            title: "定期券を更新する",
            dueDate: .init(date: "2日後", time: "10:44"),
            priority: .none,
            notes: "サンプルメモ 65",
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "8:33"),
            lastModifiedDate: .init(date: "昨日", time: "12:33"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000066",
            list: Self.hobbyList,
            title: "映画のチケットを予約する",
            dueDate: .init(date: "2日後", time: "11:12"),
            priority: .low,
            notes: "サンプルメモ 66",
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "8:48"),
            lastModifiedDate: .init(date: "5日前", time: "12:48"),
            completionDate: .init(date: "5日前", time: "12:48")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000067",
            list: Self.otherList,
            title: "スマホを充電する",
            dueDate: .init(date: "2日後", time: "11:38"),
            priority: .none,
            notes: "サンプルメモ 67",
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "8:48"),
            lastModifiedDate: .init(date: "5日前", time: "12:48"),
            completionDate: .init(date: "5日前", time: "12:48")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000068",
            list: Self.personalTasksList,
            title: "旅行の宿を予約する",
            dueDate: .init(date: "3日後", time: "7:56"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "9:13"),
            lastModifiedDate: .init(date: "昨日", time: "13:13"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000069",
            list: Self.personalTasksList,
            title: "役所の手続きを確認する",
            dueDate: .init(date: "3日後", time: "8:21"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "9:13"),
            lastModifiedDate: .init(date: "昨日", time: "13:13"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000070",
            list: Self.personalTasksList,
            title: "友人に連絡する",
            dueDate: .init(date: "3日後", time: "8:48"),
            priority: .low,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "9:28"),
            lastModifiedDate: .init(date: "5日前", time: "13:28"),
            completionDate: .init(date: "5日前", time: "13:28")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000071",
            list: Self.householdList,
            title: "電池を買う",
            dueDate: .init(date: "3日後", time: "9:16"),
            priority: .medium,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "9:28"),
            lastModifiedDate: .init(date: "5日前", time: "13:28"),
            completionDate: .init(date: "5日前", time: "13:28")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000072",
            list: Self.hobbyList,
            title: "語学アプリで学習する",
            dueDate: .init(date: "3日後", time: "9:46"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "9:43"),
            lastModifiedDate: .init(date: "昨日", time: "13:43"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000073",
            list: Self.hobbyList,
            title: "ヨガをする",
            dueDate: .init(date: "3日後", time: "10:30"),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "9:58"),
            lastModifiedDate: .init(date: "今日", time: "13:58"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000074",
            list: Self.otherList,
            title: "アプリをアップデートする",
            dueDate: .init(date: "3日後", time: "11:02"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "9:58"),
            lastModifiedDate: .init(date: "今日", time: "13:58"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000075",
            list: Self.hobbyList,
            title: "読書メモをまとめる",
            dueDate: .init(date: "4日後", time: "8:12"),
            priority: .low,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "10:08"),
            lastModifiedDate: .init(date: "5日前", time: "14:08"),
            completionDate: .init(date: "5日前", time: "14:08")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000076",
            list: Self.hobbyList,
            title: "ランニングシューズを洗う",
            dueDate: .init(date: "4日後", time: "8:54"),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "10:23"),
            lastModifiedDate: .init(date: "昨日", time: "14:23"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000077",
            list: Self.otherList,
            title: "パソコンをバックアップする",
            dueDate: .init(date: "4日後", time: "9:28"),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "10:23"),
            lastModifiedDate: .init(date: "昨日", time: "14:23"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000078",
            list: Self.personalTasksList,
            title: "誕生日プレゼントを選ぶ",
            dueDate: .init(date: "4日後", time: "9:54"),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "10:38"),
            lastModifiedDate: .init(date: "今日", time: "14:38"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000079",
            list: Self.householdList,
            title: "シーツを洗う",
            dueDate: .init(date: "4日後", time: "10:29"),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "10:38"),
            lastModifiedDate: .init(date: "今日", time: "14:38"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000080",
            list: Self.householdList,
            title: "宅配便を受け取る",
            dueDate: .init(date: "4日後", time: "10:50"),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "10:53"),
            lastModifiedDate: .init(date: "昨日", time: "14:53"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000081",
            list: Self.householdList,
            title: "牛乳を買う",
            dueDate: .init(date: nil, time: nil),
            priority: .medium,
            notes: "サンプルメモ 81",
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "8:00"),
            lastModifiedDate: .init(date: "1日前", time: "12:00"),
            completionDate: .init(date: "1日前", time: "12:00")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000082",
            list: Self.householdList,
            title: "卵を買う",
            dueDate: .init(date: nil, time: nil),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "10:35"),
            lastModifiedDate: .init(date: "昨日", time: "14:35"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000083",
            list: Self.householdList,
            title: "燃えるゴミを出す",
            dueDate: .init(date: nil, time: nil),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "9:10"),
            lastModifiedDate: .init(date: "今日", time: "13:10"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000084",
            list: Self.householdList,
            title: "洗濯物を干す",
            dueDate: .init(date: nil, time: nil),
            priority: .high,
            notes: "サンプルメモ 84",
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "8:45"),
            lastModifiedDate: .init(date: "昨日", time: "12:45"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000085",
            list: Self.householdList,
            title: "リビングを掃除する",
            dueDate: .init(date: nil, time: nil),
            priority: .none,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "10:20"),
            lastModifiedDate: .init(date: "1日前", time: "14:20"),
            completionDate: .init(date: "1日前", time: "14:20")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000086",
            list: Self.personalTasksList,
            title: "メールに返信する",
            dueDate: .init(date: nil, time: nil),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "9:55"),
            lastModifiedDate: .init(date: "昨日", time: "13:55"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000087",
            list: Self.workList,
            title: "会議資料を確認する",
            dueDate: .init(date: nil, time: nil),
            priority: .low,
            notes: "サンプルメモ 87",
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "8:30"),
            lastModifiedDate: .init(date: "今日", time: "12:30"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000088",
            list: Self.personalTasksList,
            title: "銀行に行く",
            dueDate: .init(date: nil, time: nil),
            priority: .medium,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "10:05"),
            lastModifiedDate: .init(date: "昨日", time: "14:05"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000089",
            list: Self.personalTasksList,
            title: "郵便物を出す",
            dueDate: .init(date: nil, time: nil),
            priority: .none,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "9:40"),
            lastModifiedDate: .init(date: "1日前", time: "13:40"),
            completionDate: .init(date: "1日前", time: "13:40")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000090",
            list: Self.personalTasksList,
            title: "図書館に本を返す",
            dueDate: .init(date: nil, time: nil),
            priority: .low,
            notes: "サンプルメモ 90",
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "8:15"),
            lastModifiedDate: .init(date: "昨日", time: "12:15"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000091",
            list: Self.personalTasksList,
            title: "歯医者を予約する",
            dueDate: .init(date: nil, time: nil),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "10:50"),
            lastModifiedDate: .init(date: "今日", time: "14:50"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000092",
            list: Self.personalTasksList,
            title: "薬を受け取る",
            dueDate: .init(date: nil, time: nil),
            priority: .none,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "9:25"),
            lastModifiedDate: .init(date: "昨日", time: "13:25"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000093",
            list: Self.householdList,
            title: "水道料金を支払う",
            dueDate: .init(date: nil, time: nil),
            priority: .high,
            notes: "サンプルメモ 93",
            isCompleted: true,
            creationDate: .init(date: "7日前", time: "8:00"),
            lastModifiedDate: .init(date: "1日前", time: "12:00"),
            completionDate: .init(date: "1日前", time: "12:00")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000094",
            list: Self.householdList,
            title: "電気料金を確認する",
            dueDate: .init(date: nil, time: nil),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "21日前", time: "10:35"),
            lastModifiedDate: .init(date: "昨日", time: "14:35"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000095",
            list: Self.personalTasksList,
            title: "保険証を更新する",
            dueDate: .init(date: nil, time: nil),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "3日前", time: "9:10"),
            lastModifiedDate: .init(date: "今日", time: "13:10"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000096",
            list: Self.personalTasksList,
            title: "靴を磨く",
            dueDate: .init(date: nil, time: nil),
            priority: .low,
            notes: "サンプルメモ 96",
            isCompleted: false,
            creationDate: .init(date: "10日前", time: "8:45"),
            lastModifiedDate: .init(date: "昨日", time: "12:45"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000097",
            list: Self.householdList,
            title: "観葉植物に水をあげる",
            dueDate: .init(date: nil, time: nil),
            priority: .high,
            notes: nil,
            isCompleted: true,
            creationDate: .init(date: "30日前", time: "10:20"),
            lastModifiedDate: .init(date: "1日前", time: "14:20"),
            completionDate: .init(date: "1日前", time: "14:20")
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000098",
            list: Self.householdList,
            title: "冷蔵庫を整理する",
            dueDate: .init(date: nil, time: nil),
            priority: .high,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "5日前", time: "9:55"),
            lastModifiedDate: .init(date: "昨日", time: "13:55"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000099",
            list: Self.householdList,
            title: "夕食の準備をする",
            dueDate: .init(date: nil, time: nil),
            priority: .high,
            notes: "サンプルメモ 99",
            isCompleted: false,
            creationDate: .init(date: "14日前", time: "8:30"),
            lastModifiedDate: .init(date: "今日", time: "12:30"),
            completionDate: nil
        ),
        makeSample(
            calendarItemIdentifier: "00000000-0000-0000-0000-000000000100",
            list: Self.householdList,
            title: "朝食用のパンを買う",
            dueDate: .init(date: nil, time: nil),
            priority: .low,
            notes: nil,
            isCompleted: false,
            creationDate: .init(date: "1日前", time: "10:05"),
            lastModifiedDate: .init(date: "昨日", time: "14:05"),
            completionDate: nil
        ),
    ]
    
    static func accessRequestPreviewReminders(for list: RAReminderList) -> [RAReminder] {
        let dueDate1 = DateInput(date: "50日前", time: "9:00")
        let dueDate2 = DateInput(date: "50日後", time: "9:00")
        let creationDate = DateInput(date: "100日前", time: "9:00")
        
        return [
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000001",
                list: list,
                title: "xxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000002",
                list: list,
                title: "xxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000003",
                list: list,
                title: "xxxxxxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000004",
                list: list,
                title: "xxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000005",
                list: list,
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate1,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000006",
                list: list,
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .high,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000007",
                list: list,
                title: "xxxxxxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000008",
                list: list,
                title: "xxxxxxxxxxxxxxxx",
                dueDate: .init(date: "昨日", time: "11:02"),
                priority: .low,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000009",
                list: list,
                title: "xxxxxxxxxx",
                dueDate: dueDate2,
                priority: .medium,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
            makeSample(
                calendarItemIdentifier: "00000000-0000-0000-0000-000000000010",
                list: list,
                title: "xxxxxxxxxxxxxx",
                dueDate: dueDate2,
                priority: .none,
                creationDate: creationDate,
                lastModifiedDate: creationDate,
            ),
        ]
    }
}
