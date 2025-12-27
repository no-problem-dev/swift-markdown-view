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
    /// - Parameter inlines: The inline elements to render.
    /// - Returns: A `Text` view with all formatting applied.
    static func render(_ inlines: [MarkdownInline]) -> Text {
        let attributed = buildAttributedString(inlines, style: .default)
        return Text(attributed)
    }

    /// Renders inline elements with specific style context.
    ///
    /// - Parameters:
    ///   - inlines: The inline elements to render.
    ///   - style: The inherited style context.
    /// - Returns: An AttributedString with all formatting applied.
    private static func buildAttributedString(
        _ inlines: [MarkdownInline],
        style: InlineStyle
    ) -> AttributedString {
        var result = AttributedString()
        for inline in inlines {
            result.append(buildSingle(inline, style: style))
        }
        return result
    }

    /// Builds an AttributedString for a single inline element.
    private static func buildSingle(
        _ inline: MarkdownInline,
        style: InlineStyle
    ) -> AttributedString {
        switch inline {
        case .text(let string):
            var attributed = AttributedString(string)
            applyStyle(&attributed, style: style)
            return attributed

        case .emphasis(let children):
            return buildAttributedString(children, style: style.withEmphasis())

        case .strong(let children):
            return buildAttributedString(children, style: style.withStrong())

        case .code(let code):
            var attributed = AttributedString(code)
            attributed.font = .system(.body, design: .monospaced)
            attributed.backgroundColor = .gray.opacity(0.15)
            return attributed

        case .link(let destination, _, let content):
            var attributed = buildAttributedString(content, style: style.withLink())
            if let url = URL(string: destination) {
                attributed.link = url
            }
            return attributed

        case .image(_, let alt, _):
            var attributed = AttributedString("[\(alt)]")
            applyStyle(&attributed, style: style)
            return attributed

        case .softBreak:
            return AttributedString(" ")

        case .hardBreak:
            return AttributedString("\n")

        case .strikethrough(let children):
            return buildAttributedString(children, style: style.withStrikethrough())
        }
    }

    /// Applies accumulated style to an AttributedString.
    private static func applyStyle(_ attributed: inout AttributedString, style: InlineStyle) {
        if style.isEmphasis && style.isStrong {
            attributed.font = .body.bold().italic()
        } else if style.isEmphasis {
            attributed.font = .body.italic()
        } else if style.isStrong {
            attributed.font = .body.bold()
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
