import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// `MarkdownView` のイニシャライザ契約。
///
/// パース結果そのものは `MarkdownModelTests` が検証する。ここで守るのは
/// 「文字列版とコンテンツ版が同じものを表す」ことと「渡したコンテンツが
/// 再パースされず素通しされる」こと。
struct MarkdownViewTests {

    @Test("文字列版はコンテンツ版と同じ内容になる")
    func stringInitMatchesContentInit() {
        let source = """
        # Title

        This is a paragraph.

        - Item 1
        - Item 2
        """
        #expect(MarkdownView(source).content == MarkdownContent(parsing: source))
    }

    @Test("渡したコンテンツをそのまま保持する")
    func contentInitPreservesContent() {
        // パース済みコンテンツを再利用する用途があるため、再パースされると
        // 同じ結果でも無駄が生じる。ここでは内容が一致することだけを保証する。
        let content = MarkdownContent(parsing: "# Title\n\nBody")
        #expect(MarkdownView(content).content == content)
    }

    @Test("空文字列でもクラッシュしない")
    func emptySourceIsSafe() {
        #expect(MarkdownView("").content.blocks.isEmpty)
    }
}
