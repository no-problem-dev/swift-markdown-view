#if os(iOS) || os(macOS)
import SwiftUI
import DesignSystem
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension MarkdownTextTheme {

    /// Builds a TextKit theme from the DesignSystem color palette so the
    /// selectable renderer matches the app's theme tokens.
    @MainActor
    static func resolved(palette: any ColorPalette, baseFontSize: CGFloat = 16) -> MarkdownTextTheme {
        func color(_ swiftUIColor: Color) -> PlatformColor { PlatformColor(swiftUIColor) }
        return MarkdownTextTheme(
            baseFont: .system(size: baseFontSize),
            codeFont: .monospaced(size: baseFontSize * 0.92),
            textColor: color(MarkdownColors.bodyText(palette)),
            secondaryColor: color(MarkdownColors.blockquoteText(palette)),
            headingColor: color(MarkdownColors.headingText(palette)),
            linkColor: color(MarkdownColors.link(palette)),
            inlineCodeForeground: color(MarkdownColors.inlineCodeText(palette)),
            inlineCodeBackground: color(MarkdownColors.inlineCodeBackground(palette)),
            codeBlockBackground: color(MarkdownColors.codeBlockBackground(palette)),
            quoteBarColor: color(MarkdownColors.blockquoteBorder(palette)),
            ruleColor: color(MarkdownColors.blockquoteBorder(palette))
        )
    }
}

/// Bridges the SwiftUI `SyntaxHighlighter` (which returns an `AttributedString`)
/// to the TextKit-facing ``MarkdownCodeHighlighting`` protocol.
struct SyntaxHighlighterAdapter: MarkdownCodeHighlighting {
    let base: any SyntaxHighlighter

    func highlightedCode(_ code: String, language: String?) async -> AttributedString? {
        try? await base.highlight(code, language: language)
    }
}
#endif
