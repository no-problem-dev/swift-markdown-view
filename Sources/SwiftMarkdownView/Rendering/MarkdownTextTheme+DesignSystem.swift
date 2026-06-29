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

    /// DesignSystem トークン（パレットからカラー、`Typography` からフォント/サイズ、
    /// `SpacingScale` からスペーシング）を基に TextKit テーマを構築する。
    /// 選択可能レンダラーがアプリのデザインシステムに一致するようにする。
    @MainActor
    static func resolved(palette: any ColorPalette, spacing: any SpacingScale) -> MarkdownTextTheme {
        func color(_ swiftUIColor: Color) -> PlatformColor { PlatformColor(swiftUIColor) }

        let bodySize = Typography.bodyLarge.size
        let headingSizes = [
            Typography.headlineLarge.size,
            Typography.headlineMedium.size,
            Typography.headlineSmall.size,
            Typography.titleLarge.size,
            Typography.titleMedium.size,
            Typography.titleSmall.size,
        ]

        return MarkdownTextTheme(
            baseFont: .system(size: bodySize),
            codeFont: .monospaced(size: bodySize * 0.92),
            textColor: color(MarkdownColors.bodyText(palette)),
            secondaryColor: color(MarkdownColors.blockquoteText(palette)),
            headingColor: color(MarkdownColors.headingText(palette)),
            linkColor: color(MarkdownColors.link(palette)),
            inlineCodeForeground: color(MarkdownColors.inlineCodeText(palette)),
            inlineCodeBackground: color(MarkdownColors.inlineCodeBackground(palette)),
            codeBlockBackground: color(MarkdownColors.codeBlockBackground(palette)),
            quoteBarColor: color(MarkdownColors.blockquoteBorder(palette)),
            ruleColor: color(MarkdownColors.blockquoteBorder(palette)),
            paragraphSpacing: spacing.md,
            indentStep: spacing.xl,
            headingSizes: headingSizes,
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
