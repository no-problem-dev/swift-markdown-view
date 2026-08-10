import SwiftUI
import SwiftMarkdownView
@preconcurrency import HighlightSwift

/// A syntax highlighter backed by highlight.js, covering many languages accurately.
///
/// Built on the [HighlightSwift](https://github.com/appstefan/HighlightSwift) library, it brings:
/// - more than 50 languages
/// - more than 30 built-in light and dark themes
/// - automatic language detection
/// - `AttributedString` output that drops straight into SwiftUI
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// MarkdownView(source)
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
/// ```
///
/// To choose a theme:
/// ```swift
/// MarkdownView(source)
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .light))
/// ```
public struct HighlightJSSyntaxHighlighter: SyntaxHighlighter, Sendable {

    public let theme: HighlightTheme

    public let colorMode: ColorMode

    private let highlight: Highlight

    public enum ColorMode: Sendable {
        case light
        case dark
    }

    /// Creates a highlighter backed by highlight.js.
    ///
    /// - Parameters:
    ///   - theme: The color theme. Defaults to `.xcode`.
    ///   - colorMode: Whether to use the theme's light or dark colors. Defaults to `.light`.
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
            // Use the language the caller named.
            return try await highlight.attributedText(code, language: language, colors: colors)
        } else {
            // Let highlight.js detect the language.
            return try await highlight.attributedText(code, colors: colors)
        }
    }
}

// MARK: - Convenience Theme Presets

extension HighlightJSSyntaxHighlighter {

    /// Matches Xcode's own light appearance.
    ///
    /// - Warning: This theme can leave plain text without an explicit color. For legibility,
    ///   consider ``a11yLight`` or ``githubLight`` instead.
    public static let xcodeLight = HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .light)

    public static let xcodeDark = HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .dark)

    /// A light preset with dependable contrast on light backgrounds.
    public static let githubLight = HighlightJSSyntaxHighlighter(theme: .github, colorMode: .light)

    public static let githubDark = HighlightJSSyntaxHighlighter(theme: .github, colorMode: .dark)

    public static let atomOneLight = HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .light)

    public static let atomOneDark = HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .dark)

    public static let solarizedLight = HighlightJSSyntaxHighlighter(theme: .solarized, colorMode: .light)

    public static let solarizedDark = HighlightJSSyntaxHighlighter(theme: .solarized, colorMode: .dark)

    public static let tokyoNightDark = HighlightJSSyntaxHighlighter(theme: .tokyoNight, colorMode: .dark)

    /// The high-contrast, accessibility-oriented preset for light backgrounds.
    public static let a11yLight = HighlightJSSyntaxHighlighter(theme: .a11y, colorMode: .light)

    /// The high-contrast, accessibility-oriented preset for dark backgrounds.
    public static let a11yDark = HighlightJSSyntaxHighlighter(theme: .a11y, colorMode: .dark)

    /// Creates a highlighter matching the given color scheme.
    ///
    /// - Parameters:
    ///   - colorScheme: The color scheme to follow.
    ///   - theme: The highlight.js theme. Defaults to `.a11y`, which is tuned for contrast.
    public static func forColorScheme(
        _ colorScheme: ColorScheme,
        theme: HighlightTheme = .a11y
    ) -> HighlightJSSyntaxHighlighter {
        let colorMode: ColorMode = colorScheme == .dark ? .dark : .light
        return HighlightJSSyntaxHighlighter(theme: theme, colorMode: colorMode)
    }
}

// MARK: - View Extension for Adaptive Syntax Highlighting

public extension View {

    /// Highlights code with a theme that follows the light and dark appearance.
    ///
    /// The modifier reads the current color scheme from the environment and installs a matching
    /// highlighter.
    ///
    /// ```swift
    /// import SwiftMarkdownViewHighlightJS
    ///
    /// MarkdownCatalogView()
    ///     .theme(ThemeProvider())
    ///     .adaptiveSyntaxHighlighting()
    /// ```
    ///
    /// To choose a theme:
    /// ```swift
    /// MarkdownCatalogView()
    ///     .theme(ThemeProvider())
    ///     .adaptiveSyntaxHighlighting(theme: .github)
    /// ```
    ///
    /// - Parameter theme: The highlight.js theme. Defaults to `.a11y`, which is tuned for contrast.
    func adaptiveSyntaxHighlighting(theme: HighlightTheme = .a11y) -> some View {
        modifier(AdaptiveSyntaxHighlightingModifier(theme: theme))
    }
}

// MARK: - Adaptive Syntax Highlighting Modifier

/// Installs a highlighter chosen from the current color scheme.
private struct AdaptiveSyntaxHighlightingModifier: ViewModifier {

    let theme: HighlightTheme

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let highlighter = HighlightJSSyntaxHighlighter.forColorScheme(colorScheme, theme: theme)
        return content.markdownSyntaxHighlighter(highlighter)
    }
}
