import Testing
@testable import SwiftMarkdownEditorCore

/// 行境界の扱いに関する回帰テスト。
///
/// トークナイザは行単位で走るため、行の切り出しを誤ると「どこまでを着色するか」が
/// 静かにずれる。表示は一応成立してしまうので、テストが無いと気づけない類の不具合。
@Suite("MarkdownTokenizer の行境界")
struct MarkdownTokenizerLineBoundaryTests {

    // MARK: CRLF

    @Test("CRLF でも LF と同じ種別のトークン列になる")
    func crlfMatchesLF() {
        // 絶対オフセットは比較しない。CRLF はソース自体が 1 行あたり 1 コードユニット長く、
        // 後続行の位置がずれるのが正しい挙動のため。
        let lf = MarkdownTokenizer.tokenize("# T\n- a\n").map(\.kind)
        let crlf = MarkdownTokenizer.tokenize("# T\r\n- a\r\n").map(\.kind)
        #expect(lf == crlf)
    }

    @Test("CRLF でも各トークンの長さが LF と一致する")
    func crlfTokenLengthsMatchLF() {
        let lf = MarkdownTokenizer.tokenize("# T\n- a\n")
            .map { $0.range.upperBound - $0.range.lowerBound }
        let crlf = MarkdownTokenizer.tokenize("# T\r\n- a\r\n")
            .map { $0.range.upperBound - $0.range.lowerBound }
        #expect(lf == crlf)
    }

    @Test("CRLF の見出し本文に \\r が含まれない")
    func crlfHeadingExcludesCarriageReturn() {
        let tokens = MarkdownTokenizer.tokenize("# T\r\n")
        let heading = tokens.first { $0.kind == .heading }
        // "# T" の本文は index 2..3。\r を飲むと 2..4 になる。
        #expect(heading?.range == TextSpan(lowerBound: 2, upperBound: 3))
    }

    @Test("CRLF のコードブロック行に \\r が含まれない")
    func crlfCodeBlockExcludesCarriageReturn() {
        let tokens = MarkdownTokenizer.tokenize("```\r\nx\r\n```\r\n")
        let codeBlock = tokens.first { $0.kind == .codeBlock }
        // 2 行目 "x" は index 5..6。
        #expect(codeBlock?.range == TextSpan(lowerBound: 5, upperBound: 6))
    }

    // MARK: インデントされた閉じフェンス

    @Test("インデントされた閉じフェンスを認識する")
    func indentedClosingFenceCloses() {
        let tokens = MarkdownTokenizer.tokenize("```swift\nlet x = 1\n  ```\n# Heading\n")
        // 閉じフェンスを認識できないと、以降の見出しまで codeBlock になる。
        let hasHeading = tokens.contains { $0.kind == .headingMarker }
        #expect(hasHeading)
    }

    @Test("閉じフェンスの後の行はコードとして着色されない")
    func contentAfterIndentedFenceIsNotCode() {
        let source = "```\ncode\n  ```\nplain\n"
        let tokens = MarkdownTokenizer.tokenize(source)
        // "plain" は index 15..20。ここに codeBlock トークンが乗っていないこと。
        let codeAfterFence = tokens.contains { token in
            token.kind == .codeBlock && token.range.lowerBound >= 15
        }
        #expect(codeAfterFence == false)
    }

    @Test("フェンス内の未閉じ状態は従来どおり継続する")
    func unterminatedFenceStillRunsToEnd() {
        let tokens = MarkdownTokenizer.tokenize("```\ncode\nmore\n")
        let codeBlocks = tokens.filter { $0.kind == .codeBlock }
        #expect(codeBlocks.count == 2)
    }
}
