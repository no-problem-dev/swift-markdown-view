import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The fonts, colors, and spacing resolved for building the rendered attributed string.
///
/// These are plain values with no dependency on SwiftUI or the design system, which keeps this layer
/// self-contained and testable headlessly. `SwiftMarkdownView` maps design system tokens onto a theme.
public struct MarkdownTextTheme: @unchecked Sendable, Equatable {

    // Fonts
    /// The font for body text, and the size the default heading sizes are scaled from.
    public var baseFont: PlatformFont
    /// The monospaced font, used for code blocks and inline code alike.
    public var codeFont: PlatformFont

    // Colors
    /// The foreground color for body text.
    ///
    /// Quoting works by matching this exact color, so a run only dims to ``secondaryColor`` inside a
    /// block quote if it was painted with it.
    public var textColor: PlatformColor
    /// The foreground color for de-emphasized text: list markers, and body text inside a block quote.
    public var secondaryColor: PlatformColor
    public var headingColor: PlatformColor
    public var linkColor: PlatformColor
    /// The foreground color for inline code, also used for code block text and for math fallback text.
    public var inlineCodeForeground: PlatformColor
    public var inlineCodeBackground: PlatformColor
    public var codeBlockBackground: PlatformColor
    /// The default color of the leading bar beside a block quote; an aside's kind overrides it.
    public var quoteBarColor: PlatformColor
    /// The color of thematic breaks and of the separators between table rows.
    public var ruleColor: PlatformColor

    // Spacing
    /// The vertical gap between sibling blocks, in points.
    public var paragraphSpacing: CGFloat
    /// The line height multiple for body text; code blocks always use 1.0 instead.
    public var lineHeightMultiple: CGFloat
    /// The indent added per nesting level of a list or quote, in points.
    public var indentStep: CGFloat
    /// The inset between code text and the edges of its rounded background box, in points.
    public var codeBlockPadding: CGFloat
    /// The extra vertical room above and below code text, in points.
    public var codeBlockVerticalPadding: CGFloat
    /// The corner radius of a code block's background box, in points.
    public var codeBlockCornerRadius: CGFloat
    /// The width of the leading bar drawn for each block quote level, in points.
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

    public var baseFontSize: CGFloat { baseFont.pointSize }

    /// The body font with optional bold and italic traits applied.
    public func bodyFont(bold: Bool = false, italic: Bool = false) -> PlatformFont {
        baseFont.withTraits(bold: bold, italic: italic)
    }

    /// Point sizes for ATX heading levels 1 through 6.
    public var headingSizes: [CGFloat]
    /// The weight applied to every heading level.
    public var headingWeight: PlatformFont.Weight

    /// The ATX heading font for the given level, clamped to the range 1 through 6.
    public func headingFont(level: Int) -> PlatformFont {
        let index = max(1, min(6, level)) - 1
        return PlatformFont.system(size: headingSizes[index], weight: headingWeight)
    }

    /// Heading sizes derived from the base size by ratio, used when the design system supplies none.
    public static func scaledHeadingSizes(base: CGFloat) -> [CGFloat] {
        [1.7, 1.45, 1.28, 1.15, 1.07, 1.0].map { base * $0 }
    }

    /// A default theme built from dynamic system colors, for use without a design system.
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
