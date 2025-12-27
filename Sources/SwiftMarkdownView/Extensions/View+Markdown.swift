import SwiftUI
import DesignSystem

// MARK: - View Extensions for MarkdownView

public extension View {

    /// Applies a DesignSystem theme to the MarkdownView and its contents.
    ///
    /// This modifier ensures that all Markdown elements use the appropriate
    /// typography, colors, and spacing from the DesignSystem theme.
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownTheme(themeProvider)
    /// ```
    ///
    /// - Parameter provider: The ThemeProvider containing the theme configuration.
    /// - Returns: A view with the theme applied.
    func markdownTheme(_ provider: ThemeProvider) -> some View {
        self.theme(provider)
    }
}

// MARK: - MarkdownView Convenience Extensions

public extension MarkdownView {

    /// Creates a MarkdownView with a specific theme applied.
    ///
    /// This is a convenience initializer that combines content parsing
    /// with theme application.
    ///
    /// ```swift
    /// MarkdownView("# Hello", theme: themeProvider)
    /// ```
    ///
    /// - Parameters:
    ///   - source: The Markdown string to parse and render.
    ///   - theme: The ThemeProvider to apply.
    init(_ source: String, theme: ThemeProvider) {
        self.init(source)
    }
}
