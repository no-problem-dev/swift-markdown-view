import SwiftUI
import DesignSystem

/// The main entry point for the Markdown catalog.
///
/// Displays a comprehensive catalog of all Markdown elements,
/// styles, and configuration options with live previews.
///
/// The view automatically adapts to the screen size:
/// - Regular horizontal size class: Three-column NavigationSplitView
/// - Compact horizontal size class: NavigationStack-based list
///
/// ## Basic Usage
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         MarkdownCatalogView()
///             .theme(ThemeProvider())
///     }
/// }
/// ```
///
/// ## With Syntax Highlighting
///
/// To enable syntax highlighting for all code examples in the catalog,
/// use the `SwiftMarkdownViewHighlightJS` module:
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// struct ContentView: View {
///     var body: some View {
///         MarkdownCatalogView()
///             .theme(ThemeProvider())
///             .adaptiveSyntaxHighlighting()
///     }
/// }
/// ```
///
/// This applies syntax highlighting to all code snippets throughout
/// the catalog with automatic light/dark mode support.
public struct MarkdownCatalogView: View {

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init() {}

    public var body: some View {
        if horizontalSizeClass == .regular {
            MarkdownCatalogSplitView()
        } else {
            MarkdownCatalogListView()
        }
    }
}

#Preview {
    MarkdownCatalogView()
        .theme(ThemeProvider())
}
