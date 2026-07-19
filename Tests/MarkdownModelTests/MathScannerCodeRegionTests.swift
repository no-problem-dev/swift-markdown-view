import Testing
@testable import MarkdownModel

/// コード領域が数式として解釈されないことの検証。
///
/// ここが破れるとコードブロックの中身が原文と食い違って表示される。Markdown レンダラとして
/// 最も壊してはいけない性質なので、CommonMark のコード構文 4 種すべてに対して検証する。
@Suite("MathScanner がコード領域を保護する")
struct MathScannerCodeRegionTests {

    // MARK: バッククォートフェンス

    @Test("バッククォートフェンス内の $ は数式にならない")
    func backtickFencePreservesDollars() {
        let content = MarkdownContent(parsing: "```\n$x$\n```")
        #expect(content.blocks == [.codeBlock(language: nil, code: "$x$\n")])
    }

    @Test("言語指定つきバッククォートフェンスでも保護される")
    func backtickFenceWithLanguagePreservesDollars() {
        let content = MarkdownContent(parsing: "```swift\nlet cost = $5$\n```")
        #expect(content.blocks == [.codeBlock(language: "swift", code: "let cost = $5$\n")])
    }

    // MARK: チルダフェンス

    @Test("チルダフェンス内の $ は数式にならない")
    func tildeFencePreservesDollars() {
        let content = MarkdownContent(parsing: "~~~\n$x$\n~~~")
        #expect(content.blocks == [.codeBlock(language: nil, code: "$x$\n")])
    }

    @Test("言語指定つきチルダフェンスでも保護される")
    func tildeFenceWithLanguagePreservesDollars() {
        let content = MarkdownContent(parsing: "~~~python\ncost = $5$\n~~~")
        #expect(content.blocks == [.codeBlock(language: "python", code: "cost = $5$\n")])
    }

    @Test("4 本以上のチルダフェンスでも保護される")
    func longTildeFencePreservesDollars() {
        let content = MarkdownContent(parsing: "~~~~\n$x$\n~~~~")
        #expect(content.blocks == [.codeBlock(language: nil, code: "$x$\n")])
    }

    @Test("打ち消し線のチルダはフェンスと誤認されない")
    func strikethroughIsNotTreatedAsFence() {
        let content = MarkdownContent(parsing: "~~gone~~ and $x$ stays")
        let inlines = content.blocks.first.flatMap { block -> [MarkdownInline]? in
            if case .paragraph(let items) = block { return items }
            return nil
        }
        #expect(inlines?.contains(.inlineMath("x")) == true)
    }

    // MARK: インデントコードブロック

    @Test("4 スペースのインデントコード内の $ は数式にならない")
    func indentedCodePreservesDollars() {
        let content = MarkdownContent(parsing: "paragraph\n\n    let a = $5$\n")
        #expect(content.blocks.contains(.codeBlock(language: nil, code: "let a = $5$\n")))
    }

    @Test("インデントコードは空行を挟んでも継続する")
    func indentedCodeSurvivesBlankLine() {
        let source = "intro\n\n    let a = $1$\n\n    let b = $2$\n"
        let content = MarkdownContent(parsing: source)
        let code = content.blocks.compactMap { block -> String? in
            if case .codeBlock(_, let code) = block { return code }
            return nil
        }.joined()
        #expect(code.contains("$1$"))
        #expect(code.contains("$2$"))
    }

    @Test("段落の継続行はインデントされていてもコードではない")
    func indentedParagraphContinuationIsNotCode() {
        // CommonMark: インデントコードは段落を中断できない。
        // よってこの $x$ は通常のインライン数式として解釈される。
        let content = MarkdownContent(parsing: "paragraph\n    $x$\n")
        let isCodeBlock = content.blocks.contains { block in
            if case .codeBlock = block { return true }
            return false
        }
        #expect(isCodeBlock == false)
    }

    // MARK: インラインコードスパン

    @Test("インラインコードスパン内の $ は数式にならない")
    func codeSpanPreservesDollars() {
        let content = MarkdownContent(parsing: "Use `$HOME$` here.")
        guard case .paragraph(let inlines)? = content.blocks.first else {
            Issue.record("段落が得られなかった")
            return
        }
        #expect(inlines.contains(.code("$HOME$")))
    }

    @Test("$ が先行してもコードスパンを飲み込まない")
    func dollarBeforeCodeSpanDoesNotSwallowIt() {
        // 回帰: 閉じデリミター探索がコードスパンを跨いでいたため、
        // `$HOME` の $ を閉じと誤認して "5, see `" を数式にしていた。
        let content = MarkdownContent(parsing: "The fee is $5, see `$HOME` for details.")
        guard case .paragraph(let inlines)? = content.blocks.first else {
            Issue.record("段落が得られなかった")
            return
        }
        #expect(inlines.contains(.code("$HOME")))
        let hasMath = inlines.contains { inline in
            if case .inlineMath = inline { return true }
            return false
        }
        #expect(hasMath == false)
    }

    // MARK: 数式が壊れていないことの確認（保護が過剰でないこと）

    @Test("コード外のインライン数式は従来どおり認識される")
    func inlineMathOutsideCodeStillParses() {
        let content = MarkdownContent(parsing: "The value $x^2$ matters.")
        guard case .paragraph(let inlines)? = content.blocks.first else {
            Issue.record("段落が得られなかった")
            return
        }
        #expect(inlines.contains(.inlineMath("x^2")))
    }

    @Test("コード外のディスプレイ数式は従来どおり認識される")
    func displayMathOutsideCodeStillParses() {
        let content = MarkdownContent(parsing: "$$\nx^2\n$$")
        #expect(content.blocks.contains(.math("x^2")))
    }

    @Test("フェンス直後の数式は保護対象外なので認識される")
    func mathAfterFenceStillParses() {
        let content = MarkdownContent(parsing: "```\ncode\n```\n\nthen $y$ here")
        guard case .paragraph(let inlines)? = content.blocks.last else {
            Issue.record("段落が得られなかった")
            return
        }
        #expect(inlines.contains(.inlineMath("y")))
    }
}
