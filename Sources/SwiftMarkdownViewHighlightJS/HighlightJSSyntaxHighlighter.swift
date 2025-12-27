import SwiftUI
import SwiftMarkdownView
@preconcurrency import HighlightSwift

/// A syntax highlighter powered by highlight.js for accurate, multi-language support.
///
/// This highlighter uses the [HighlightSwift](https://github.com/appstefan/HighlightSwift)
/// library which provides:
/// - 50+ language support
/// - 30+ built-in themes (light/dark)
/// - Automatic language detection
/// - SwiftUI integration with `AttributedString` output
///
/// Example usage:
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// MarkdownView(source)
///     .syntaxHighlighter(HighlightJSSyntaxHighlighter())
/// ```
///
/// With a custom theme:
/// ```swift
/// MarkdownView(source)
///     .syntaxHighlighter(HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .light))
/// ```
public struct HighlightJSSyntaxHighlighter: SyntaxHighlighter, Sendable {

    /// The highlight.js theme to use.
    public let theme: HighlightTheme

    /// Whether to use light or dark colors.
    public let colorMode: ColorMode

    /// The highlight engine instance.
    private let highlight: Highlight

    /// Color mode for syntax highlighting.
    public enum ColorMode: Sendable {
        case light
        case dark
    }

    /// Creates a highlight.js-based syntax highlighter.
    ///
    /// - Parameters:
    ///   - theme: The color theme to use. Defaults to `.xcode`.
    ///   - colorMode: Whether to use light or dark colors. Defaults to `.light`.
    public init(theme: HighlightTheme = .xcode, colorMode: ColorMode = .light) {
        self.theme = theme
        self.colorMode = colorMode
        self.highlight = Highlight()
    }

    public func highlight(_ code: String, language: String?) async throws -> AttributedString {
        guard !code.isEmpty else { return AttributedString() }

        let colors: HighlightColors
        switch colorMode {
        case .light:
            colors = .light(theme)
        case .dark:
            colors = .dark(theme)
        }

        if let language = language, !language.isEmpty {
            // Use specified language
            return try await highlight.attributedText(code, language: language, colors: colors)
        } else {
            // Auto-detect language
            return try await highlight.attributedText(code, colors: colors)
        }
    }
}

// MARK: - Convenience Theme Presets

extension HighlightJSSyntaxHighlighter {

    /// Xcode light theme.
    /// - Warning: This theme has issues with plain text not having explicit colors.
    ///   Consider using `a11yLight` or `githubLight` for better visibility.
    public static let xcodeLight = HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .light)

    /// Xcode dark theme.
    public static let xcodeDark = HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .dark)

    /// GitHub light theme - good contrast for light backgrounds.
    public static let githubLight = HighlightJSSyntaxHighlighter(theme: .github, colorMode: .light)

    /// GitHub dark theme.
    public static let githubDark = HighlightJSSyntaxHighlighter(theme: .github, colorMode: .dark)

    /// Atom One light theme.
    public static let atomOneLight = HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .light)

    /// Atom One dark theme.
    public static let atomOneDark = HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .dark)

    /// Solarized light theme.
    public static let solarizedLight = HighlightJSSyntaxHighlighter(theme: .solarized, colorMode: .light)

    /// Solarized dark theme.
    public static let solarizedDark = HighlightJSSyntaxHighlighter(theme: .solarized, colorMode: .dark)

    /// Tokyo Night dark theme.
    public static let tokyoNightDark = HighlightJSSyntaxHighlighter(theme: .tokyoNight, colorMode: .dark)

    /// A11y (Accessibility) light theme - high contrast, recommended for light backgrounds.
    public static let a11yLight = HighlightJSSyntaxHighlighter(theme: .a11y, colorMode: .light)

    /// A11y (Accessibility) dark theme - high contrast for dark backgrounds.
    public static let a11yDark = HighlightJSSyntaxHighlighter(theme: .a11y, colorMode: .dark)
}
