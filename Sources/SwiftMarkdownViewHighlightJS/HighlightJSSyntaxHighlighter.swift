import SwiftUI
import SwiftMarkdownView
@preconcurrency import HighlightSwift

/// highlight.js を使用した、多言語対応の高精度シンタックスハイライター。
///
/// [HighlightSwift](https://github.com/appstefan/HighlightSwift) ライブラリを使用し、
/// 以下の機能を提供する:
/// - 50 以上の言語に対応
/// - 30 以上のビルトインテーマ（ライト/ダーク）
/// - 言語の自動検出
/// - `AttributedString` 出力による SwiftUI 統合
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// MarkdownView(source)
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
/// ```
///
/// カスタムテーマを使用する場合:
/// ```swift
/// MarkdownView(source)
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .light))
/// ```
public struct HighlightJSSyntaxHighlighter: SyntaxHighlighter, Sendable {

    /// 使用する highlight.js テーマ。
    public let theme: HighlightTheme

    /// ライトカラーまたはダークカラーのどちらを使用するか。
    public let colorMode: ColorMode

    /// ハイライトエンジンのインスタンス。
    private let highlight: Highlight

    /// シンタックスハイライトのカラーモード。
    public enum ColorMode: Sendable {
        case light
        case dark
    }

    /// highlight.js ベースのシンタックスハイライターを生成する。
    ///
    /// - Parameters:
    ///   - theme: 使用するカラーテーマ。デフォルトは `.xcode`。
    ///   - colorMode: ライトまたはダークカラーを使用するか。デフォルトは `.light`。
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
            // 指定言語を使用
            return try await highlight.attributedText(code, language: language, colors: colors)
        } else {
            // 言語を自動検出
            return try await highlight.attributedText(code, colors: colors)
        }
    }
}

// MARK: - Convenience Theme Presets

extension HighlightJSSyntaxHighlighter {

    /// Xcode ライトテーマ。
    /// - Warning: このテーマはプレーンテキストに明示的なカラーが設定されていないことがある。
    ///   視認性を高めるには `a11yLight` または `githubLight` の使用を検討する。
    public static let xcodeLight = HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .light)

    /// Xcode ダークテーマ。
    public static let xcodeDark = HighlightJSSyntaxHighlighter(theme: .xcode, colorMode: .dark)

    /// GitHub ライトテーマ。ライト背景に対するコントラストが良好。
    public static let githubLight = HighlightJSSyntaxHighlighter(theme: .github, colorMode: .light)

    /// GitHub ダークテーマ。
    public static let githubDark = HighlightJSSyntaxHighlighter(theme: .github, colorMode: .dark)

    /// Atom One ライトテーマ。
    public static let atomOneLight = HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .light)

    /// Atom One ダークテーマ。
    public static let atomOneDark = HighlightJSSyntaxHighlighter(theme: .atomOne, colorMode: .dark)

    /// Solarized ライトテーマ。
    public static let solarizedLight = HighlightJSSyntaxHighlighter(theme: .solarized, colorMode: .light)

    /// Solarized ダークテーマ。
    public static let solarizedDark = HighlightJSSyntaxHighlighter(theme: .solarized, colorMode: .dark)

    /// Tokyo Night ダークテーマ。
    public static let tokyoNightDark = HighlightJSSyntaxHighlighter(theme: .tokyoNight, colorMode: .dark)

    /// A11y（アクセシビリティ）ライトテーマ。高コントラストでライト背景に推奨。
    public static let a11yLight = HighlightJSSyntaxHighlighter(theme: .a11y, colorMode: .light)

    /// A11y（アクセシビリティ）ダークテーマ。ダーク背景向けの高コントラスト。
    public static let a11yDark = HighlightJSSyntaxHighlighter(theme: .a11y, colorMode: .dark)

    /// 指定した SwiftUI ColorScheme に合わせたハイライターを生成する。
    ///
    /// - Parameters:
    ///   - colorScheme: SwiftUI のカラースキーム（.light または .dark）。
    ///   - theme: 使用する highlight.js テーマ。コントラスト最適化のデフォルトは `.a11y`。
    /// - Returns: カラースキームに設定されたハイライター。
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

    /// カラースキームに自動対応するシンタックスハイライトを適用する。
    ///
    /// このモディファイアは環境から現在の `colorScheme` を読み取り、
    /// 適切な `HighlightJSSyntaxHighlighter` を設定する。
    ///
    /// ```swift
    /// import SwiftMarkdownViewHighlightJS
    ///
    /// MarkdownCatalogView()
    ///     .theme(ThemeProvider())
    ///     .adaptiveSyntaxHighlighting()
    /// ```
    ///
    /// カスタムテーマを使用する場合:
    /// ```swift
    /// MarkdownCatalogView()
    ///     .theme(ThemeProvider())
    ///     .adaptiveSyntaxHighlighting(theme: .github)
    /// ```
    ///
    /// - Parameter theme: 使用する highlight.js テーマ。コントラスト最適化のデフォルトは `.a11y`。
    /// - Returns: アダプティブシンタックスハイライトが適用されたビュー。
    func adaptiveSyntaxHighlighting(theme: HighlightTheme = .a11y) -> some View {
        modifier(AdaptiveSyntaxHighlightingModifier(theme: theme))
    }
}

// MARK: - Adaptive Syntax Highlighting Modifier

/// 現在のカラースキームに基づいてシンタックスハイライトを設定するビューモディファイア。
private struct AdaptiveSyntaxHighlightingModifier: ViewModifier {

    let theme: HighlightTheme

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let highlighter = HighlightJSSyntaxHighlighter.forColorScheme(colorScheme, theme: theme)
        return content.markdownSyntaxHighlighter(highlighter)
    }
}
