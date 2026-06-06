import SwiftUI
import DesignSystem

/// Renders inline Markdown elements as SwiftUI Text.
///
/// This renderer converts `MarkdownInline` elements into concatenated `Text` views,
/// preserving formatting such as emphasis, strong, and inline code.
/// Links are rendered as tappable elements using AttributedString.
enum InlineRenderer {

    /// Renders an array of inline elements as a single concatenated Text.
    ///
    /// - Parameters:
    ///   - inlines: The inline elements to render.
    ///   - colorPalette: The color palette for theming inline elements.
    ///   - bodyFont: The base font to apply to all text runs. When provided, every run
    ///     in the AttributedString receives an explicit font attribute, preventing
    ///     SwiftUI's View-level `.font()` from overriding the first run.
    /// - Returns: A `Text` view with all formatting applied.
    static func render(
        _ inlines: [MarkdownInline],
        colorPalette: any ColorPalette,
        bodyFont: Font? = nil
    ) -> Text {
        let attributed = buildAttributedString(
            inlines,
            style: .default,
            colorPalette: colorPalette,
            bodyFont: bodyFont
        )
        return Text(attributed)
    }

    /// Renders inline elements, delegating inline math to a math renderer.
    ///
    /// AttributedString cannot host arbitrary views, so the paragraph is
    /// built as concatenated `Text` segments: attributed runs are flushed
    /// whenever an inline math element produces its own `Text`.
    @MainActor
    static func render(
        _ inlines: [MarkdownInline],
        colorPalette: any ColorPalette,
        bodyFont: Font?,
        mathRenderer: (any MathRenderer)?
    ) -> Text {
        guard let mathRenderer, containsInlineMath(inlines) else {
            return render(inlines, colorPalette: colorPalette, bodyFont: bodyFont)
        }

        var output = Text(verbatim: "")
        var pending = AttributedString()
        appendSegments(
            inlines,
            style: .default,
            colorPalette: colorPalette,
            bodyFont: bodyFont,
            mathRenderer: mathRenderer,
            pending: &pending,
            output: &output
        )
        if !pending.characters.isEmpty {
            output = output + Text(pending)
        }
        return output
    }

    @MainActor
    private static func appendSegments(
        _ inlines: [MarkdownInline],
        style: InlineStyle,
        colorPalette: any ColorPalette,
        bodyFont: Font?,
        mathRenderer: any MathRenderer,
        pending: inout AttributedString,
        output: inout Text
    ) {
        for inline in inlines {
            switch inline {
            case .inlineMath(let latex):
                if !pending.characters.isEmpty {
                    output = output + Text(pending)
                    pending = AttributedString()
                }
                output = output + mathRenderer.inlineMath(latex, palette: colorPalette)

            case .emphasis(let children):
                appendSegments(children, style: style.withEmphasis(), colorPalette: colorPalette, bodyFont: bodyFont, mathRenderer: mathRenderer, pending: &pending, output: &output)

            case .strong(let children):
                appendSegments(children, style: style.withStrong(), colorPalette: colorPalette, bodyFont: bodyFont, mathRenderer: mathRenderer, pending: &pending, output: &output)

            case .strikethrough(let children):
                appendSegments(children, style: style.withStrikethrough(), colorPalette: colorPalette, bodyFont: bodyFont, mathRenderer: mathRenderer, pending: &pending, output: &output)

            case .link(_, _, let content) where containsInlineMath(content):
                // A link whose content holds math: descend so the math is
                // typeset; the math segment itself loses tappability.
                appendSegments(content, style: style.withLink(), colorPalette: colorPalette, bodyFont: bodyFont, mathRenderer: mathRenderer, pending: &pending, output: &output)

            default:
                pending.append(buildSingle(inline, style: style, colorPalette: colorPalette, bodyFont: bodyFont))
            }
        }
    }

    private static func containsInlineMath(_ inlines: [MarkdownInline]) -> Bool {
        inlines.contains { inline in
            switch inline {
            case .inlineMath:
                return true
            case .emphasis(let children), .strong(let children), .strikethrough(let children),
                 .link(_, _, let children):
                return containsInlineMath(children)
            default:
                return false
            }
        }
    }

    /// Renders inline elements with specific style context.
    ///
    /// - Parameters:
    ///   - inlines: The inline elements to render.
    ///   - style: The inherited style context.
    ///   - colorPalette: The color palette for theming.
    ///   - bodyFont: The base font for plain text runs.
    /// - Returns: An AttributedString with all formatting applied.
    private static func buildAttributedString(
        _ inlines: [MarkdownInline],
        style: InlineStyle,
        colorPalette: any ColorPalette,
        bodyFont: Font?
    ) -> AttributedString {
        var result = AttributedString()
        for inline in inlines {
            result.append(buildSingle(inline, style: style, colorPalette: colorPalette, bodyFont: bodyFont))
        }
        return result
    }

    /// Builds an AttributedString for a single inline element.
    private static func buildSingle(
        _ inline: MarkdownInline,
        style: InlineStyle,
        colorPalette: any ColorPalette,
        bodyFont: Font?
    ) -> AttributedString {
        switch inline {
        case .text(let string):
            var attributed = AttributedString(string)
            applyStyle(&attributed, style: style, bodyFont: bodyFont)
            return attributed

        case .emphasis(let children):
            return buildAttributedString(children, style: style.withEmphasis(), colorPalette: colorPalette, bodyFont: bodyFont)

        case .strong(let children):
            return buildAttributedString(children, style: style.withStrong(), colorPalette: colorPalette, bodyFont: bodyFont)

        case .code(let code):
            var attributed = AttributedString(code)
            attributed.font = .system(.body, design: .monospaced)
            attributed.backgroundColor = MarkdownColors.inlineCodeBackground(colorPalette)
            attributed.foregroundColor = MarkdownColors.inlineCodeText(colorPalette)
            return attributed

        case .link(let destination, _, let content):
            var attributed = buildAttributedString(content, style: style.withLink(), colorPalette: colorPalette, bodyFont: bodyFont)
            if let url = URL(string: destination) {
                attributed.link = url
            }
            return attributed

        case .image(_, let alt, _):
            var attributed = AttributedString("[\(alt)]")
            applyStyle(&attributed, style: style, bodyFont: bodyFont)
            return attributed

        case .softBreak:
            var attributed = AttributedString(" ")
            if let bodyFont { attributed.font = bodyFont }
            return attributed

        case .hardBreak:
            var attributed = AttributedString("\n")
            if let bodyFont { attributed.font = bodyFont }
            return attributed

        case .strikethrough(let children):
            return buildAttributedString(children, style: style.withStrikethrough(), colorPalette: colorPalette, bodyFont: bodyFont)

        case .inlineMath(let latex):
            // Plain fallback used wherever no math renderer participates:
            // show the delimited source like inline code.
            var attributed = AttributedString("$\(latex)$")
            attributed.font = .system(.body, design: .monospaced)
            attributed.foregroundColor = MarkdownColors.inlineCodeText(colorPalette)
            return attributed
        }
    }

    /// Applies accumulated style to an AttributedString.
    ///
    /// When `bodyFont` is provided, every text run receives an explicit font attribute.
    /// This prevents SwiftUI's View-level `.font()` from overriding the first run's
    /// font in an AttributedString (a known SwiftUI behavior).
    private static func applyStyle(_ attributed: inout AttributedString, style: InlineStyle, bodyFont: Font?) {
        if let bodyFont {
            if style.isEmphasis && style.isStrong {
                attributed.font = bodyFont.bold().italic()
            } else if style.isEmphasis {
                attributed.font = bodyFont.italic()
            } else if style.isStrong {
                attributed.font = bodyFont.bold()
            } else {
                attributed.font = bodyFont
            }
        } else {
            if style.isEmphasis && style.isStrong {
                attributed.font = .body.bold().italic()
            } else if style.isEmphasis {
                attributed.font = .body.italic()
            } else if style.isStrong {
                attributed.font = .body.bold()
            }
        }

        if style.isStrikethrough {
            attributed.strikethroughStyle = .single
        }

        if style.isLink {
            attributed.underlineStyle = .single
        }
    }
}

// MARK: - Inline Style

/// Tracks accumulated inline formatting styles.
private struct InlineStyle {
    var isEmphasis: Bool = false
    var isStrong: Bool = false
    var isStrikethrough: Bool = false
    var isLink: Bool = false

    static let `default` = InlineStyle()

    func withEmphasis() -> InlineStyle {
        var copy = self
        copy.isEmphasis = true
        return copy
    }

    func withStrong() -> InlineStyle {
        var copy = self
        copy.isStrong = true
        return copy
    }

    func withStrikethrough() -> InlineStyle {
        var copy = self
        copy.isStrikethrough = true
        return copy
    }

    func withLink() -> InlineStyle {
        var copy = self
        copy.isLink = true
        return copy
    }
}
