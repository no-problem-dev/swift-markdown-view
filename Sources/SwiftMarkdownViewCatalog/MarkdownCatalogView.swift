import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// A browsable tour of every Markdown element, style, and configuration option, each with a live preview.
///
/// The layout follows the horizontal size class:
/// - Regular: a three-column `NavigationSplitView`.
/// - Compact: a list inside a `NavigationStack`.
///
/// ## Getting started
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
/// ## Turning on syntax highlighting
///
/// Code samples render as plain text unless a highlighter is in the environment. Import the
/// `SwiftMarkdownViewHighlightJS` module to color them:
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
/// The modifier reaches every code snippet in the catalog and picks a light or dark theme
/// from the current color scheme.
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
