import Foundation

extension JapaneseDateConverter {
    
    // 受け取った日本語による日付表現をDate型で返す
    public func convert(from japaneseDate: String) -> Date? {
        
        // Phase1: 日本語による日付の入力を整形する
        let formattedJapaneseDate = getFormattedJapaneseDate(from: japaneseDate)
        
        // Phase2: 整形されたものに当てはまる正規表現を探し、その正規表現のUnicode35DateFormatを返す
        guard let matchUnicode35 = getUnicode35DateFormat(from: formattedJapaneseDate)
        else { return nil}
        
        // Phase3: Date型を作成する
        guard let date = StringからoptionalDateに変換(str: formattedJapaneseDate, unicode35: matchUnicode35)
        else { return nil }
        
        return date
    }
    
    
    // 受け取ったDate型を「yyyy年M月dd日 H:mm」の形で返す
    public func getFamiliarDateExpression(from str: Date, dateFormat: String = "yyyy年M月d日 H:mm") -> String? {
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: str)
    }
    
}

