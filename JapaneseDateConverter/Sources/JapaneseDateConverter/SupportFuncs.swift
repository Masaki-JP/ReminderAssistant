import Foundation

extension JapaneseDateConverter {
    
    func 文字列が正規表現に当てはまるか(str: String, regex: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { fatalError() }
        let results = regex.matches(in: str, options: [], range: NSRange(0..<str.count))
        return !results.isEmpty ? true : false
    }
    
    /// 指定された正規表現で抽出された文字列を返す。
    /// 抽出された文字列が複数の場合、もしくは抽出されなかった場合はnilを返す。
    func getOnlyOneMatchString(str: String, regex: String) -> String? {
        let regex = try? NSRegularExpression(pattern: regex)
        let results = regex?.matches(in: str, range: NSRange(0..<str.count))
        
        guard let results, results.count == 1 else { return nil }
        
        let start = str.index(str.startIndex, offsetBy: results[0].range(at: 0).location)
        let end = str.index(start, offsetBy: results[0].range(at: 0).length)
        let str = String(str[start..<end])
        return str
    }
    
}

