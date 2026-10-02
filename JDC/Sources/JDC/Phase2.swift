import Foundation

extension JapaneseDateConverter {
    
    func getUnicode35DateFormat(from str: String) -> String? {
        var matchUnicode35: String? = nil
     
        for set in setsOfRegularExpressionAndUnicode35DateFormat {
            guard 文字列が正規表現に当てはまるか(str: str, regex: set["regex"]!)
            else { continue }
            
            matchUnicode35 = set["unicode35"]!
            break
        }
        
        return matchUnicode35
    }
    
}

