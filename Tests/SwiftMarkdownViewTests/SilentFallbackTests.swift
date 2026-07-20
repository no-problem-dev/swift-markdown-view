#if os(iOS) || os(macOS)
import Testing
import SwiftUI
import Foundation
@testable import SwiftMarkdownView
@testable import MarkdownAttributedKit

/// 「約束したことを黙って別のことに差し替える」失敗の回帰テスト。
///
/// この種のバグは症状が出ない — 例外も出ず、ログも出ず、ただ違う挙動になる。
/// 一度直しても、気づかないまま元に戻せてしまうので固定しておく。
@Suite("silent fallback の禁止")
struct SilentFallbackTests {

    // MARK: Mermaid スクリプトのソース

    @Test("inline を宣言したら外部 URL に落ちない")
    func inlineSourceNeverFallsBackToNetwork() {
        let javaScript = "window.mermaid = {};"
        let resolved = MermaidScript.resolve(from: .inline(javaScript))

        #expect(resolved == .inline(javaScript))
    }

    @Test("url を宣言したらその URL がそのまま使われる")
    func urlSourceIsPreserved() throws {
        let url = try #require(URL(string: "https://example.com/mermaid.js"))

        #expect(MermaidScript.resolve(from: .url(url)) == .remote(url))
    }

    @Test("localFile は中身を読み込んで埋め込む")
    func localFileIsInlined() throws {
        let javaScript = "/* bundled mermaid */"
        let url = URL.temporaryDirectory.appending(path: "mermaid-\(UUID().uuidString).js")
        try javaScript.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(MermaidScript.resolve(from: .localFile(url)) == .inline(javaScript))
    }

    @Test("読めない localFile は描画しない。CDN には落ちない")
    func unreadableLocalFileYieldsNothing() throws {
        let missing = URL.temporaryDirectory.appending(path: "absent-\(UUID().uuidString).js")

        #expect(MermaidScript.resolve(from: .localFile(missing)) == nil)
    }

    @Test("インライン JS 中の </script> が HTML を割らない")
    func inlineScriptCannotBreakOutOfTag() {
        let html = MermaidHTML.make(
            source: "graph TD; A-->B;",
            script: .inline("const s = \"</script><img src=x>\";"),
            isDark: false
        )

        #expect(!html.contains("</script><img src=x>"))
        #expect(html.contains("<\\/script>"))
    }

    // MARK: 数式レンダラーの接続

    /// 以前は `MathRenderer` と `MarkdownAttachmentRendering` が無関係な 2 プロトコルで、
    /// `as?` で繋がれていた。適合していない自作レンダラーは無言で無視され、
    /// 数式が `$latex$` のまま表示された。継承にしたので取り違えようがない。
    @Test("MathRenderer は必ずアタッチメントレンダラーとしても通る")
    func mathRendererIsAlwaysAnAttachmentRenderer() {
        let renderer: any MathRenderer = PlainMathRenderer()

        #expect(renderer is any MarkdownAttachmentRendering)
    }

    // MARK: シンタックスハイライトの失敗

    private struct FailingHighlighter: SyntaxHighlighter {
        struct Boom: Error {}
        func highlight(_ code: String, language: String?) async throws -> AttributedString {
            throw Boom()
        }
    }

    /// アダプタが `try?` で握り潰していたため、利用者は自作ハイライターの失敗を
    /// 「なぜか色が付かない」としてしか観測できなかった。今は素通しする。
    @Test("ハイライターの失敗はアダプタで握り潰さない")
    func highlighterErrorPropagatesThroughAdapter() async {
        let adapter = SyntaxHighlighterAdapter(base: FailingHighlighter())

        await #expect(throws: FailingHighlighter.Boom.self) {
            _ = try await adapter.highlightedCode("let x = 1", language: "swift")
        }
    }
}
#endif
