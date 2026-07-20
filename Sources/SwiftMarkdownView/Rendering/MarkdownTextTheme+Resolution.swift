#if os(iOS) || os(macOS)
import SwiftUI
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension MarkdownTextTheme {

    /// 環境から解決した色・寸法・文字サイズを TextKit テーマに束ねる。
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

/// SwiftUI の `SyntaxHighlighter`（`AttributedString` を返す）を
/// TextKit 向けの ``MarkdownCodeHighlighting`` プロトコルにブリッジする。
struct SyntaxHighlighterAdapter: MarkdownCodeHighlighting {
    let base: any SyntaxHighlighter

    func highlightedCode(_ code: String, language: String?) async -> AttributedString? {
        try? await base.highlight(code, language: language)
    }
}
#endif
