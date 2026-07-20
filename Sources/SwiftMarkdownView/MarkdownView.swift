import SwiftUI
import DesignSystem

/// Markdown テキストをレンダリングする SwiftUI View。
///
/// CommonMark および GitHub Flavored Markdown 構文を完全サポートし、
/// Markdown テキストをパースして描画する。
///
/// ```swift
/// // 文字列から直接作成
/// MarkdownView("# Hello **World**")
///
/// // パフォーマンスのために事前パース済みコンテンツを使用
/// let content = MarkdownContent(parsing: markdownString)
/// MarkdownView(content)
/// ```
///
/// `swift-design-system` パッケージが提供するテーマと自動統合し、
/// 適切なタイポグラフィ・色・スペーシングトークンを適用する。
public struct MarkdownView: View {

    /// レンダリング対象のパース済み Markdown コンテンツ。
    public let content: MarkdownContent

    /// Markdown 文字列をパースして MarkdownView を作成する。
    ///
    /// - Parameter source: パースしてレンダリングする Markdown 文字列。
    public init(_ source: String) {
        self.content = MarkdownContent(parsing: source)
    }

    /// パース済みの Markdown コンテンツで MarkdownView を作成する。
    ///
    /// Markdown を一度だけパースして再利用したい場合や、
    /// レンダリング前にコンテンツを加工したい場合に使用する。
    ///
    /// - Parameter content: パース済みの Markdown コンテンツ。
    public init(_ content: MarkdownContent) {
        self.content = content
    }

    public var body: some View {
        // ドキュメント全体を 1 つの TextKit 2 テキストビューに流し込む。
        // ブロックを跨いで選択が連続し、コピーで読めるテキストが得られる。
        MarkdownTextKitBackend(content: content)
    }
}

#if os(iOS) || os(macOS)
/// 環境からテーマとシンタックスハイライターを読み取り、
/// 連続選択 TextKit バックエンドでドキュメントをレンダリングする。
private struct MarkdownTextKitBackend: View {
    let content: MarkdownContent

    @Environment(\.colorPalette) private var palette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.syntaxHighlighter) private var highlighter
    @Environment(\.mathRenderer) private var mathRenderer
    @Environment(\.mermaidScriptProvider) private var mermaidScriptProvider
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        var view = MarkdownSelectableText(content, theme: .resolved(palette: palette, spacing: spacing))
            .codeHighlighter(SyntaxHighlighterAdapter(base: highlighter))
            .attachmentRenderer(mathRenderer as? MarkdownAttachmentRendering)
        if let url = Self.mermaidScriptURL(mermaidScriptProvider) {
            view = view.mermaid(scriptURL: url, isDark: colorScheme == .dark)
        }
        return view
    }

    private static func mermaidScriptURL(_ provider: any MermaidScriptProvider) -> URL? {
        if case .url(let url) = provider.scriptSource { return url }
        if case .localFile(let url) = provider.scriptSource { return url }
        if case .url(let url) = CDNMermaidScriptProvider().scriptSource { return url }
        return nil
    }
}
#endif

#Preview {
    MarkdownView("""
    # Hello World

    This is a **bold** statement with *italic* text.

    - Item 1
    - Item 2

    ```swift
    let x = 1
    ```
    """)
    .padding()
}
