#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import Testing
import AppKit
@testable import MarkdownTextKit
@testable import MarkdownAttributedKit

/// テキストビュー基盤の不変条件。
///
/// ここで守るのは「ドキュメント全体が 1 つのストレージに載っていること」と
/// 「TextKit 2 が有効であること」。どちらも壊れても表示は一応成立してしまうため、
/// テストが無いと気づけない。TextKit 1 へのダウングレードは
/// カスタムフラグメント描画（コードブロック背景など）を無効化する。
@Suite("MarkdownTextView の基盤")
@MainActor
struct MarkdownTextViewTests {

    private func attributed(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string)
    }

    @Test("TextKit 2 が有効になっている")
    func usesTextKit2() {
        let textView = MarkdownTextViewFactory.make()
        // textLayoutManager が nil なら TextKit 1 に落ちている。
        #expect(textView.textLayoutManager != nil)
        #expect(textView.textContentStorage != nil)
    }

    @Test("読み取り専用かつ選択可能")
    func isReadOnlyAndSelectable() {
        let textView = MarkdownTextViewFactory.make()
        #expect(textView.isEditable == false)
        #expect(textView.isSelectable)
    }

    @Test("ドキュメント全体が 1 つのストレージに載る")
    func documentLivesInASingleStorage() {
        let textView = MarkdownTextViewFactory.make()
        let source = "Heading\nParagraph one\nParagraph two"
        MarkdownTextViewFactory.apply(attributed(source), to: textView)

        let storage = textView.textContentStorage?.textStorage
        #expect(storage?.length == source.utf16.count)
        // ブロックを跨いで連続した 1 本のテキストであること。
        #expect(storage?.string == source)
    }

    @Test("適用したテキストで置き換わる（追記されない）")
    func applyReplacesRatherThanAppends() {
        let textView = MarkdownTextViewFactory.make()
        MarkdownTextViewFactory.apply(attributed("first"), to: textView)
        MarkdownTextViewFactory.apply(attributed("second"), to: textView)
        #expect(textView.textContentStorage?.textStorage?.string == "second")
    }

    @Test("コンテンツが増えると高さが増える")
    func contentHeightGrowsWithContent() {
        let textView = MarkdownTextViewFactory.make()

        MarkdownTextViewFactory.apply(attributed("one line"), to: textView)
        let short = MarkdownTextViewFactory.contentHeight(of: textView, fittingWidth: 200)

        MarkdownTextViewFactory.apply(
            attributed(Array(repeating: "another line", count: 20).joined(separator: "\n")),
            to: textView
        )
        let tall = MarkdownTextViewFactory.contentHeight(of: textView, fittingWidth: 200)

        #expect(short > 0)
        #expect(tall > short)
    }

    @Test("フラグメントプロバイダーがレイアウトマネージャーのデリゲートになる")
    func fragmentProviderBecomesDelegate() {
        let textView = MarkdownTextViewFactory.make()
        let provider = MarkdownLayoutFragmentProvider()
        MarkdownTextViewFactory.setFragmentProvider(provider, on: textView)
        #expect(textView.textLayoutManager?.delegate === provider)
    }
}
#endif
