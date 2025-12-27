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
/// ## Example
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         MarkdownCatalogView()
///             .theme(ThemeProvider())
///     }
/// }
/// ```
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
