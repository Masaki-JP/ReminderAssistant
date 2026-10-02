import Foundation


extension JapaneseDateConverter {
    func StringからoptionalDateに変換(str: String, unicode35: String) -> Date? {
        
        let newStr = 文字列を〇年〇月〇日〇時〇分〇秒の形に加工(str)
        
        let newUnicode35 = unicode35を〇年〇月〇日〇時〇分〇秒の形に加工(unicode35)
        
        let date = StringからDateに変換したものを再度Stringにしてズレのないことを確認(str: newStr, unicode: newUnicode35)
        
        return date
    }
}




extension JapaneseDateConverter {
    
    
    func 文字列を〇年〇月〇日〇時〇分〇秒の形に加工(_ str: String) -> String {
        
        // year, month, day, hour, minuteの作成
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
        
        // 足りないものを付け足していく
        var newStr = str
        if !newStr.contains("年") {
            newStr.insert(contentsOf: year, at: newStr.index(newStr.startIndex, offsetBy: 0))
        }
        if !newStr.contains("月") {
            newStr.insert(contentsOf: month, at: newStr.index(newStr.firstIndex(of: "年")!, offsetBy: 1))
        }
        if !newStr.contains("日") {
            newStr.insert(contentsOf: day, at: newStr.index(newStr.firstIndex(of: "月")!, offsetBy: 1))
        }
        if !newStr.contains("時") {
            newStr.insert(contentsOf: hour, at: newStr.index(newStr.firstIndex(of: "日")!, offsetBy: 1))
        }
        if !newStr.contains("分") {
            newStr.insert(contentsOf: minute, at: newStr.index(newStr.firstIndex(of: "時")!, offsetBy: 1))
        }
        if !newStr.contains("秒") {
            newStr.insert(contentsOf: second, at: newStr.index(newStr.firstIndex(of: "分")!, offsetBy: 1))
        }
        
        //// コードは短いが分かりにくい
        //  var newStr = str
        //        let 年・月・日・時・分・秒: Array<(targetCharacter: String, insertion: String)>
        //        = [ ("年", year), ("月", month), ("日", day), ("時", hour), ("分", minute), ("秒", second)]
        //
        //        for i in 年・月・日・時・分・秒.indices {
        //            if 年・月・日・時・分・秒[i].targetCharacter == "年" && !newStr.contains(年・月・日・時・分・秒[i].targetCharacter) {
        //
        //                newStr.insert(contentsOf: 年・月・日・時・分・秒[i].insertion, at: newStr.index(newStr.startIndex, offsetBy: 0))
        //
        //            } else if !newStr.contains(年・月・日・時・分・秒[i].targetCharacter) {
        //
        //                newStr.insert(contentsOf: 年・月・日・時・分・秒[i].insertion, at: newStr.index(newStr.firstIndex(of: 年・月・日・時・分・秒[i-1].targetCharacter.first!)!, offsetBy: 1))
        //            }
        //
        //        }
        
        return newStr
    }
    
    
    
    func unicode35を〇年〇月〇日〇時〇分〇秒の形に加工(_ str: String) -> String {
        
        var newUnicode35 = str
        
        // 足りないものを付け足していく
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

        return newUnicode35
    }
    
    
    /// 11月31日など入力された時は12月01日に変換されてしまうため
    func StringからDateに変換したものを再度Stringにしてズレのないことを確認(str: String, unicode: String) -> Date? {
        dateFormatter.dateFormat = unicode
        guard let date = dateFormatter.date(from: str),
              str == dateFormatter.string(from: date)
        else {  return nil }
        return date
    }
}

