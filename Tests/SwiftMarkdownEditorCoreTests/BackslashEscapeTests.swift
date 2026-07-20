import Testing
@testable import SwiftMarkdownEditorCore

/// バックスラッシュエスケープが、エディタ側の 2 つの解析器でも尊重されることの検証。
///
/// プレビュー側（swift-markdown）は `\*` をリテラルとして描く。エディタ側が強調として
/// 扱うと、分割表示で同じ行が左では斜体・右では `*not em*` になる。
/// 数式スキャナは既にエスケープを扱っており、同一パッケージ内で規則が割れていた。
@Suite("バックスラッシュエスケープ")
struct BackslashEscapeTests {

    // MARK: InlineSpanParser

    @Test("エスケープされた * は強調スパンにならない")
    func escapedStarIsNotEmphasis() {
        let spans = InlineSpanParser.parse(#"a \*not em\* b"#)
        #expect(spans.isEmpty)
    }

    @Test("エスケープされた _ は強調スパンにならない")
    func escapedUnderscoreIsNotEmphasis() {
        let spans = InlineSpanParser.parse(#"a \_not em\_ b"#)
        #expect(spans.isEmpty)
    }

    @Test("エスケープされたバッククォートはコードスパンを開かない")
    func escapedBacktickIsNotCode() {
        let spans = InlineSpanParser.parse(#"a \`not code\` b"#)
        #expect(spans.isEmpty)
    }

    @Test("エスケープされていない強調は従来どおり")
    func unescapedEmphasisStillWorks() {
        let spans = InlineSpanParser.parse("a *em* b")
        #expect(spans.count == 1)
        #expect(spans.first?.kind == .emphasis)
    }

    @Test("コードスパンの中のバックスラッシュはエスケープしない")
    func backslashInsideCodeSpanIsLiteral() {
        // CommonMark 6.1: コードスパン内でバックスラッシュエスケープは働かない。
        let spans = InlineSpanParser.parse(#"a `\*` b"#)
        #expect(spans.count == 1)
        #expect(spans.first?.kind == .code)
    }

    // MARK: MarkdownTokenizer

    @Test("トークナイザもエスケープされた * を強調マーカーにしない")
    func tokenizerSkipsEscapedStar() {
        let kinds = MarkdownTokenizer.tokenize(#"a \*not em\* b"#).map(\.kind)
        #expect(!kinds.contains(.emphasis))
        #expect(!kinds.contains(.strong))
    }

    @Test("トークナイザもエスケープされたバッククォートを無視する")
    func tokenizerSkipsEscapedBacktick() {
        let kinds = MarkdownTokenizer.tokenize(#"a \`not code\` b"#).map(\.kind)
        #expect(!kinds.contains(.inlineCode))
    }

    @Test("トークナイザのエスケープされていない強調は従来どおり")
    func tokenizerUnescapedStillWorks() {
        let kinds = MarkdownTokenizer.tokenize("a *em* b").map(\.kind)
        #expect(kinds.filter { $0 == .emphasis }.count == 2)
    }

    @Test("エスケープされた [ はリンクを開かない")
    func escapedBracketIsNotLink() {
        let kinds = MarkdownTokenizer.tokenize(#"a \[not a link](url) b"#).map(\.kind)
        #expect(!kinds.contains(.linkText))
    }
}
