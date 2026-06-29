import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// レンダリング済み属性文字列を構築するためのフォント・カラー・スペーシングの解決値。SwiftUI / DesignSystem に依存しないプレーン値のため、このレイヤーは自己完結しヘッドレステスト可能。`SwiftMarkdownView` が DesignSystem トークンをこのテーマにマップする。
public struct MarkdownTextTheme: @unchecked Sendable {

    // Fonts
    /// 本文テキストに使用するベースフォント。
    public var baseFont: PlatformFont
    /// コードブロックおよびインラインコードに使用する等幅フォント。
    public var codeFont: PlatformFont

    // Colors
    /// 本文テキストの前景色。
    public var textColor: PlatformColor
    /// 補助テキスト（キャプション等）の前景色。
    public var secondaryColor: PlatformColor
    /// 見出しテキストの前景色。
    public var headingColor: PlatformColor
    /// リンクテキストの前景色。
    public var linkColor: PlatformColor
    /// インラインコードの前景色。
    public var inlineCodeForeground: PlatformColor
    /// インラインコードの背景色。
    public var inlineCodeBackground: PlatformColor
    /// コードブロックの背景色。
    public var codeBlockBackground: PlatformColor
    /// ブロッククォートのリーディングバーの色。
    public var quoteBarColor: PlatformColor
    /// 水平線（`---`）の描画色。
    public var ruleColor: PlatformColor

    // Spacing
    /// 兄弟ブロック間の垂直ギャップ（ポイント単位）。
    public var paragraphSpacing: CGFloat
    /// 本文テキストに適用するライン高さ倍率。
    public var lineHeightMultiple: CGFloat
    /// リストおよびクォートのネストレベルごとのインデント幅（ポイント単位）。
    public var indentStep: CGFloat
    /// コードテキストと丸角背景ボックスの端との内側余白（ポイント単位）。
    public var codeBlockPadding: CGFloat
    /// コードテキストの上下に追加する垂直余白（ポイント単位）。
    public var codeBlockVerticalPadding: CGFloat
    /// コードブロック背景ボックスの角丸半径（ポイント単位）。
    public var codeBlockCornerRadius: CGFloat
    /// ブロッククォートの各レベルに描画するリーディングバーの幅（ポイント単位）。
    public var quoteBarWidth: CGFloat

    public init(
        baseFont: PlatformFont,
        codeFont: PlatformFont,
        textColor: PlatformColor,
        secondaryColor: PlatformColor,
        headingColor: PlatformColor,
        linkColor: PlatformColor,
        inlineCodeForeground: PlatformColor,
        inlineCodeBackground: PlatformColor,
        codeBlockBackground: PlatformColor,
        quoteBarColor: PlatformColor,
        ruleColor: PlatformColor,
        paragraphSpacing: CGFloat = 12,
        lineHeightMultiple: CGFloat = 1.2,
        indentStep: CGFloat = 22,
        codeBlockPadding: CGFloat = 12,
        codeBlockVerticalPadding: CGFloat = 8,
        codeBlockCornerRadius: CGFloat = 8,
        quoteBarWidth: CGFloat = 3,
        headingSizes: [CGFloat]? = nil,
        headingWeight: PlatformFont.Weight = .bold
    ) {
        self.baseFont = baseFont
        self.codeFont = codeFont
        self.textColor = textColor
        self.secondaryColor = secondaryColor
        self.headingColor = headingColor
        self.linkColor = linkColor
        self.inlineCodeForeground = inlineCodeForeground
        self.inlineCodeBackground = inlineCodeBackground
        self.codeBlockBackground = codeBlockBackground
        self.quoteBarColor = quoteBarColor
        self.ruleColor = ruleColor
        self.paragraphSpacing = paragraphSpacing
        self.lineHeightMultiple = lineHeightMultiple
        self.indentStep = indentStep
        self.codeBlockPadding = codeBlockPadding
        self.codeBlockVerticalPadding = codeBlockVerticalPadding
        self.codeBlockCornerRadius = codeBlockCornerRadius
        self.quoteBarWidth = quoteBarWidth
        self.headingSizes = headingSizes ?? Self.scaledHeadingSizes(base: baseFont.pointSize)
        self.headingWeight = headingWeight
    }

    /// 本文フォントのポイントサイズ。
    public var baseFontSize: CGFloat { baseFont.pointSize }

    /// オプションの太字/斜体トレイトを適用した本文フォント。
    public func bodyFont(bold: Bool = false, italic: Bool = false) -> PlatformFont {
        baseFont.withTraits(bold: bold, italic: italic)
    }

    /// ATX 見出しレベル 1–6 のポイントサイズ。
    public var headingSizes: [CGFloat]
    /// すべての見出しに適用するウェイト。
    public var headingWeight: PlatformFont.Weight

    /// 指定レベル（1–6）の ATX 見出しフォント。
    public func headingFont(level: Int) -> PlatformFont {
        let index = max(1, min(6, level)) - 1
        return PlatformFont.system(size: headingSizes[index], weight: headingWeight)
    }

    /// DesignSystem のサイズが指定されていない場合にベースサイズから比率で算出した見出しサイズ。
    public static func scaledHeadingSizes(base: CGFloat) -> [CGFloat] {
        [1.7, 1.45, 1.28, 1.15, 1.07, 1.0].map { base * $0 }
    }

    /// DesignSystem なしで使用できる、ライトモード向けのデフォルト設定。
    public static var `default`: MarkdownTextTheme {
        let base: CGFloat = 16
        return MarkdownTextTheme(
            baseFont: .system(size: base),
            codeFont: .monospaced(size: base * 0.92),
            textColor: .label,
            secondaryColor: .secondaryLabel,
            headingColor: .label,
            linkColor: .link,
            inlineCodeForeground: .label,
            inlineCodeBackground: .quaternaryLabel,
            codeBlockBackground: .quaternaryLabel,
            quoteBarColor: .tertiaryLabel,
            ruleColor: .separator
        )
    }
}

#if canImport(AppKit) && !canImport(UIKit)
// AppKit spells a few system colors differently; alias the ones used above.
private extension NSColor {
    static var label: NSColor { .labelColor }
    static var secondaryLabel: NSColor { .secondaryLabelColor }
    static var tertiaryLabel: NSColor { .tertiaryLabelColor }
    static var quaternaryLabel: NSColor { .quaternaryLabelColor }
    static var link: NSColor { .linkColor }
    static var separator: NSColor { .separatorColor }
}
#endif
