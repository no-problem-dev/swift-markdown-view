import Testing
@testable import MarkdownModel

/// 未閉じのディスプレイ数式が後続のブロックを飲み込まないことの検証。
///
/// `$$` は複数行にまたがれるが、閉じデリミターが無いときに文書末まで探し続けると、
/// 後ろにあるコードブロックや段落が丸ごと数式として抽出される。インライン版（`$...$`）は
/// `\n` と `` ` `` で打ち切っているのに、ディスプレイ版には打ち切り条件が無かった。
@Suite("未閉じディスプレイ数式がブロックを越えない")
struct MathScannerBlockBoundaryTests {

    // 閉じ側の `$$` は後続ブロックの内側にある。これが無いと走査が無害に失敗するだけで、
    // 「ブロックを飲み込む」経路そのものを踏まない。

    @Test("未閉じ $$ が後続のフェンスコードを飲み込まない")
    func unclosedDisplayMathStopsBeforeFence() {
        let source = "He paid $$ for it.\n\n```js\nconst a = \"$$\";\n```\n"
        let content = MarkdownContent(parsing: source)
        // コードブロックが原文のまま残っていること。
        #expect(content.blocks.contains { block in
            if case .codeBlock(let language, let code) = block {
                return language == "js" && code == "const a = \"$$\";\n"
            }
            return false
        })
        #expect(!content.blocks.contains { if case .math = $0 { true } else { false } })
    }

    @Test("未閉じ $$ が後続のインデントコードを飲み込まない")
    func unclosedDisplayMathStopsBeforeIndentedCode() {
        let source = "Cost: $$ maybe.\n\n    let s = \"$$\"\n\ntail\n"
        let content = MarkdownContent(parsing: source)
        #expect(content.blocks.contains { block in
            if case .codeBlock(_, let code) = block { return code.contains("let s") }
            return false
        })
    }

    @Test("未閉じ $$ が空行を越えて次の段落の $$ と対にならない")
    func unclosedDisplayMathStopsAtBlankLine() {
        let source = "He paid $$ for it.\n\nSecond $$ paragraph.\n"
        let content = MarkdownContent(parsing: source)
        // 2 段落が残り、段落をまたぐ数式ブロックは生まれない。
        let paragraphCount = content.blocks.filter { if case .paragraph = $0 { true } else { false } }.count
        #expect(paragraphCount == 2)
        #expect(!content.blocks.contains { if case .math = $0 { true } else { false } })
    }

    @Test("正しく閉じたディスプレイ数式は複数行でも従来どおり")
    func closedDisplayMathStillSpansLines() {
        let source = "$$\na + b\n= c\n$$\n"
        let content = MarkdownContent(parsing: source)
        #expect(content.blocks == [.math("a + b\n= c")])
    }

    @Test("段落内で閉じたディスプレイ数式は従来どおり")
    func inlineClosedDisplayMathStillWorks() {
        let parts = MathScanner.parts(in: "before $$x$$ after")
        #expect(parts == [
            .text("before "),
            .math(latex: "x", isDisplay: true, raw: "$$x$$"),
            .text(" after"),
        ])
    }
}
