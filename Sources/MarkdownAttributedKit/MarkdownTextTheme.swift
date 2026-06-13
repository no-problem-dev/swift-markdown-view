import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Resolved fonts, colors, and spacing for building the rendered attributed
/// string. Plain values (no SwiftUI / DesignSystem) so this layer is
/// self-contained and headlessly testable; `SwiftMarkdownView` maps its
/// DesignSystem tokens onto this theme.
public struct MarkdownTextTheme {

    // Fonts
    public var baseFont: PlatformFont
    public var codeFont: PlatformFont

    // Colors
    public var textColor: PlatformColor
    public var secondaryColor: PlatformColor
    public var headingColor: PlatformColor
    public var linkColor: PlatformColor
    public var inlineCodeForeground: PlatformColor
    public var inlineCodeBackground: PlatformColor
    public var codeBlockBackground: PlatformColor
    public var quoteBarColor: PlatformColor
    public var ruleColor: PlatformColor

    // Spacing
    /// Vertical gap between sibling blocks, in points.
    public var paragraphSpacing: CGFloat
    /// Line-height multiple applied to body text.
    public var lineHeightMultiple: CGFloat
    /// Indent per nesting level for lists and quotes, in points.
    public var indentStep: CGFloat
    /// Inset of code text from the edge of its rounded background box, in points.
    public var codeBlockPadding: CGFloat
    /// Corner radius of the code-block background box, in points.
    public var codeBlockCornerRadius: CGFloat
    /// Width of the leading bar drawn for each blockquote level, in points.
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
        self.codeBlockCornerRadius = codeBlockCornerRadius
        self.quoteBarWidth = quoteBarWidth
        self.headingSizes = headingSizes ?? Self.scaledHeadingSizes(base: baseFont.pointSize)
        self.headingWeight = headingWeight
    }

    /// Point size of the body font.
    public var baseFontSize: CGFloat { baseFont.pointSize }

    /// The body font with optional bold/italic traits.
    public func bodyFont(bold: Bool = false, italic: Bool = false) -> PlatformFont {
        baseFont.withTraits(bold: bold, italic: italic)
    }

    /// Point sizes for ATX heading levels 1–6.
    public var headingSizes: [CGFloat]
    /// Weight applied to all headings.
    public var headingWeight: PlatformFont.Weight

    /// The font for an ATX heading of the given level (1–6).
    public func headingFont(level: Int) -> PlatformFont {
        let index = max(1, min(6, level)) - 1
        return PlatformFont.system(size: headingSizes[index], weight: headingWeight)
    }

    /// Heading sizes scaled off a base size, used when explicit DesignSystem
    /// sizes aren't supplied.
    public static func scaledHeadingSizes(base: CGFloat) -> [CGFloat] {
        [1.7, 1.45, 1.28, 1.15, 1.07, 1.0].map { base * $0 }
    }

    /// A reasonable light-mode default, usable without DesignSystem.
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
