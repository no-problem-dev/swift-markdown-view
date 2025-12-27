import SwiftUI

/// A SwiftUI view that renders Markdown content.
///
/// `MarkdownView` parses and displays Markdown text with full support for
/// CommonMark and GitHub Flavored Markdown syntax.
///
/// ```swift
/// // Basic usage with a string
/// MarkdownView("# Hello **World**")
///
/// // Using pre-parsed content for performance
/// let content = MarkdownContent(parsing: markdownString)
/// MarkdownView(content)
/// ```
///
/// The view automatically integrates with your app's theme through
/// the `swift-design-system` package, using appropriate typography,
/// colors, and spacing tokens.
public struct MarkdownView: View {

    /// The parsed Markdown content to render.
    public let content: MarkdownContent

    /// Creates a MarkdownView by parsing the given Markdown string.
    ///
    /// - Parameter source: The Markdown string to parse and render.
    public init(_ source: String) {
        self.content = MarkdownContent(parsing: source)
    }

    /// Creates a MarkdownView with pre-parsed Markdown content.
    ///
    /// Use this initializer when you want to parse the Markdown once
    /// and reuse it, or when you need to manipulate the content
    /// before rendering.
    ///
    /// - Parameter content: The pre-parsed Markdown content.
    public init(_ content: MarkdownContent) {
        self.content = content
    }

    public var body: some View {
        BlockRenderer.render(content.blocks)
    }
}

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
