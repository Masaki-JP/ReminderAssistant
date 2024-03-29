//
//  Class_MyRegex.swift
//  ReminderAssistant_ver2.0
//
//  Created by 土井正貴 on 2022/10/09.
//

import Foundation





// 複合関数
extension MyRegex {

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


        // String型からDate型を生成したときに時間のずれが生じていないか確認
        dateFormatter.dateFormat = newUnicode35
        let deadline_Date = dateFormatter.date(from: newDeadline)
        guard deadline_Date != nil else {fatalError()}
        guard newDeadline == dateFormatter.string(from: deadline_Date!) else {return nil}

        return deadline_Date
    }


    // 期限の整形
    func getFormattedDeadline(deadline: String) -> String {
        var formattedDeadline = deadline
        formattedDeadline = fullwidthToHalfwidth(formattedDeadline) ?? formattedDeadline // 全角文字を半角文字へ変換
        formattedDeadline = removeStrings(str: formattedDeadline) // 余計な文字列を削除
        formattedDeadline = addFirstDay(str: formattedDeadline) // 文字列が「月」で終わる場合、「01日」を追加する。
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

//    func replace(str: String) -> String {
//        var newStr = str
//        newStr = newStr.replacingOccurrences(of: "r", with: "R")
//        return newStr
//    }

    // 文字列が正規表現に当てはまるか否か
    func matchOrNot(dateString: String, regexPattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: []) else {fatalError()}
        let results = regex.matches(in: dateString, options: [], range: NSRange(0..<dateString.count))
        if !(results.isEmpty) {
            return true
        } else {
            return false
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
