import Testing
@testable import MarkdownModel

/// 数式の抽出・復元がドキュメント構造を壊さないことの検証。
@Suite("数式の前処理が構造を壊さない")
struct MathPreprocessorStructureTests {

    // MARK: B-5: ブロックへの切り出しが container を突き抜けない

    @Test("リスト項目の中のディスプレイ数式でリストが分断されない")
    func displayMathKeepsListIntact() {
        let content = MarkdownContent(parsing: "- item $$a$$ more\n")
        // リストが 1 つだけ残り、数式やテキストが外に漏れていないこと。
        #expect(content.blocks.count == 1)
        guard case .unorderedList(let items)? = content.blocks.first else {
            Issue.record("リストとしてパースされなかった: \(content.blocks)")
            return
        }
        #expect(items.count == 1)
        // 数式は項目の内側にブロックとして入る。
        #expect(items[0].blocks.contains { if case .math("a") = $0 { true } else { false } })
    }

    @Test("複数項目のリストが数式で壊れない")
    func multiItemListSurvives() {
        let content = MarkdownContent(parsing: "- one $$x$$\n- two\n- three\n")
        guard case .unorderedList(let items)? = content.blocks.first else {
            Issue.record("リストとしてパースされなかった: \(content.blocks)")
            return
        }
        #expect(items.count == 3)
    }

    @Test("引用の中のディスプレイ数式で引用が分断されない")
    func displayMathKeepsAsideIntact() {
        let content = MarkdownContent(parsing: "> note $$a$$ tail\n")
        #expect(content.blocks.count == 1)
    }

    @Test("段落の途中のディスプレイ数式は独立したブロックになる")
    func displayMathSplitsParagraph() {
        // 既存の意図された挙動。復元側へ移しても保たれること。
        let content = MarkdownContent(parsing: "before $$x$$ after\n")
        #expect(content.blocks.count == 3)
        #expect(content.blocks[1] == .math("x"))
    }

    @Test("インライン数式は段落を分割しない")
    func inlineMathDoesNotSplit() {
        let content = MarkdownContent(parsing: "before $x$ after\n")
        #expect(content.blocks.count == 1)
    }

    // MARK: B-4: ソース由来のトークン文字の注入

    @Test("ソース中の私用領域文字が数式プレースホルダーとして解釈されない")
    func privateUseCharactersAreNotTreatedAsTokens() {
        // 攻撃者が本文に U+E000 0 U+E001 を仕込んでも、既存の数式が複製されない。
        let content = MarkdownContent(parsing: "\u{E000}0\u{E001} and real $x$")
        guard case .paragraph(let inlines)? = content.blocks.first else {
            Issue.record("段落としてパースされなかった: \(content.blocks)")
            return
        }
        let mathCount = inlines.filter { if case .inlineMath = $0 { true } else { false } }.count
        #expect(mathCount == 1, "数式が \(mathCount) 個に増殖した")
    }

    @Test("私用領域文字だけがあり数式が無い場合は素通しする")
    func privateUseCharactersWithoutMathAreHarmless() {
        // 数式が 1 つも無ければ前処理そのものが走らない。原文がそのまま残る。
        let content = MarkdownContent(parsing: "plain \u{E000}0\u{E001} text")
        #expect(content.blocks.count == 1)
    }
}
