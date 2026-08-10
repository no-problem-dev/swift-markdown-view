#if os(iOS) || os(macOS)
import SwiftUI
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension MarkdownTextTheme {

    /// Gathers the colors, metrics, and font sizes from the environment into one TextKit theme.
    ///
    /// The palette is wider on the TextKit side than in ``MarkdownPalette``, so some values feed
    /// two slots: `codeBackground` backs both inline code and code blocks, and `rule` colors both
    /// the quote bar and thematic breaks.
    @MainActor
    static func resolved(
        palette: any MarkdownPalette,
        metrics: any MarkdownMetrics,
        typeScale: any MarkdownTypeScale
    ) -> MarkdownTextTheme {
        func color(_ swiftUIColor: Color) -> PlatformColor { PlatformColor(swiftUIColor) }

        let bodySize = typeScale.bodySize

        return MarkdownTextTheme(
            baseFont: .system(size: bodySize),
            codeFont: .monospaced(size: bodySize * 0.92),
            textColor: color(palette.text),
            secondaryColor: color(palette.secondaryText),
            headingColor: color(palette.heading),
            linkColor: color(palette.link),
            inlineCodeForeground: color(palette.secondaryText),
            inlineCodeBackground: color(palette.codeBackground),
            codeBlockBackground: color(palette.codeBackground),
            quoteBarColor: color(palette.rule),
            ruleColor: color(palette.rule),
            paragraphSpacing: metrics.paragraphSpacing,
            indentStep: metrics.indentStep,
            headingSizes: typeScale.headingSizes,
            headingWeight: .semibold
        )
    }
}

/// Bridges the SwiftUI-facing highlighter protocol to the one the TextKit layer expects.
///
/// SwiftUI's ``SyntaxHighlighter`` returns an `AttributedString`; the TextKit side consumes
/// ``MarkdownCodeHighlighting``.
struct SyntaxHighlighterAdapter: MarkdownCodeHighlighting {
    let base: any SyntaxHighlighter

    func highlightedCode(_ code: String, language: String?) async throws -> AttributedString? {
        // No `try?` here. `SyntaxHighlighter.highlight` documents that it throws, and dropping
        // the error would leave a client no way to observe a failure in their own highlighter.
        try await base.highlight(code, language: language)
    }
}
#endif
