//
//  Class_Regex.swift
//  ReminderAssistant_ver3.0
//
//  Created by 土井正貴 on 2022/10/11.
//

import Foundation





// 複合関数
extension MyRegex {

    // 期限の整形
    func getFormattedDeadline(deadline: String) -> String {
        var formattedDeadline = deadline
        formattedDeadline = fullwidthToHalfwidth(formattedDeadline) ?? formattedDeadline // 全角文字を半角文字へ変換する。
        formattedDeadline = convertKanjiToNum(str: formattedDeadline) // 零から三十一までの漢字を数字に変換する
        formattedDeadline = removeStrings(str: formattedDeadline) // 余計な文字列を削除する
        formattedDeadline = createTonightDate_Str(str: formattedDeadline) // 入力内容が「今夜」であれば、"yyyy年MM月dd日19時00分"へ変換する
        formattedDeadline = replace(str: formattedDeadline) // 時半や来年や明日などの文字列を変換する
        formattedDeadline = addFirstDay(str: formattedDeadline) // 文字列が「月」で終わる場合、「01日」を追加する。
        formattedDeadline = createStringDateFromRelativeTimeSpecification(Str: formattedDeadline) // 〇日後や0時間後を変換する。
        formattedDeadline = createStringDateFromDayOfTheWeekSpecification(str: formattedDeadline) // 日曜日や次の水曜日を"yyyy年MM月dd日"に変換する。
        return formattedDeadline
    }

    // String型 -> Optional<Date>型
    func getDateFromString(deadline: String, unicode35: String) -> Date? {

        // DateFormatterのインスタンス作成
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        // year,month,day,hour,minuteの作成
        let today = Date()
        dateFormatter.dateFormat = "yyyy年"
        let year = dateFormatter.string(from: today)
        dateFormatter.dateFormat = "MM月"
        let month = dateFormatter.string(from: today)
        dateFormatter.dateFormat = "dd日"
        let day = dateFormatter.string(from: today)
        let hour = "09時"
        let minute = "00分"
        let second = "00秒"

        // newDeadlineの加工
        var newDeadline = deadline
        if !(newDeadline.contains("年")) {
            newDeadline.insert(contentsOf: year, at: newDeadline.index(newDeadline.startIndex, offsetBy: 0))
        }
        if !(newDeadline.contains("月")) {
            newDeadline.insert(contentsOf: month, at: newDeadline.index(newDeadline.firstIndex(of: "年")!, offsetBy: 1))
        }
        if !(newDeadline.contains("日")) {
            newDeadline.insert(contentsOf: day, at: newDeadline.index(newDeadline.firstIndex(of: "月")!, offsetBy: 1))
        }
        if !(newDeadline.contains("時")) {
            newDeadline.insert(contentsOf: hour, at: newDeadline.index(newDeadline.firstIndex(of: "日")!, offsetBy: 1))
        }
        if !(newDeadline.contains("分")) {
            newDeadline.insert(contentsOf: minute, at: newDeadline.index(newDeadline.firstIndex(of: "時")!, offsetBy: 1))
        }
        if !(newDeadline.contains("秒")) {
            newDeadline.insert(contentsOf: second, at: newDeadline.index(newDeadline.firstIndex(of: "分")!, offsetBy: 1))
        }

        // newUnicode35の加工
        var newUnicode35 = unicode35
        if !(newUnicode35.contains("年")) {
            newUnicode35.insert(contentsOf: "yyyy年", at: newUnicode35.index(newUnicode35.startIndex, offsetBy: 0))
        }
        if !(newUnicode35.contains("月")) {
            newUnicode35.insert(contentsOf: "MM月", at: newUnicode35.index(newUnicode35.firstIndex(of: "年")!, offsetBy: 1))
        }
        if !(newUnicode35.contains("日")) {
            newUnicode35.insert(contentsOf: "dd日", at: newUnicode35.index(newUnicode35.firstIndex(of: "月")!, offsetBy: 1))
        }
        if !(newUnicode35.contains("時")) {
            newUnicode35.insert(contentsOf: "HH時", at: newUnicode35.index(newUnicode35.firstIndex(of: "日")!, offsetBy: 1))
        }
        if !(newUnicode35.contains("分")) {
            newUnicode35.insert(contentsOf: "mm分", at: newUnicode35.index(newUnicode35.firstIndex(of: "時")!, offsetBy: 1))
        }
        if !(newUnicode35.contains("秒")) {
            newUnicode35.insert(contentsOf: "ss秒", at: newUnicode35.index(newUnicode35.firstIndex(of: "分")!, offsetBy: 1))
        }


        // String型からDate型を生成したときに時間のずれが生じていないか確認
        dateFormatter.dateFormat = newUnicode35
        let deadline_Date = dateFormatter.date(from: newDeadline)
        guard deadline_Date != nil else {fatalError()}
        guard newDeadline == dateFormatter.string(from: deadline_Date!) else {return nil}

        return deadline_Date
    }

    // 入力内容が「今夜」であれば、"yyyy年MM月dd日19時00分"へ変換する
    func createTonightDate_Str(str: String) -> String {
        if matchOrNot(dateString: str, regex: "^今夜$") {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let tonight = dateFormatter.string(from: Date()) + "19時00分"
            return tonight
        } else {
            return str
        }
    }

    // 「〇年〇ヶ月後」を"yyyy年MM月dd日"を作成する関数
    func convert1(str: String) -> String {

        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^[1-9][0-9]{0,2}年[1-9][0-9]{0,2}ヶ月後")
        else { return str }

        let dateSpecificationArray = dateSpecification.components(separatedBy: "年")
        let years = Int(dateSpecificationArray[0])!
        let months = Int(dateSpecificationArray[1].replacingOccurrences(of: "ヶ月後", with: ""))!

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        var day = dateFormatter.calendar.date(byAdding: .year, value: years, to: Date())!
        day = dateFormatter.calendar.date(byAdding: .month, value: months, to: day)!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 「〇年半後」を"yyyy年MM月dd日"を作成する関数
    func convert2(str: String) -> String {
        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^[1-9][0-9]{0,2}年半後") else { return str }

        let years = Int(dateSpecification.replacingOccurrences(of: "年半後", with: ""))!
        let months = 6

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        var day = dateFormatter.calendar.date(byAdding: .year, value: years, to: Date())!
        day = dateFormatter.calendar.date(byAdding: .month, value: months, to: day)!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 「〇年後」を"yyyy年MM月dd日"を作成する関数
    func convert3(str: String) -> String {
        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^[1-9][0-9]{0,2}年後") else { return str }

        let year = Int(dateSpecification.replacingOccurrences(of: "年後", with: ""))!

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        let day = dateFormatter.calendar.date(byAdding: .year, value: year, to: Date())!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 「半年後」を"yyyy年MM月dd日"を作成する関数
    func convert4(str: String) -> String {
        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^半年後") else { return str }

        let months = 6

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        let day = dateFormatter.calendar.date(byAdding: .month, value: months, to: Date())!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 「〇ヶ月半後」を"yyyy年MM月dd日"を作成する関数
    func convert5(str: String) -> String {
        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^[1-9][0-9]{0,3}ヶ月半後") else { return str }

        let months = Int(dateSpecification.replacingOccurrences(of: "ヶ月半後", with: ""))!
        let days = 15

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        var day = dateFormatter.calendar.date(byAdding: .month, value: months, to: Date())!
        day = dateFormatter.calendar.date(byAdding: .day, value: days, to: day)!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 「〇ヶ月後」を"yyyy年MM月dd日"を作成する関数
    func convert6(str: String) -> String {
        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^[1-9][0-9]{0,3}ヶ月後") else { return str }

        let months = Int(dateSpecification.replacingOccurrences(of: "ヶ月後", with: ""))!

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        let day = dateFormatter.calendar.date(byAdding: .month, value: months, to: Date())!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 「半月後」を"yyyy年MM月dd日"を作成する関数
    func convert7(str: String) -> String {
        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^半月後") else { return str }

        let days = 15

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        let day = dateFormatter.calendar.date(byAdding: .day, value: days, to: Date())!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 「〇週間後」を"yyyy年MM月dd日"を作成する関数
    func convert8(str: String) -> String {
        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^[1-9][0-9]{0,3}週間後") else { return str }

        let days = 7 * Int(dateSpecification.replacingOccurrences(of: "週間後", with: ""))!

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        let day = dateFormatter.calendar.date(byAdding: .day, value: days, to: Date())!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 「〇日後」を"yyyy年MM月dd日"を作成する関数
    func convert9(str: String) -> String {

        guard let dateSpecification = getOnlyOneMatchString(str: str, regex: "^[1-9][0-9]{0,3}日後") else { return str }

        let days = Int(dateSpecification.replacingOccurrences(of: "日後", with: ""))!

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = TimeZone(identifier: "jp_JP")
        dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日"

        let day = dateFormatter.calendar.date(byAdding: .day, value: days, to: Date())!

        let newStr = str.replacingOccurrences(of: dateSpecification, with: dateFormatter.string(from: day))

        return newStr
    }
    // 〇時間〇分後から"yyyy年MM月dd日HH時mm分"を作成する関数
    func convert10(str: String) -> String {
        if matchOrNot(dateString: str, regex: "^[1-9][0-9]{0,3}時間[1-9][0-9]{0,3}分後$") {
            let newStr = str.replacingOccurrences(of: "分後", with: "")
            let times = newStr.components(separatedBy: "時間")
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_Jp")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            var day = dateFormatter.calendar.date(byAdding: .hour, value: Int(times[0])!, to: Date())
            day = dateFormatter.calendar.date(byAdding: .minute, value: Int(times[1])!, to: day!)
            dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分"
            return dateFormatter.string(from: day!)
        } else {
            return str
        }
    }
    // 〇時間半後から"yyyy年MM月dd日HH時mm分"を作成する関数
    func convert11(str: String) -> String {
        if matchOrNot(dateString: str, regex: "^[1-9][0-9]{0,3}時間半後$") {
            let time = Int(str.replacingOccurrences(of: "時間半後", with: ""))!
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            var day = dateFormatter.calendar.date(byAdding: .hour, value: time, to: Date())
            day = dateFormatter.calendar.date(byAdding: .minute, value: 30, to: day!)
            dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分"
            return dateFormatter.string(from: day!)
        } else {
            return str
        }
    }
    // 〇時間後から"yyyy年MM月dd日HH時mm分"を作成する関数
    func convert12(str: String) -> String {
        if matchOrNot(dateString: str, regex: "^[1-9][0-9]{0,3}時間後$") {
            let time = Int(str.replacingOccurrences(of: "時間後", with: ""))!
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            let day = dateFormatter.calendar.date(byAdding: .hour, value: time, to: Date())!
            dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分"
            return dateFormatter.string(from: day)
        } else {
            return str
        }
    }
    // 〇分後から"yyyy年MM月dd日HH時mm分"を作成する関数
    func convert13(str: String) -> String {
        if matchOrNot(dateString: str, regex: "^[1-9][0-9]{0,3}分後$") {
            let time = Int(str.replacingOccurrences(of: "分後", with: ""))!
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            let day = dateFormatter.calendar.date(byAdding: .minute, value: time, to: Date())!
            dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分"
            return dateFormatter.string(from: day)
        } else {
            return str
        }
    }

    // convert1~convert13までを行う
    func createStringDateFromRelativeTimeSpecification(Str: String) -> String {
        var newStr = Str
        newStr = convert1(str: newStr)
        newStr = convert2(str: newStr)
        newStr = convert3(str: newStr)
        newStr = convert4(str: newStr)
        newStr = convert5(str: newStr)
        newStr = convert6(str: newStr)
        newStr = convert7(str: newStr)
        newStr = convert8(str: newStr)
        newStr = convert9(str: newStr)
        newStr = convert10(str: newStr)
        newStr = convert11(str: newStr)
        newStr = convert12(str: newStr)
        newStr = convert13(str: newStr)
        return newStr
    }

    // 文字列に〇曜日があれば、〇曜に変換し、文字列を返す。
    func convertA(str: String) -> String {
        guard !str.contains("日曜日") else {
            return str.replacingOccurrences(of: "日曜日", with: "日曜")
        }
        guard !str.contains("月曜日") else {
            return str.replacingOccurrences(of: "月曜日", with: "月曜")
        }
        guard !str.contains("火曜日") else {
            return str.replacingOccurrences(of: "火曜日", with: "火曜")
        }
        guard !str.contains("水曜日") else {
            return str.replacingOccurrences(of: "水曜日", with: "水曜")
        }
        guard !str.contains("木曜日") else {
            return str.replacingOccurrences(of: "木曜日", with: "木曜")
        }
        guard !str.contains("金曜日") else {
            return str.replacingOccurrences(of: "金曜日", with: "金曜")
        }
        guard !str.contains("土曜日") else {
            return str.replacingOccurrences(of: "土曜日", with: "土曜")
        }
        return str
    }

    // 文字列に次〇曜があるならば、〇曜に変換し、文字列を返す。
    func convertB(str: String) -> String {
        guard !str.contains("次日曜") else {
            return str.replacingOccurrences(of: "次日曜", with: "日曜")
        }
        guard !str.contains("次月曜") else {
            return str.replacingOccurrences(of: "次月曜", with: "月曜")
        }
        guard !str.contains("次火曜") else {
            return str.replacingOccurrences(of: "次火曜", with: "火曜")
        }
        guard !str.contains("次水曜") else {
            return str.replacingOccurrences(of: "次水曜", with: "水曜")
        }
        guard !str.contains("次木曜") else {
            return str.replacingOccurrences(of: "次木曜", with: "木曜")
        }
        guard !str.contains("次金曜") else {
            return str.replacingOccurrences(of: "次金曜", with: "金曜")
        }
        guard !str.contains("次土曜") else {
            return str.replacingOccurrences(of: "次土曜", with: "土曜")
        }
        return str
    }

    // 文字列に〇曜があるならば、"yyyy年MM月dd日"に変換し、文字列を返す。
    func convertC(str: String) -> String {

        guard !str.contains("日曜") else {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let weekdayOfSpecifiedDay = 1
            let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
            let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
            let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays), to: Date())!
            return str.replacingOccurrences(of: "日曜", with: dateFormatter.string(from: date))
        }

        guard !str.contains("月曜") else {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let weekdayOfSpecifiedDay = 2
            let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
            let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
            let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays), to: Date())!
            return str.replacingOccurrences(of: "月曜", with: dateFormatter.string(from: date))
        }

        guard !str.contains("火曜") else {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let weekdayOfSpecifiedDay = 3
            let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
            let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
            let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays), to: Date())!
            return str.replacingOccurrences(of: "火曜", with: dateFormatter.string(from: date))
        }

        guard !str.contains("水曜") else {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let weekdayOfSpecifiedDay = 4
            let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
            let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
            let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays), to: Date())!
            return str.replacingOccurrences(of: "水曜", with: dateFormatter.string(from: date))
        }

        guard !str.contains("木曜") else {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let weekdayOfSpecifiedDay = 5
            let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
            let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
            let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays), to: Date())!
            return str.replacingOccurrences(of: "木曜", with: dateFormatter.string(from: date))
        }

        guard !str.contains("金曜") else {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let weekdayOfSpecifiedDay = 6
            let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
            let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
            let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays), to: Date())!
            return str.replacingOccurrences(of: "金曜", with: dateFormatter.string(from: date))
        }

        guard !str.contains("土曜") else {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            dateFormatter.dateFormat = "yyyy年MM月dd日"
            let weekdayOfSpecifiedDay = 7
            let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
            let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
            let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays), to: Date())!
            return str.replacingOccurrences(of: "土曜", with: dateFormatter.string(from: date))
        }

        return str
    }

    // convertA~convertCを行う
    func createStringDateFromDayOfTheWeekSpecification(str: String) -> String {
        var newStr  = str
        newStr = convertA(str: newStr)
        newStr = convertB(str: newStr)
        newStr = convertC(str: newStr)
        return newStr
    }
}





// 単体関数
extension MyRegex {

    // 全角文字を半角文字に変換する。
    func fullwidthToHalfwidth(_ halfwidthString: String) -> String? {
        let fullwidthString = halfwidthString.applyingTransform(.fullwidthToHalfwidth, reverse: false)
        return fullwidthString
    }

    // 不要な文字列を削除し、それを返す。
    func removeStrings(str: String) -> String {
        var newStr = str
        let unnecessaryStrings = ["と", "の", " ", "　"] // スペースは全角と半角
        unnecessaryStrings.forEach { unnecessaryStr in
            newStr = newStr.replacingOccurrences(of: unnecessaryStr, with: "")
        }
        return newStr
    }

    // 文字列が「月」で終わる場合、「01日」を追加する。
    func addFirstDay(str: String) -> String {
        if str.last == "月" {
            var newStr = str
            newStr += "01日"
            return newStr
        } else {
            return str
        }
    }

    // 昼、来月、明日などの文字列を変換する
    func replace(str: String) -> String {

        var newStr = str
        let today = Date()

        // 時半を変換する
        newStr = newStr.replacingOccurrences(of: "時半", with: "時30分")

        // 早朝、朝、昼、正午、夜、晩を変換する。
        newStr = newStr.replacingOccurrences(of: "早朝", with: "07時00分")
        newStr = newStr.replacingOccurrences(of: "朝", with: "07時00分")
        newStr = newStr.replacingOccurrences(of: "昼", with: "12時00分")
        newStr = newStr.replacingOccurrences(of: "正午", with: "12時00分")
        newStr = newStr.replacingOccurrences(of: "夜", with: "19時00分")
        newStr = newStr.replacingOccurrences(of: "晩", with: "19時00分")

        // 来年、再来年、来月、再来月、来週、再来週、明日、明後日、明明後日を変換する。
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        dateFormatter.dateFormat = "yyyy年"

        let yearAfterNext = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .year, value: 2, to: today)!)
        newStr = newStr.replacingOccurrences(of: "再来年", with: yearAfterNext) // 来年と再来年の順番は入れ替えない！
        let nextYear = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .year, value: 1, to: today)!)
        newStr = newStr.replacingOccurrences(of: "来年", with: nextYear) // 来年と再来年の順番は入れ替えない！

        dateFormatter.dateFormat = "MM月"
        let monthAfterNext = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .month, value: 2, to: today)!)
        newStr = newStr.replacingOccurrences(of: "再来月", with: monthAfterNext) // 来月と再来月の順番は入れ替えない！
        let nextMonth = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .month, value: 1, to: today)!)
        newStr = newStr.replacingOccurrences(of: "来月", with: nextMonth) // 来月と再来月の順番は入れ替えない！

        dateFormatter.dateFormat = "dd日"
        let weekAfterNext = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 14, to: today)!)
        newStr = newStr.replacingOccurrences(of: "再来週", with: weekAfterNext) // 来週と再来週の順番は入れ替えない！
        let nextWeek = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 7, to: today)!)
        newStr = newStr.replacingOccurrences(of: "来週", with: nextWeek) // 来週と再来週の順番は入れ替えない！
        let tommorow = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 1, to: today)!)
        newStr = newStr.replacingOccurrences(of: "明日", with: tommorow)
        let twoDaysAfterTommorow = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 3, to: today)!)
        newStr = newStr.replacingOccurrences(of: "明々後日", with: twoDaysAfterTommorow)
        newStr = newStr.replacingOccurrences(of: "明明後日", with: twoDaysAfterTommorow) // 明後日と明明後日の順番は入れ替えない！
        let dayAfterTommorow = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 2, to: today)!)
        newStr = newStr.replacingOccurrences(of: "明後日", with: dayAfterTommorow) // 明後日と明明後日の順番は入れ替えない！


        return newStr
    }

    // 文字列が正規表現に当てはまるか否か
    func matchOrNot(dateString: String, regex: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { fatalError() }
        let results = regex.matches(in: dateString, options: [], range: NSRange(0..<dateString.count))
        if !(results.isEmpty) {
            return true
        } else {
            return false
        }
    }

    // 日付の文字列を返す
    func getFullDateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分ss秒"
        return dateFormatter.string(from: date)
    }

    // 漢字を数字に変換する
    func convertKanjiToNum(str: String) -> String {
        var newStr = str
        newStr = newStr.replacingOccurrences(of: "三十一", with: "31")
        newStr = newStr.replacingOccurrences(of: "三十", with: "30")
        newStr = newStr.replacingOccurrences(of: "二十九", with: "29")
        newStr = newStr.replacingOccurrences(of: "二十八", with: "28")
        newStr = newStr.replacingOccurrences(of: "二十七", with: "27")
        newStr = newStr.replacingOccurrences(of: "二十六", with: "26")
        newStr = newStr.replacingOccurrences(of: "二十五", with: "25")
        newStr = newStr.replacingOccurrences(of: "二十四", with: "24")
        newStr = newStr.replacingOccurrences(of: "二十三", with: "23")
        newStr = newStr.replacingOccurrences(of: "二十二", with: "22")
        newStr = newStr.replacingOccurrences(of: "二十一", with: "21")
        newStr = newStr.replacingOccurrences(of: "二十", with: "20")
        newStr = newStr.replacingOccurrences(of: "十九", with: "19")
        newStr = newStr.replacingOccurrences(of: "十八", with: "18")
        newStr = newStr.replacingOccurrences(of: "十七", with: "17")
        newStr = newStr.replacingOccurrences(of: "十六", with: "16")
        newStr = newStr.replacingOccurrences(of: "十五", with: "15")
        newStr = newStr.replacingOccurrences(of: "十四", with: "14")
        newStr = newStr.replacingOccurrences(of: "十三", with: "13")
        newStr = newStr.replacingOccurrences(of: "十二", with: "12")
        newStr = newStr.replacingOccurrences(of: "十一", with: "11")
        newStr = newStr.replacingOccurrences(of: "十", with: "10")
        newStr = newStr.replacingOccurrences(of: "九", with: "9")
        newStr = newStr.replacingOccurrences(of: "八", with: "8")
        newStr = newStr.replacingOccurrences(of: "七", with: "7")
        newStr = newStr.replacingOccurrences(of: "六", with: "6")
        newStr = newStr.replacingOccurrences(of: "五", with: "5")
        newStr = newStr.replacingOccurrences(of: "四", with: "4")
        newStr = newStr.replacingOccurrences(of: "三", with: "3")
        newStr = newStr.replacingOccurrences(of: "二", with: "2")
        newStr = newStr.replacingOccurrences(of: "一", with: "1")
        newStr = newStr.replacingOccurrences(of: "零", with: "0")
        return newStr
    }

    // 「か月、ヵ月、カ月、ケ月、箇月」を「ヶ月」に変換する
    func convertCorrectMonthSpecification(str: String) -> String {
        var newStr = str
        newStr = newStr.replacingOccurrences(of: "か月", with: "ヶ月")
        newStr = newStr.replacingOccurrences(of: "ヵ月", with: "ヶ月")
        newStr = newStr.replacingOccurrences(of: "カ月", with: "ヶ月")
        newStr = newStr.replacingOccurrences(of: "ケ月", with: "ヶ月")
        newStr = newStr.replacingOccurrences(of: "箇月", with: "ヶ月")
        return newStr
    }

    // 指定された正規表現で抽出された文字列を返す。抽出された文字列が複数の場合、もしくは抽出されなかった場合はnilを返す。
    func getOnlyOneMatchString(str: String, regex: String) -> String? {

        var newStr = str
        let regex = try! NSRegularExpression(pattern: regex, options: [])
        let results = regex.matches(in: newStr, options: [], range: NSRange(0..<newStr.count))

        if results.isEmpty {
            return nil
        } else if results.count >= 2 {
            return nil
        } else {
            let start = newStr.index(newStr.startIndex, offsetBy: results[0].range(at: 0).location)
            let end = newStr.index(start, offsetBy: results[0].range(at: 0).length)
            newStr = String(newStr[start..<end])
            return newStr
        }

    }
}





// プロパティ
final class MyRegex {

    let patterns = [

        ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9]時$","unicode35": "yyyy年M月d日H時"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時$","unicode35": "yyyy年M月d日HH時"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9]時[0-9]分$","unicode35": "yyyy年M月d日H時m分"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "yyyy年M月d日HH時m分"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "yyyy年M月d日H時mm分"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "yyyy年M月d日HH時mm分"],

        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時$","unicode35": "yyyy年MM月d日H時"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時$","unicode35": "yyyy年MM月d日HH時"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時[0-9]分$","unicode35": "yyyy年MM月d日H時m分"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "yyyy年MM月d日HH時m分"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "yyyy年MM月d日H時mm分"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "yyyy年MM月d日HH時mm分"],

        ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時$","unicode35": "yyyy年M月dd日H時"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時$","unicode35": "yyyy年M月dd日HH時"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "yyyy年M月dd日H時m分"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "yyyy年M月dd日HH時m分"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "yyyy年M月dd日H時mm分"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "yyyy年M月dd日HH時mm分"],

        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時$","unicode35": "yyyy年MM月dd日H時"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時$","unicode35": "yyyy年MM月dd日HH時"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "yyyy年MM月dd日H時m分"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "yyyy年MM月dd日HH時m分"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "yyyy年MM月dd日H時mm分"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "yyyy年MM月dd日HH時mm分"],

        ["regex": "^[0-9]{4}年[0-9]月[0-9]日$","unicode35": "yyyy年M月d日"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日$","unicode35": "yyyy年MM月d日"],
        ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日$","unicode35": "yyyy年M月dd日"],
        ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日$","unicode35": "yyyy年MM月dd日"],
//        ["regex": "^[0-9]{4}年[0-9]月$","unicode35": "yyyy年M月"],
//        ["regex": "^[0-9]{4}年[0-9][0-9]月$","unicode35": "yyyy年MM月"],

        ["regex": "^[0-9]月[0-9]日[0-9]時$","unicode35": "M月d日H時"],
        ["regex": "^[0-9]月[0-9]日[0-9][0-9]時$","unicode35": "M月d日HH時"],
        ["regex": "^[0-9]月[0-9]日[0-9]時[0-9]分$","unicode35": "M月d日H時m分"],
        ["regex": "^[0-9]月[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "M月d日HH時m分"],
        ["regex": "^[0-9]月[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "M月d日H時mm分"],
        ["regex": "^[0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "M月d日HH時mm分"],

        ["regex": "^[0-9][0-9]月[0-9]日[0-9]時$","unicode35": "MM月d日H時"],
        ["regex": "^[0-9][0-9]月[0-9]日[0-9][0-9]時$","unicode35": "MM月d日HH時"],
        ["regex": "^[0-9][0-9]月[0-9]日[0-9]時[0-9]分$","unicode35": "MM月d日H時m分"],
        ["regex": "^[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "MM月d日HH時m分"],
        ["regex": "^[0-9][0-9]月[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "MM月d日H時mm分"],
        ["regex": "^[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "MM月d日HH時mm分"],

        ["regex": "^[0-9]月[0-9][0-9]日[0-9]時$","unicode35": "M月dd日H時"],
        ["regex": "^[0-9]月[0-9][0-9]日[0-9][0-9]時$","unicode35": "M月dd日HH時"],
        ["regex": "^[0-9]月[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "M月dd日H時m分"],
        ["regex": "^[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "M月dd日HH時m分"],
        ["regex": "^[0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "M月dd日H時mm分"],
        ["regex": "^[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "M月dd日HH時mm分"],

        ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9]時$","unicode35": "MM月dd日H時"],
        ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時$","unicode35": "MM月dd日HH時"],
        ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "MM月dd日H時m分"],
        ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "MM月dd日HH時m分"],
        ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "MM月dd日H時mm分"],
        ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "MM月dd日HH時mm分"],

        ["regex": "^[0-9]月[0-9]日$","unicode35": "M月d日"],
        ["regex": "^[0-9][0-9]月[0-9]日$","unicode35": "MM月d日"],
        ["regex": "^[0-9]月[0-9][0-9]日$","unicode35": "M月dd日"],
        ["regex": "^[0-9][0-9]月[0-9][0-9]日$","unicode35": "MM月dd日"],
//        ["regex": "^[0-9]月$","unicode35": "M月"],
//        ["regex": "^[0-9][0-9]月$","unicode35": "MM月"],

        ["regex": "^[0-9]日[0-9]時$","unicode35": "d日H時"],
        ["regex": "^[0-9]日[0-9][0-9]時$","unicode35": "d日HH時"],
        ["regex": "^[0-9]日[0-9]時[0-9]分$","unicode35": "d日H時m分"],
        ["regex": "^[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "d日HH時m分"],
        ["regex": "^[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "d日H時mm分"],
        ["regex": "^[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "d日HH時mm分"],

        ["regex": "^[0-9][0-9]日[0-9]時$","unicode35": "dd日H時"],
        ["regex": "^[0-9][0-9]日[0-9][0-9]時$","unicode35": "dd日HH時"],
        ["regex": "^[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "dd日H時m分"],
        ["regex": "^[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "dd日HH時m分"],
        ["regex": "^[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "dd日H時mm分"],
        ["regex": "^[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "dd日HH時mm分"],

        ["regex": "^[0-9]日$","unicode35": "d日"],
        ["regex": "^[0-9][0-9]日$","unicode35": "dd日"],
        ["regex": "^[0-9]時$","unicode35": "H時"],
        ["regex": "^[0-9][0-9]時$","unicode35": "HH時"],
        ["regex": "^[0-9]時[0-9]分$","unicode35": "H時m分"],
        ["regex": "^[0-9][0-9]時[0-9]分$","unicode35": "HH時m分"],
        ["regex": "^[0-9]時[0-9][0-9]分$","unicode35": "H時mm分"],
        ["regex": "^[0-9][0-9]時[0-9][0-9]分$","unicode35": "HH時mm分"]

    ]

}


// 想定パターン phase.1
/*


 〇年〇月〇日 + 時間指定
 〇年〇月〇日
 〇年〇月

 〇月〇日+ 時間指定
 〇月〇日
 〇月
 〇日 + 時間指定
 〇日

 時間指定
 〇時〇分
 〇時


 */

// 想定パターン phase.2
/*


 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————

 【〇年〇月〇日＋時刻指定】



 [0-9]{4}年[0-9]月[0-9]日[0-9]時
 yyyy年M月d日H時
 [0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時
 yyyy年M月d日HH時
 [0-9]{4}年[0-9]月[0-9]日[0-9]時[0-9]分
 yyyy年M月d日H時m分
 [0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時[0-9]分
 yyyy年M月d日HH時m分
 [0-9]{4}年[0-9]月[0-9]日[0-9]時[0-9][0-9]分
 yyyy年M月d日H時mm分
 [0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分
 yyyy年M月d日HH時mm分

 [0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時
 yyyy年MM月d日H時
 [0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時
 yyyy年MM月d日HH時
 [0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時[0-9]分
 yyyy年MM月d日H時m分
 [0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9]分
 yyyy年MM月d日HH時m分
 [0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時[0-9][0-9]分
 yyyy年MM月d日H時mm分
 [0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分
 yyyy年MM月d日HH時mm分

 [0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時
 yyyy年M月dd日H時
 [0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時
 yyyy年M月dd日HH時
 [0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時[0-9]分
 yyyy年M月dd日H時m分
 [0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分
 yyyy年M月dd日HH時m分
 [0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分
 yyyy年M月dd日H時mm分
 [0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分
 yyyy年M月dd日HH時mm分

 [0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時
 yyyy年MM月dd日H時
 [0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時
 yyyy年MM月dd日HH時
 [0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9]分
 yyyy年MM月dd日H時m分
 [0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分
 yyyy年MM月dd日HH時m分
 [0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分
 yyyy年MM月dd日H時mm分
 [0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分
 yyyy年MM月dd日HH時mm分


 ————————————————————

 【〇年〇月〇日】

 [0-9]{4}年[0-9]月[0-9]日
 yyyy年M月d日

 [0-9]{4}年[0-9][0-9]月[0-9]日
 yyyy年MM月d日

 [0-9]{4}年[0-9]月[0-9][0-9]日
 yyyy年M月dd日

 [0-9]{4}年[0-9][0-9]月[0-9][0-9]日
 yyyy年MM月dd日

 ————————————————————

 【〇年〇月】

 [0-9]{4}年[0-9]月
 yyyy年M月
 [0-9]{4}年[0-9][0-9]月
 yyyy年MM月


 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————

 【〇月〇日＋時刻指定】


 [0-9]月[0-9]日[0-9]時
 M月d日H時
 [0-9]月[0-9]日[0-9][0-9]時
 M月d日HH時
 [0-9]月[0-9]日[0-9]時[0-9]分
 M月d日H時m分
 [0-9]月[0-9]日[0-9][0-9]時[0-9]分
 M月d日HH時m分
 [0-9]月[0-9]日[0-9]時[0-9][0-9]分
 M月d日H時mm分
 [0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分
 M月d日HH時mm分

 [0-9][0-9]月[0-9]日[0-9]時
 MM月d日H時
 [0-9][0-9]月[0-9]日[0-9][0-9]時
 MM月d日HH時
 [0-9][0-9]月[0-9]日[0-9]時[0-9]分
 MM月d日H時m分
 [0-9][0-9]月[0-9]日[0-9][0-9]時[0-9]分
 MM月d日HH時m分
 [0-9][0-9]月[0-9]日[0-9]時[0-9][0-9]分
 MM月d日H時mm分
 [0-9][0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分
 MM月d日HH時mm分

 [0-9]月[0-9][0-9]日[0-9]時
 M月dd日H時
 [0-9]月[0-9][0-9]日[0-9][0-9]時
 M月dd日HH時
 [0-9]月[0-9][0-9]日[0-9]時[0-9]分
 M月dd日H時m分
 [0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分
 M月dd日HH時m分
 [0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分
 M月dd日H時mm分
 [0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分
 M月dd日HH時mm分

 [0-9][0-9]月[0-9][0-9]日[0-9]時
 MM月dd日H時
 [0-9][0-9]月[0-9][0-9]日[0-9][0-9]時
 MM月dd日HH時
 [0-9][0-9]月[0-9][0-9]日[0-9]時[0-9]分
 MM月dd日H時m分
 [0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分
 MM月dd日HH時m分
 [0-9][0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分
 MM月dd日H時mm分
 [0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分
 MM月dd日HH時mm分


 ————————————————————

 【〇月〇日】


 [0-9]月[0-9]日
 M月d日

 [0-9][0-9]月[0-9]日
 MM月d日

 [0-9]月[0-9][0-9]日
 M月dd日

 [0-9][0-9]月[0-9][0-9]日
 MM月dd日

 ————————————————————

 【〇月】

 [0-9]月
 M月
 [0-9][0-9]月
 MM月


 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————


 【〇日＋時刻指定】

 [0-9]日[0-9]時
 d日H時
 [0-9]日[0-9][0-9]時
 d日HH時
 [0-9]日[0-9]時[0-9]分
 d日H時m分
 [0-9]日[0-9][0-9]時[0-9]分
 d日HH時m分
 [0-9]日[0-9]時[0-9][0-9]分
 d日H時mm分
 [0-9]日[0-9][0-9]時[0-9][0-9]分
 d日HH時mm分
 [0-9][0-9]日[0-9]時
 dd日H時
 [0-9][0-9]日[0-9][0-9]時
 dd日HH時
 [0-9][0-9]日[0-9]時[0-9]分
 dd日H時m分
 [0-9][0-9]日[0-9][0-9]時[0-9]分
 dd日HH時m分
 [0-9][0-9]日[0-9]時[0-9][0-9]分
 dd日H時mm分
 [0-9][0-9]日[0-9][0-9]時[0-9][0-9]分
 dd日HH時mm分



 ————————————————————

 【〇日】

 [0-9]日
 d日
 [0-9][0-9]日
 dd日


 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————

 【時刻指定】


 [0-9]時
 H時
 [0-9][0-9]時
 HH時
 [0-9]時[0-9]分
 H時m分
 [0-9][0-9]時[0-9]分
 HH時m分
 [0-9]時[0-9][0-9]分
 H時mm分
 [0-9][0-9]時[0-9][0-9]分
 HH時mm分


 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————
 ————————————————————————————————————————————————————————————


 */

// 想定パターン phase.3
/*

 ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9]時$","unicode35": "yyyy年M月d日H時"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時$","unicode35": "yyyy年M月d日HH時"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9]時[0-9]分$","unicode35": "yyyy年M月d日H時m分"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "yyyy年M月d日HH時m分"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "yyyy年M月d日H時mm分"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "yyyy年M月d日HH時mm分"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時$","unicode35": "yyyy年MM月d日H時"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時$","unicode35": "yyyy年MM月d日HH時"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時[0-9]分$","unicode35": "yyyy年MM月d日H時m分"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "yyyy年MM月d日HH時m分"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "yyyy年MM月d日H時mm分"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "yyyy年MM月d日HH時mm分"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時$","unicode35": "yyyy年M月dd日H時"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時$","unicode35": "yyyy年M月dd日HH時"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "yyyy年M月dd日H時m分"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "yyyy年M月dd日HH時m分"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "yyyy年M月dd日H時mm分"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "yyyy年M月dd日HH時mm分"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時$","unicode35": "yyyy年MM月dd日H時"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時$","unicode35": "yyyy年MM月dd日HH時"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "yyyy年MM月dd日H時m分"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "yyyy年MM月dd日HH時m分"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "yyyy年MM月dd日H時mm分"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "yyyy年MM月dd日HH時mm分"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9]日$","unicode35": "yyyy年M月d日"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9]日$","unicode35": "yyyy年MM月d日"],
 ["regex": "^[0-9]{4}年[0-9]月[0-9][0-9]日$","unicode35": "yyyy年M月dd日"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月[0-9][0-9]日$","unicode35": "yyyy年MM月dd日"],
 ["regex": "^[0-9]{4}年[0-9]月$","unicode35": "yyyy年M月"],
 ["regex": "^[0-9]{4}年[0-9][0-9]月$","unicode35": "yyyy年MM月"],
 ["regex": "^[0-9]月[0-9]日[0-9]時$","unicode35": "M月d日H時"],
 ["regex": "^[0-9]月[0-9]日[0-9][0-9]時$","unicode35": "M月d日HH時"],
 ["regex": "^[0-9]月[0-9]日[0-9]時[0-9]分$","unicode35": "M月d日H時m分"],
 ["regex": "^[0-9]月[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "M月d日HH時m分"],
 ["regex": "^[0-9]月[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "M月d日H時mm分"],
 ["regex": "^[0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "M月d日HH時mm分"],
 ["regex": "^[0-9][0-9]月[0-9]日[0-9]時$","unicode35": "MM月d日H時"],
 ["regex": "^[0-9][0-9]月[0-9]日[0-9][0-9]時$","unicode35": "MM月d日HH時"],
 ["regex": "^[0-9][0-9]月[0-9]日[0-9]時[0-9]分$","unicode35": "MM月d日H時m分"],
 ["regex": "^[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "MM月d日HH時m分"],
 ["regex": "^[0-9][0-9]月[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "MM月d日H時mm分"],
 ["regex": "^[0-9][0-9]月[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "MM月d日HH時mm分"],
 ["regex": "^[0-9]月[0-9][0-9]日[0-9]時$","unicode35": "M月dd日H時"],
 ["regex": "^[0-9]月[0-9][0-9]日[0-9][0-9]時$","unicode35": "M月dd日HH時"],
 ["regex": "^[0-9]月[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "M月dd日H時m分"],
 ["regex": "^[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "M月dd日HH時m分"],
 ["regex": "^[0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "M月dd日H時mm分"],
 ["regex": "^[0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "M月dd日HH時mm分"],
 ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9]時$","unicode35": "MM月dd日H時"],
 ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時$","unicode35": "MM月dd日HH時"],
 ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "MM月dd日H時m分"],
 ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "MM月dd日HH時m分"],
 ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "MM月dd日H時mm分"],
 ["regex": "^[0-9][0-9]月[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "MM月dd日HH時mm分"],
 ["regex": "^[0-9]月[0-9]日$","unicode35": "M月d日"],
 ["regex": "^[0-9][0-9]月[0-9]日$","unicode35": "MM月d日"],
 ["regex": "^[0-9]月[0-9][0-9]日$","unicode35": "M月dd日"],
 ["regex": "^[0-9][0-9]月[0-9][0-9]日$","unicode35": "MM月dd日"],
 ["regex": "^[0-9]月$","unicode35": "M月"],
 ["regex": "^[0-9][0-9]月$","unicode35": "MM月"],
 ["regex": "^[0-9]日[0-9]時$","unicode35": "d日H時"],
 ["regex": "^[0-9]日[0-9][0-9]時$","unicode35": "d日HH時"],
 ["regex": "^[0-9]日[0-9]時[0-9]分$","unicode35": "d日H時m分"],
 ["regex": "^[0-9]日[0-9][0-9]時[0-9]分$","unicode35": "d日HH時m分"],
 ["regex": "^[0-9]日[0-9]時[0-9][0-9]分$","unicode35": "d日H時mm分"],
 ["regex": "^[0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "d日HH時mm分"],
 ["regex": "^[0-9][0-9]日[0-9]時$","unicode35": "dd日H時"],
 ["regex": "^[0-9][0-9]日[0-9][0-9]時$","unicode35": "dd日HH時"],
 ["regex": "^[0-9][0-9]日[0-9]時[0-9]分$","unicode35": "dd日H時m分"],
 ["regex": "^[0-9][0-9]日[0-9][0-9]時[0-9]分$","unicode35": "dd日HH時m分"],
 ["regex": "^[0-9][0-9]日[0-9]時[0-9][0-9]分$","unicode35": "dd日H時mm分"],
 ["regex": "^[0-9][0-9]日[0-9][0-9]時[0-9][0-9]分$","unicode35": "dd日HH時mm分"],
 ["regex": "^[0-9]日$","unicode35": "d日"],
 ["regex": "^[0-9][0-9]日$","unicode35": "dd日"],
 ["regex": "^[0-9]時$","unicode35": "H時"],
 ["regex": "^[0-9][0-9]時$","unicode35": "HH時"],
 ["regex": "^[0-9]時[0-9]分$","unicode35": "H時m分"],
 ["regex": "^[0-9][0-9]時[0-9]分$","unicode35": "HH時m分"],
 ["regex": "^[0-9]時[0-9][0-9]分$","unicode35": "H時mm分"],
 ["regex": "^[0-9][0-9]時$-9][0-9]分","unicode35": "HH時mm分"]

 */
