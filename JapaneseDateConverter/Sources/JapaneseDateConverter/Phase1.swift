import Foundation

extension JapaneseDateConverter {
    
    func getFormattedJapaneseDate(from japaneseDate: String) -> String {
        
        var formattedJapaneseDate = japaneseDate
        formattedJapaneseDate = 全角文字を半角文字に変換(formattedJapaneseDate)
        formattedJapaneseDate = 漢数字を数字に変換(formattedJapaneseDate)
        formattedJapaneseDate = 全スペ・半スペ・と・のを削除する(formattedJapaneseDate)
        formattedJapaneseDate = か月・ヵ月・カ月・ケ月・箇月をヶ月に変換(formattedJapaneseDate)
        formattedJapaneseDate = 今夜・今晩をyyyy年MM月dd日19時00分(formattedJapaneseDate)
        formattedJapaneseDate = 〇月末をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 再来月末をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 来月末をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 今月末・月末をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 再来週末をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 来週末をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 今週末・週末をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇曜日を〇曜に変換(formattedJapaneseDate)
        formattedJapaneseDate = 再来週〇曜をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 来週〇曜をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 今週〇曜をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 次〇曜を〇曜に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇曜をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 時半を時30分に変換(formattedJapaneseDate)
        formattedJapaneseDate = 早朝と朝と昼と正午と夜と晩をHH時mm分に変換(formattedJapaneseDate)
        formattedJapaneseDate = 再来年・来年をyyyy年に変換(formattedJapaneseDate)
        formattedJapaneseDate = 再来月・来月をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 再来週・来週をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 明日・明々後日・明明後日・明後日をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 文字列が月で終わる場合に01日を追加する(formattedJapaneseDate)
        formattedJapaneseDate = 〇年〇ヶ月後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇年半後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇年後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 半年後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇ヶ月半後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇ヶ月後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 半月後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇週間後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇日後をyyyy年MM月dd日に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇時間〇分後をyyyy年MM月HH時mm分ss秒に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇時間半後をyyyy年MM月HH時mm分ss秒に変換(formattedJapaneseDate)
        formattedJapaneseDate = 〇時間後からyyyy年MM月dd日HH時mm分ss秒(formattedJapaneseDate)
        formattedJapaneseDate = 〇分後からyyyy年MM月dd日HH時mm分ss秒(formattedJapaneseDate)
        return formattedJapaneseDate
        
    }
      
}


extension JapaneseDateConverter {
    

    
    func 全角文字を半角文字に変換(_ str: String) -> String {
        return str.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? str
    }

        
    
    func 漢数字を数字に変換(_ str: String) -> String {
        var str = str

        let kanjis = ["九十九", "九十八", "九十七", "九十六", "九十五", "九十四", "九十三", "九十二", "九十一", "九十", "八十九", "八十八", "八十七", "八十六", "八十五", "八十四", "八十三", "八十二", "八十一", "八十", "七十九", "七十八", "七十七", "七十六", "七十五", "七十四", "七十三", "七十二", "七十一", "七十", "六十九", "六十八", "六十七", "六十六", "六十五", "六十四", "六十三", "六十二", "六十一", "六十", "五十九", "五十八", "五十七", "五十六", "五十五", "五十四", "五十三", "五十二", "五十一", "五十", "四十九", "四十八", "四十七", "四十六", "四十五", "四十四", "四十三", "四十二", "四十一", "四十", "三十九", "三十八", "三十七", "三十六", "三十五", "三十四", "三十三", "三十二", "三十一", "三十", "二十九", "二十八", "二十七", "二十六", "二十五", "二十四", "二十三", "二十二", "二十一", "二十", "十九", "十八", "十七", "十六", "十五", "十四", "十三", "十二", "十一", "十", "九", "八", "七", "六", "五", "四", "三", "二", "一", "零"]

        kanjis.enumerated().forEach { kanji in
            str = str.replacingOccurrences(of: kanji.element, with: String(99 - kanji.offset))
        }

        return str
    }
    
    

    func 全スペ・半スペ・と・のを削除する(_ str: String) -> String {
        var str = str
        let uselessStrings = ["と", "の", "　", " "]
        uselessStrings.forEach { uselessStr in
            str = str.replacingOccurrences(of: uselessStr, with: "")
        }
        return str
    }

    
    
    func か月・ヵ月・カ月・ケ月・箇月をヶ月に変換(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "か月", with: "ヶ月")
            .replacingOccurrences(of: "ヵ月", with: "ヶ月")
            .replacingOccurrences(of: "カ月", with: "ヶ月")
            .replacingOccurrences(of: "ケ月", with: "ヶ月")
            .replacingOccurrences(of: "箇月", with: "ヶ月")
    }
    
    
    
    func 今夜・今晩をyyyy年MM月dd日19時00分(_ str: String) -> String {
        var str = str
        
        ["^今夜$", "^今晩$"].forEach { regex in
            if 文字列が正規表現に当てはまるか(str: str, regex: regex) {
                dateFormatter.dateFormat = "yyyy年MM月dd日"
                let tonight = dateFormatter.string(from: Date()) + "19時00分"
                str = tonight
            }
        }
        return str
    }

    
    
    func 〇月末をyyyy年MM月dd日に変換(_ str: String) -> String {
        guard let matchString = getOnlyOneMatchString(str: str, regex: "[1-9][1-9]{0,1}月末")
        else { return str }
           
        let yearNum = dateFormatter.calendar.component(.year, from: Date())
        let monthNum = Int((matchString.replacingOccurrences(of: "月末", with: "")))!
        let dayNum = 1
        let dateComponent = DateComponents(year: yearNum, month: monthNum, day: dayNum)
                
        var date = dateFormatter.calendar.date(from: dateComponent)!
        date = dateFormatter.calendar.date(byAdding: .month, value: 1, to: date)!
        date = dateFormatter.calendar.date(byAdding: .day, value: -1, to: date)!
                
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return str.replacingOccurrences(of: matchString, with: dateFormatter.string(from: date))
    }
    
    
    
    func 再来月末をyyyy年MM月dd日に変換(_ str: String) -> String {
        guard str.contains("再来月末") else { return str }
        
        let today = Date()
        let MonthAfterNextMonthDate = dateFormatter.calendar.date(byAdding: .month, value: 2, to: today)!
        let startOfMonth = dateFormatter.calendar.date(from: dateFormatter.calendar.dateComponents([.year, .month], from: MonthAfterNextMonthDate))!
        let range = dateFormatter.calendar.range(of: .day, in: .month, for: startOfMonth)!
        let endOfMonth = dateFormatter.calendar.date(byAdding: DateComponents(day: range.count-1), to: startOfMonth)!

        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return str.replacingOccurrences(of: "再来月末", with: dateFormatter.string(from: endOfMonth))
    }
    
    
    
    func 来月末をyyyy年MM月dd日に変換(_ str: String) -> String {
        guard str.contains("来月末") else { return str }
        
        let today = Date()
        let nextMonthDate = dateFormatter.calendar.date(byAdding: .month, value: 1, to: today)!
        let startOfMonth = dateFormatter.calendar.date(from: dateFormatter.calendar.dateComponents([.year, .month], from: nextMonthDate))!
        let range = dateFormatter.calendar.range(of: .day, in: .month, for: startOfMonth)!
        let endOfMonth = dateFormatter.calendar.date(byAdding: DateComponents(day: range.count-1), to: startOfMonth)!

        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return str.replacingOccurrences(of: "来月末", with: dateFormatter.string(from: endOfMonth))
    }
    
    
    
    func 今月末・月末をyyyy年MM月dd日に変換(_ str: String) -> String {
        var str = str
        
        if str.contains("今月末") {
            str = str.replacingOccurrences(of: "今月末", with: "月末")
        }
        
        guard str.contains("月末") else { return str }
        
        let today = Date()
        let startOfMonth = dateFormatter.calendar.date(from: dateFormatter.calendar.dateComponents([.year, .month], from: today))!
        let range = dateFormatter.calendar.range(of: .day, in: .month, for: startOfMonth)!
        let endOfMonth = dateFormatter.calendar.date(byAdding: DateComponents(day: range.count-1), to: startOfMonth)!

        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return str.replacingOccurrences(of: "月末", with: dateFormatter.string(from: endOfMonth))
    }
    
    
    
    func 再来週末をyyyy年MM月dd日に変換(_ str: String) -> String {
        guard str.contains("再来週末") else { return str }
        let weekdayOfSpecifiedDay = 7
        let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
        let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
        let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays+14), to: Date())!
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return str.replacingOccurrences(of: "再来週末", with: dateFormatter.string(from: date))

    }
    
    
    
    func 来週末をyyyy年MM月dd日に変換(_ str: String) -> String {
        guard str.contains("来週末") else { return str }
        let weekdayOfSpecifiedDay = 7
        let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
        let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
        let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays+7), to: Date())!
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return str.replacingOccurrences(of: "来週末", with: dateFormatter.string(from: date))

    }
    
    
    
    func 今週末・週末をyyyy年MM月dd日に変換(_ str: String) -> String {
        var str = str
        str = str.replacingOccurrences(of: "今週末", with: "週末")

        guard str.contains("週末") else { return str }
        let weekdayOfSpecifiedDay = 7
        let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())
        let additionalDays =  (weekdayOfSpecifiedDay - weekdayOfToday) > 0 ? (weekdayOfSpecifiedDay - weekdayOfToday) : (weekdayOfSpecifiedDay - weekdayOfToday) + 7
        let date = dateFormatter.calendar.date(byAdding: DateComponents(day: additionalDays), to: Date())! // FIXME: try!
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        return str.replacingOccurrences(of: "週末", with: dateFormatter.string(from: date))
    }
    
    
    
    func 〇曜日を〇曜に変換(_ str: String) -> String {
        var str = str
    
        for originWord in ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"] {
            guard str.contains(originWord) else { continue }
            
            let index = originWord.index(originWord.startIndex, offsetBy: 2)
            var omittedWord = originWord
            omittedWord.remove(at: index)
            
            str = str.replacingOccurrences(of: originWord, with: omittedWord)
            break
        }

        return str
    }
    
    
    
    func 再来週〇曜をyyyy年MM月dd日に変換(_ str: String) -> String {
        let str = str
        let specifications = ["再来週日曜", "再来週月曜", "再来週火曜", "再来週水曜", "再来週木曜", "再来週金曜", "再来週土曜"]
        
        for i in specifications.indices {
            guard str.contains(specifications[i]) else { continue }
            
            let fourteenDaysLater = dateFormatter.calendar.date(byAdding: .day, value: 14, to: Date())!
            let weekdayOfSpecification = i + 1
            let weekdayOfSevenDaysLater = dateFormatter.calendar.component(.weekday, from: fourteenDaysLater)
            let additionalDays = weekdayOfSpecification - weekdayOfSevenDaysLater + 14
            let date = dateFormatter.calendar.date(byAdding: .day, value: additionalDays, to: Date())!

            dateFormatter.dateFormat = "yyyy年MM月dd日"
            return str.replacingOccurrences(of: specifications[i], with: dateFormatter.string(from: date))
        }
        return str
    }
    
    
    
    func 来週〇曜をyyyy年MM月dd日に変換(_ str: String) -> String {
        let specifications = ["来週日曜", "来週月曜", "来週火曜", "来週水曜", "来週木曜", "来週金曜", "来週土曜"]

        for i in 0 ... 6 {
            guard !str.contains(specifications[i]) else {

                let dateFormatter = DateFormatter()
                dateFormatter.calendar = Calendar(identifier: .gregorian)
                dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
                dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
                dateFormatter.dateFormat = "yyyy年MM月dd日"

                let sevenDaysLater = dateFormatter.calendar.date(byAdding: .day, value: 7, to: Date())!

                let weekdayOfSpecification = i + 1
                let weekdayOfSevenDaysLater = dateFormatter.calendar.component(.weekday, from: sevenDaysLater)

                let additionalDays = weekdayOfSpecification - weekdayOfSevenDaysLater + 7

                let date = dateFormatter.calendar.date(byAdding: .day, value: additionalDays, to: Date())!

                return str.replacingOccurrences(of: specifications[i], with: dateFormatter.string(from: date))
            }
        }
        return str
    }
    
    
    
    func 今週〇曜をyyyy年MM月dd日に変換(_ str: String) -> String {
        let specifications = ["今週日曜", "今週月曜", "今週火曜", "今週水曜", "今週木曜", "今週金曜", "今週土曜"]

        for i in 0 ... 6 {
            guard !str.contains(specifications[i]) else {

                let dateFormatter = DateFormatter()
                dateFormatter.calendar = Calendar(identifier: .gregorian)
                dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
                dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
                dateFormatter.dateFormat = "yyyy年MM月dd日"

                let weekdayOfSpecification = i + 1
                let weekdayOfToday = dateFormatter.calendar.component(.weekday, from: Date())

                let additionalDays = weekdayOfSpecification - weekdayOfToday

                let date = dateFormatter.calendar.date(byAdding: .day, value: additionalDays, to: Date())!

                return str.replacingOccurrences(of: specifications[i], with: dateFormatter.string(from: date))
            }
        }
        return str
    }
    
    
    
    func 次〇曜を〇曜に変換(_ str: String) -> String {
        return  str.replacingOccurrences(of: "次日曜", with: "日曜")
            .replacingOccurrences(of: "次月曜", with: "月曜")
            .replacingOccurrences(of: "次火曜", with: "火曜")
            .replacingOccurrences(of: "次水曜", with: "水曜")
            .replacingOccurrences(of: "次木曜", with: "木曜")
            .replacingOccurrences(of: "次金曜", with: "金曜")
            .replacingOccurrences(of: "次土曜", with: "土曜")
    }
    
    
    
    func 〇曜をyyyy年MM月dd日に変換(_ str: String) -> String {
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
        
    
    
    func 時半を時30分に変換(_ str: String) -> String {
        return str.replacingOccurrences(of: "時半", with: "時30分")
    }
    
    
    
    func 早朝と朝と昼と正午と夜と晩をHH時mm分に変換(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "早朝", with: "06時00分")
            .replacingOccurrences(of: "朝", with: "08時00分")
            .replacingOccurrences(of: "昼", with: "12時00分")
            .replacingOccurrences(of: "正午", with: "12時00分")
            .replacingOccurrences(of: "夜", with: "19時00分")
            .replacingOccurrences(of: "晩", with: "19時00分")
    }
    
    
    
    func 再来年・来年をyyyy年に変換(_ str: String) -> String {
        var str = str
        let today = Date()
        dateFormatter.dateFormat = "yyyy年"
        
        // 再来年
        let yearAfterNext = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .year, value: 2, to: today)!)
        // 来年
        let nextYear = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .year, value: 1, to: today)!)
                
        str = str.replacingOccurrences(of: "再来年", with: yearAfterNext)
        str = str.replacingOccurrences(of: "来年", with: nextYear)
        
        return str
        // 再来年の変換処理後に来年の変換処理を行うこと
    }
    
    
    
    func 再来月・来月をyyyy年MM月dd日に変換(_ str: String) -> String {
        var str = str
        let today = Date()

        dateFormatter.dateFormat = "yyyy年MM月"
        
        // 再来月
        let monthAfterNext = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .month, value: 2, to: today)!)
        // 来月
        let nextMonth = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .month, value: 1, to: today)!)
        
        str = str.replacingOccurrences(of: "再来月", with: monthAfterNext)
        str = str.replacingOccurrences(of: "来月", with: nextMonth)
        
        return str
        // 再来月の変換処理の後に来月の変換処理を行うこと
    }
    
    
    
    func 再来週・来週をyyyy年MM月dd日に変換(_ str: String) -> String {
        var str = str
        let today = Date()

        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        // 再来週
        let weekAfterNext = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 14, to: today)!)
        // 来週
        let nextWeek = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 7, to: today)!)
        
        str = str.replacingOccurrences(of: "再来週", with: weekAfterNext)
        str = str.replacingOccurrences(of: "来週", with: nextWeek)
        
        return str
        // 再来週の変換処理の後に来週の変換処理を行うこと
    }
    
    
    
    func 明日・明々後日・明明後日・明後日をyyyy年MM月dd日に変換(_ str: String) -> String {
        var str = str
        let today = Date()
        
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        // 1日後
        let tommorow = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 1, to: today)!)
        // 2日後
        let twoDaysAfterTommorow = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 3, to: today)!)
        // 3日後
        let dayAfterTommorow = dateFormatter.string(from: dateFormatter.calendar.date(byAdding: .day, value: 2, to: today)!)
        
        str = str.replacingOccurrences(of: "明日", with: tommorow)
        str = str.replacingOccurrences(of: "明々後日", with: twoDaysAfterTommorow)
        str = str.replacingOccurrences(of: "明明後日", with: twoDaysAfterTommorow)
        str = str.replacingOccurrences(of: "明後日", with: dayAfterTommorow)
        
        return str
        // 明明後日の変換後に明後日の変換を行うこと
    }
    
    
    
    func 文字列が月で終わる場合に01日を追加する(_ str: String) -> String {
        return str.last == "月" ? str + "01日" : str
    }
    

    
    func 〇年〇ヶ月後をyyyy年MM月dd日に変換(_ str: String) -> String {
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
    
    
    
    func 〇年半後をyyyy年MM月dd日に変換(_ str: String) -> String {
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
    
    
    
    func 〇年後をyyyy年MM月dd日に変換(_ str: String) -> String {
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
    
    
    
    func 半年後をyyyy年MM月dd日に変換(_ str: String) -> String {
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
    
    
    
    func 〇ヶ月半後をyyyy年MM月dd日に変換(_ str: String) -> String {
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
    
    
    
    func 〇ヶ月後をyyyy年MM月dd日に変換(_ str: String) -> String {
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
    
    
    
    func 半月後をyyyy年MM月dd日に変換(_ str: String) -> String {
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
    
    
    
    func 〇週間後をyyyy年MM月dd日に変換(_ str: String) -> String {
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
    
    
    
    func 〇日後をyyyy年MM月dd日に変換(_ str: String) -> String {

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
    
    
    
    func 〇時間〇分後をyyyy年MM月HH時mm分ss秒に変換(_ str: String) -> String {
        if 文字列が正規表現に当てはまるか(str: str, regex: "^[1-9][0-9]{0,3}時間[1-9][0-9]{0,3}分後$") {
            let newStr = str.replacingOccurrences(of: "分後", with: "")
            let times = newStr.components(separatedBy: "時間")
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_Jp")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            var day = dateFormatter.calendar.date(byAdding: .hour, value: Int(times[0])!, to: Date())
            day = dateFormatter.calendar.date(byAdding: .minute, value: Int(times[1])!, to: day!)
            dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分ss秒"
            return dateFormatter.string(from: day!)
        } else {
            return str
        }
    }
    
    
    
    func 〇時間半後をyyyy年MM月HH時mm分ss秒に変換(_ str: String) -> String {
        if 文字列が正規表現に当てはまるか(str: str, regex: "^[1-9][0-9]{0,3}時間半後$") {
            let time = Int(str.replacingOccurrences(of: "時間半後", with: ""))!
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            var day = dateFormatter.calendar.date(byAdding: .hour, value: time, to: Date())
            day = dateFormatter.calendar.date(byAdding: .minute, value: 30, to: day!)
            dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分ss秒"
            return dateFormatter.string(from: day!)
        } else {
            return str
        }
    }
    
    
    
    func 〇時間後からyyyy年MM月dd日HH時mm分ss秒(_ str: String) -> String {
        if 文字列が正規表現に当てはまるか(str: str, regex: "^[1-9][0-9]{0,3}時間後$") {
            let time = Int(str.replacingOccurrences(of: "時間後", with: ""))!
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            let day = dateFormatter.calendar.date(byAdding: .hour, value: time, to: Date())!
            dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分ss秒"
            return dateFormatter.string(from: day)
        } else {
            return str
        }
    }
    
    
    
    func 〇分後からyyyy年MM月dd日HH時mm分ss秒(_ str: String) -> String { // FIXME: dateFormatter
        if 文字列が正規表現に当てはまるか(str: str, regex: "^[1-9][0-9]{0,3}分後$") {
            let time = Int(str.replacingOccurrences(of: "分後", with: ""))!
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.timeZone = TimeZone(identifier: "ja_JP")
            dateFormatter.locale = Locale(identifier: "Asia/Tokyo")
            let day = dateFormatter.calendar.date(byAdding: .minute, value: time, to: Date())!
            dateFormatter.dateFormat = "yyyy年MM月dd日HH時mm分ss秒"
            return dateFormatter.string(from: day)
        } else {
            return str
        }
    }
    
    
    
}


