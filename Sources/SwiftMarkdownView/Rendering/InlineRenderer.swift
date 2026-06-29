import SwiftUI
import DesignSystem

/// インライン Markdown 要素を SwiftUI Text としてレンダリングする。
///
/// `MarkdownInline` 要素を連結した `Text` ビューに変換し、
/// 強調・太字・インラインコードなどの書式を保持する。
/// リンクは AttributedString を使用してタップ可能な要素としてレンダリングされる。
enum InlineRenderer {

    /// インライン要素配列を単一の連結 Text としてレンダリングする。
    ///
    /// - Parameters:
    ///   - inlines: レンダリングするインライン要素。
    ///   - colorPalette: インライン要素のテーマ用カラーパレット。
    ///   - bodyFont: すべてのテキストランに適用するベースフォント。指定した場合、
    ///     AttributedString 内の各ランに明示的なフォント属性が付与され、
    ///     SwiftUI の View レベル `.font()` が最初のランを上書きするのを防ぐ。
    /// - Returns: すべての書式を適用した `Text` ビュー。
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

    /// インライン要素をレンダリングし、インライン数式を数式レンダラーに委譲する。
    ///
    /// AttributedString は任意のビューをホストできないため、段落は
    /// 連結した `Text` セグメントとして構築される。インライン数式要素が
    /// 独自の `Text` を生成するたびに、蓄積された attributed ランをフラッシュする。
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

    /// 特定のスタイルコンテキストでインライン要素をレンダリングする。
    ///
    /// - Parameters:
    ///   - inlines: レンダリングするインライン要素。
    ///   - style: 継承されたスタイルコンテキスト。
    ///   - colorPalette: テーマ用カラーパレット。
    ///   - bodyFont: プレーンテキストランのベースフォント。
    /// - Returns: すべての書式を適用した AttributedString。
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

    /// 単一のインライン要素から AttributedString を構築する。
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

    /// 蓄積されたスタイルを AttributedString に適用する。
    ///
    /// `bodyFont` が指定された場合、すべてのテキストランに明示的なフォント属性を付与する。
    /// これにより、AttributedString において SwiftUI の View レベル `.font()` が
    /// 最初のランのフォントを上書きする既知の SwiftUI 挙動を防ぐ。
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

/// 蓄積されたインライン書式スタイルを追跡する。
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
