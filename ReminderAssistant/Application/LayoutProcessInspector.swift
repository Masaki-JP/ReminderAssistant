import SwiftUI

/// SwiftUIのレイアウト処理で提案・報告されるサイズと、サブビューの配置位置をコンソールに出力するレイアウト。
///
/// 参考: https://zenn.dev/holoholo/articles/374c2b09bb7e5e
private struct LayoutProcessInspector: Layout {
    var tag: String
    var printPosition: Bool
    
    init(_ tag: String, printPosition: Bool = false) {
        self.tag = tag
        self.printPosition = printPosition
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        print("【\(tag)】proposal size:", proposal)
        let size = subviews[0].sizeThatFits(proposal)
        print("【\(tag)】report size:", size)
        return size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let position = bounds.origin
        subviews[0].place(at: position, proposal: proposal)
        if printPosition == true { print("【\(tag)】position: \(position)") }
    }
}

extension View {
    func inspectLayoutProcess(_ tag: String, printPosition: Bool = false) -> some View {
        LayoutProcessInspector(tag, printPosition: printPosition) { self }
    }
}
