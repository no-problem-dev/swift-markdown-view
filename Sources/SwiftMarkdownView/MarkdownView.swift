import SwiftUI

/// A SwiftUI view that renders Markdown.
///
/// The source is parsed with swift-markdown and drawn through TextKit 2. Headings, paragraphs,
/// lists (including task-list checkboxes), block quotes and asides, code blocks, thematic breaks,
/// and tables are rendered, along with the inline styles: emphasis, strong, code, links, images,
/// and strikethrough. Markup outside that set — raw HTML in particular — is dropped rather than
/// shown.
///
/// ```swift
/// // Build straight from a string
/// MarkdownView("# Hello **World**")
///
/// // Reuse pre-parsed content to avoid parsing the same source twice
/// let content = MarkdownContent(parsing: markdownString)
/// MarkdownView(content)
/// ```
///
/// Colors, metrics, and font sizes are resolved from ``MarkdownPalette``, ``MarkdownMetrics``, and
/// ``MarkdownTypeScale``. The defaults are system semantic colors, so the text stays readable in
/// both light and dark appearance without any configuration.
public struct MarkdownView: View {

    public let content: MarkdownContent

    /// Creates a view by parsing a Markdown string.
    ///
    /// - Parameter source: The Markdown to parse and render.
    public init(_ source: String) {
        self.content = MarkdownContent(parsing: source)
    }

    /// Creates a view from Markdown that has already been parsed.
    ///
    /// Use this to parse a source once and reuse the result, or to transform the content before
    /// it is rendered.
    ///
    /// - Parameter content: The parsed Markdown to render.
    public init(_ content: MarkdownContent) {
        self.content = content
    }

    public var body: some View {
        // Flow the whole document into a single TextKit 2 text view, so that selection runs
        // continuously across blocks and a copy yields readable text.
        MarkdownTextKitBackend(content: content)
    }
}

#if os(iOS) || os(macOS)
/// Renders the document with the continuous-selection TextKit backend.
///
/// The theme, the syntax highlighter, and the Mermaid script all come from the environment.
private struct MarkdownTextKitBackend: View {
    let content: MarkdownContent

    @Environment(\.markdownPalette) private var palette
    @Environment(\.markdownMetrics) private var metrics
    @Environment(\.markdownTypeScale) private var typeScale
    @Environment(\.syntaxHighlighter) private var highlighter
    @Environment(\.mathRenderer) private var mathRenderer
    @Environment(\.mermaidScriptProvider) private var mermaidScriptProvider
    @Environment(\.markdownRenderingOptions) private var renderingOptions
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        var view = MarkdownSelectableText(
            content,
            theme: .resolved(palette: palette, metrics: metrics, typeScale: typeScale)
        )
            .codeHighlighter(SyntaxHighlighterAdapter(base: highlighter))
            // `MathRenderer` refines `MarkdownAttachmentRendering`, so no runtime cast is needed.
            // With `renderMath` off the options refuse math, and the builder falls back to source.
            .attachmentRenderer(renderingOptions.attachmentRenderer(wrapping: mathRenderer))
            // Math is rasterized with the text color baked in, so the renderer has to be told
            // which appearance it is drawing for; a bitmap cannot follow a later change.
            .appearance(isDark: colorScheme == .dark)
        if let script = MermaidScript.resolve(from: mermaidScriptProvider.scriptSource) {
            view = view.mermaid(script: script, isDark: colorScheme == .dark)
        }
        return view
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
