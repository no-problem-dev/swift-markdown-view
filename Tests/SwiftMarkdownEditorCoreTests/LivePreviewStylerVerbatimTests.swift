import Testing
@testable import SwiftMarkdownEditorCore

/// フェンスコードブロックの中身がライブプレビューで書き換えられないことの検証。
///
/// エディタはブロック層を ``MarkdownTokenizer``（フェンスを状態として追う）、インライン層を
/// ``InlineSpanParser``（行単位でブロック文脈を持たない）で解析する。後者にフェンス範囲を
/// 渡さないと、ユーザーが書いたソースコードから `**` や `_` が消えて表示される。
/// Markdown エディタとしてコードブロックが編集できなくなるため、個別に固定する。
@Suite("ライブプレビューがフェンスコードを書き換えない")
struct LivePreviewStylerVerbatimTests {

    private func runs(_ text: String) -> [StyleRun] {
        LivePreviewStyler.runs(text: text, selection: nil, focused: false)
    }

    @Test("フェンス内の ** は conceal されず太字にもならない")
    func fencedStrongIsUntouched() {
        let result = runs("```\nlet a = **b**\n```")
        #expect(result.isEmpty)
    }

    @Test("フェンス内の _ は conceal されず斜体にもならない")
    func fencedEmphasisIsUntouched() {
        let result = runs("```\nlet c = _d_\n```")
        #expect(result.isEmpty)
    }

    @Test("チルダフェンスでも保護される")
    func tildeFenceIsUntouched() {
        let result = runs("~~~\nlet a = **b**\n~~~")
        #expect(result.isEmpty)
    }

    @Test("言語指定つきフェンスでも保護される")
    func fenceWithLanguageIsUntouched() {
        let result = runs("```swift\nlet a = **b**\n```")
        #expect(result.isEmpty)
    }

    @Test("フェンス外の強調は従来どおり処理される")
    func strongOutsideFenceStillStyled() {
        let result = runs("**bold**")
        #expect(result.contains { $0.trait == .bold })
        #expect(result.contains { $0.trait == .conceal })
    }

    @Test("フェンスの前後の強調だけが処理される")
    func onlyOutsideFenceIsStyled() {
        // 前後に 1 つずつ、フェンス内に 1 つ。処理されるのは 2 つだけ。
        let text = "**a**\n\n```\n**b**\n```\n\n**c**"
        let boldRuns = runs(text).filter { $0.trait == .bold }
        #expect(boldRuns.count == 2)
    }

    @Test("インラインコードの等幅装飾は失われない")
    func inlineCodeStillStyled() {
        // フェンスだけを除外対象にしており、インラインコードは InlineSpanParser が扱う。
        let result = runs("a `code` b")
        #expect(result.contains { $0.trait == .monospace })
    }

    @Test("フェンス内の見出し記法も conceal されない")
    func fencedHeadingIsUntouched() {
        // 見出しはトークナイザ由来なので元々フェンスを認識している。退行しないことを固定する。
        let result = runs("```\n# not a heading\n```")
        #expect(result.isEmpty)
    }
}
