//
//  Class_MyRegex.swift
//  MyReminder_2210
//
//  Created by 土井正貴 on 2022/10/05.
//
import Foundation







// 複合関数
extension MyRegex {

    // String型 -> Date型
    func getDateFromString(unicode35: String, deadline: String) -> Date? {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = unicode35
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        var date = dateFormatter.date(from: deadline)
        guard date != nil else {
            return nil
        }

        // このタイミングで引数deadlineの文字列、dateFormatter.string()で出力された文字列、この二つが同じかどうかチェックする予定

        let today = Date()
        if !(deadline.contains("年")) {
            date = dateFormatter.calendar.date(byAdding: .year, value: (dateFormatter.calendar.component(.year, from: today)-2000), to: date!)
        }
        if !(deadline.contains("月")) {
            date = dateFormatter.calendar.date(byAdding: .month, value: (dateFormatter.calendar.component(.month, from: today)-1), to: date!)
        }
        if !(deadline.contains("日")) {
            date = dateFormatter.calendar.date(byAdding: .day, value: (dateFormatter.calendar.component(.day, from: today)-1), to: date!)
        }
        if !(deadline.contains("時")) {
            date = dateFormatter.calendar.date(byAdding: .hour, value: 9, to: date!)
        }

        // このタイミングで

        return date
    }


    // 期限の整形と置換を行い、それを返す
    func getFormattedDeadline(deadline: String) -> String {
        var formattedDeadline = deadline
        formattedDeadline = fullwidthToHalfwidth(formattedDeadline) ?? formattedDeadline // 全角文字を半角文字へ変換
        formattedDeadline = removeStrings(str: formattedDeadline) // 余計な文字列を削除
        formattedDeadline = addFirstDay(str: formattedDeadline) // 〇月で終わる場合、語尾に1日を追加
        return formattedDeadline
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
        let unnecessaryStrings = ["と", "の", " ", "　"] // スペースは全角と半角のもの
        unnecessaryStrings.forEach { unnecessaryStr in
            newStr = newStr.replacingOccurrences(of: unnecessaryStr, with: "")
        }
        return newStr
    }

    // 文字列が「月」で終わる場合、「1日」を追加する。
    func addFirstDay(str: String) -> String {
        if str.last == "月" {
            var newStr = str
            newStr += "1日"
            return newStr
        } else {
            return str
        }
    }

    // 文字列が正規表現に当てはまるか否か
    func matchOrNot(dateString: String, regexPattern: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: regexPattern, options: [])
        let results = regex.matches(in: dateString, options: [], range: NSRange(0..<dateString.count))
        if !(results.isEmpty) {
            return true
        } else {
            return false
        }
    }
}










final class MyRegex {

    // 絶対的時間指定のパターン
    let absolutePatterns_221007 = [
        ///
        ///【時刻指定のみ】
        ///
        ["regex" : "^[0-9]時$", "unicode35" : "HH時"],
        ["regex" : "^[0-1][0-9]時$", "unicode35" : "HH時"],
        ["regex" : "^2[0-3]時$", "unicode35" : "HH時"],
        ["regex" : "^[0-9]時[0-9]分$", "unicode35" : "HH時mm分"],
        ["regex" : "^[0-1][0-9]時[0-9]分$", "unicode35" : "HH時mm分"],
        ["regex" : "^2[0-3]時[0-9]分$", "unicode35" : "HH時mm分"],
        ["regex" : "^[0-9]時[0-5][0-9]分$", "unicode35" : "HH時mm分"],
        ["regex" : "^[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "HH時mm分"],
        ["regex" : "^2[0-3]時[0-5][0-9]分$", "unicode35" : "HH時mm分"],
        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【時刻指定なし】
        ///
        ["regex" : "^[1-9]月$", "unicode35" : "MM月"],
        ["regex" : "^1[0-2]月$", "unicode35" : "MM月"],
        ["regex" : "^[1-9]日$", "unicode35" : "dd日"],
        ["regex" : "^[1-2][0-9]日$", "unicode35" : "dd日"],
        ["regex" : "^3[0-1]日$", "unicode35" : "dd日"],
        ["regex" : "^[1-9]月[1-9]日$", "unicode35" : "MM月dd日"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日$", "unicode35" : "yyyy年MM月dd日"],
        ["regex" : "^1[0-2]月[1-9]日$", "unicode35" : "MM月dd日"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日$", "unicode35" : "yyyy年MM月dd日"],
        ["regex" : "^[1-9]月[1-2][0-9]日$", "unicode35" : "MM月dd日"],
        ["regex" : "^[1-9]月3[0-1]日$", "unicode35" : "MM月dd日"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日$", "unicode35" : "yyyy年MM月dd日"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日$", "unicode35" : "yyyy年MM月dd日"],
        ["regex" : "^1[0-2]月[1-2][0-9]日$", "unicode35" : "MM月dd日"],
        ["regex" : "^1[0-2]月3[0-1]日$", "unicode35" : "MM月dd日"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日$", "unicode35" : "yyyy年MM月dd日"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日$", "unicode35" : "yyyy年MM月dd日"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月$", "unicode35" : "yyyy年MM月"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月$", "unicode35" : "yyyy年MM月"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【n時：[0-9]時】
        ///
        ["regex" : "^[1-9]日[0-9]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^[1-2][0-9]日[0-9]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^3[0-1]日[0-9]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^[1-9]月[1-9]日[0-9]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日[0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^1[0-2]月[1-9]日[0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日[0-9]時$", "unicode35" : "yyyy年MM月HH時"],
        ["regex" : "^[1-9]月[1-2][0-9]日[0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-9]月3[0-1]日[0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日[0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日[0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^1[0-2]月[1-2][0-9]日[0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^1[0-2]月3[0-1]日[0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日[0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日[0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【nn時①：[0-1][0-9]時】
        ///
        ["regex" : "^[1-9]日[0-1][0-9]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^[1-2][0-9]日[0-1][0-9]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^3[0-1]日[0-1][0-9]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^[1-9]月[1-9]日[0-1][0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日[0-1][0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^1[0-2]月[1-9]日[0-1][0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日[0-1][0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^[1-9]月[1-2][0-9]日[0-1][0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-9]月3[0-1]日[0-1][0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日[0-1][0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日[0-1][0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^1[0-2]月[1-2][0-9]日[0-1][0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^1[0-2]月3[0-1]日[0-1][0-9]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日[0-1][0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日[0-1][0-9]時$", "unicode35" : "yyyy年MM月dd日HH時"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【nn時②：2[0-3]時】
        ///
        ["regex" : "^[1-9]日2[0-3]時$", "unicode35" : "HH時"],
        ["regex" : "^[1-2][0-9]日2[0-3]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^3[0-1]日2[0-3]時$", "unicode35" : "dd日HH時"],
        ["regex" : "^[1-9]月[1-9]日2[0-3]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日2[0-3]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^1[0-2]月[1-9]日2[0-3]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日2[0-3]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^[1-9]月[1-2][0-9]日2[0-3]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-9]月3[0-1]日2[0-3]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日2[0-3]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日2[0-3]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^1[0-2]月[1-2][0-9]日2[0-3]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^1[0-2]月3[0-1]日2[0-3]時$", "unicode35" : "MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日2[0-3]時$", "unicode35" : "yyyy年MM月dd日HH時"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日2[0-3]時$", "unicode35" : "yyyy年MM月dd日HH時"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【n時n分：[0-9]時[0-9]分】
        ///
        ["regex" : "^[1-9]日[0-9]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-2][0-9]日[0-9]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^3[0-1]日[0-9]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-9]日[0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日[0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-9]日[0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日[0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-2][0-9]日[0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月3[0-1]日[0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日[0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日[0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-2][0-9]日[0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月3[0-1]日[0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日[0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日[0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【nn時n分①：[0-1][0-9]時[0-9]分】
        ///
        ["regex" : "^[1-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-2][0-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^3[0-1]日[0-1][0-9]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-2][0-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月3[0-1]日[0-1][0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日[0-1][0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-2][0-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月3[0-1]日[0-1][0-9]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日[0-1][0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日[0-1][0-9]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【nn時n分②：2[0-3]時[0-9]分】
        ///
        ["regex" : "^[1-9]日2[0-3]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-2][0-9]日2[0-3]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^3[0-1]日2[0-3]時[0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-9]日2[0-3]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日2[0-3]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-9]日2[0-3]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日2[0-3]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-2][0-9]日2[0-3]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月3[0-1]日2[0-3]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日2[0-3]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日2[0-3]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-2][0-9]日2[0-3]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月3[0-1]日2[0-3]時[0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日2[0-3]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日2[0-3]時[0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【n時nn分：[0-9]時[0-5][0-9]分】
        ///
        ["regex" : "^[1-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-2][0-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^3[0-1]日[0-9]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-2][0-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月3[0-1]日[0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日[0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-2][0-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月3[0-1]日[0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日[0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日[0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【nn時nn分①：[0-1][0-9]時[0-5][0-9]分】
        ///
        ["regex" : "^[1-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-2][0-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^3[0-1]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-2][0-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月3[0-1]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-2][0-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月3[0-1]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日[0-1][0-9]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],

        ///////////////////////////////////////////////////////////////////////////////
        ///
        ///【nn時nn分②：2[0-3]時[0-5][0-9]分】
        ///
        ["regex" : "^[1-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-2][0-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^3[0-1]日2[0-3]時[0-5][0-9]分$", "unicode35" : "dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月[1-2][0-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-9]月3[0-1]日2[0-3]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月[1-2][0-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年[1-9]月3[0-1]日2[0-3]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月[1-2][0-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^1[0-2]月3[0-1]日2[0-3]時[0-5][0-9]分$", "unicode35" : "MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月[1-2][0-9]日2[0-3]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
        ["regex" : "^[1-2][0-9][0-9][0-9]年1[0-2]月3[0-1]日2[0-3]時[0-5][0-9]分$", "unicode35" : "yyyy年MM月dd日HH時mm分"],
    ] // END: absolutePatterns


}
