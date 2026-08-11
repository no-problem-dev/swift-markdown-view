import Foundation
import MarkdownModel
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Renders the semantic model into one attributed string that spans the whole document.
///
/// A TextKit view hosts the result. Because everything lives in a single string, selection runs
/// continuously across blocks and the system's default copy returns readable text.
///
/// Covers headings, paragraphs, emphasis, strong, strikethrough, inline code, links, line breaks, ordered
/// and unordered lists (including task lists), block quotes and asides, thematic breaks, code blocks,
/// tables, and image, math, and Mermaid attachments.
package struct MarkdownAttributedBuilder {

    public var theme: MarkdownTextTheme
    /// The optional synchronous renderer for image and math attachments.
    ///
    /// When it returns an image the element becomes a one-character `NSTextAttachment`; when it does not,
    /// the element falls back to readable text tagged with its Markdown source.
    public var attachmentRenderer: (any MarkdownAttachmentRendering)?

    public init(theme: MarkdownTextTheme = .default, attachmentRenderer: (any MarkdownAttachmentRendering)? = nil) {
        self.theme = theme
        self.attachmentRenderer = attachmentRenderer
    }

    public func build(_ content: MarkdownContent) -> NSAttributedString {
        build(content.blocks)
    }

    public func build(_ blocks: [MarkdownBlock]) -> NSAttributedString {
        let out = NSMutableAttributedString()
        for block in blocks {
            out.append(attributed(for: block, indent: 0))
        }
        trimTrailingNewline(out)
        return out
    }

    // MARK: - Blocks

    /// Builds one block as a run of paragraphs.
    ///
    /// Every paragraph is terminated with `\n`, and the spacing that separates blocks lives in the
    /// paragraph style rather than in extra newlines.
    private func attributed(for block: MarkdownBlock, indent: Int) -> NSAttributedString {
        switch block {
        case .paragraph(let inlines):
            return paragraph(inlines, indent: indent)

        case .heading(let level, let content):
            return heading(level: level, content: content, indent: indent)

        case .codeBlock(let language, let code):
            return codeBlock(language: language, code: code, indent: indent)

        case .math(let latex):
            return displayMath(latex, indent: indent)

        case .mermaid(let source):
            return mermaid(source, indent: indent)

        case .aside(let kind, let content):
            return aside(kind: kind, content: content, indent: indent)

        case .unorderedList(let items):
            return list(items, ordered: nil, indent: indent)

        case .orderedList(let start, let items):
            return list(items, ordered: start, indent: indent)

        case .thematicBreak:
            return thematicBreak(indent: indent)

        case .table(let data):
            return table(data, indent: indent)
        }
    }

    private func paragraph(_ inlines: [MarkdownInline], indent: Int) -> NSAttributedString {
        let body = inlineText(inlines, context: .body(theme))
        let style = paragraphStyle(indent: indent, spacingAfter: theme.paragraphSpacing)
        return terminatedParagraph(body, style: style)
    }

    private func heading(level: Int, content: [MarkdownInline], indent: Int) -> NSAttributedString {
        var ctx = InlineContext.body(theme)
        ctx.font = theme.headingFont(level: level)
        ctx.color = theme.headingColor
        let body = inlineText(content, context: ctx)
        let style = paragraphStyle(
            indent: indent,
            spacingAfter: theme.paragraphSpacing,
            spacingBefore: theme.paragraphSpacing * 0.5
        )
        return terminatedParagraph(body, style: style)
    }

    private func codeBlock(language: String?, code: String, indent: Int) -> NSAttributedString {
        let style = codeParagraphStyle(indent: indent)
        let trimmed = code.hasSuffix("\n") ? String(code.dropLast()) : code
        // `.markdownCodeLanguage` scopes the highlightable region to the code
        // text only (excluding the block separator) so an async highlighter's
        // output length matches the region exactly. The decoration spans both so
        // the background fill covers the whole block.
        let decoration = MarkdownBlockDecoration(.codeBlock(language: language))
        var codeAttrs: [NSAttributedString.Key: Any] = [
            .font: theme.codeFont,
            .foregroundColor: theme.inlineCodeForeground,
            .paragraphStyle: style,
            .markdownBlockDecoration: decoration,
            .markdownCodeLanguage: language ?? "",
        ]
        let result = NSMutableAttributedString(string: trimmed, attributes: codeAttrs)
        codeAttrs[.markdownCodeLanguage] = nil
        result.append(NSAttributedString(string: "\n", attributes: codeAttrs))
        return result
    }

    private func blockQuote(_ content: [MarkdownBlock], indent: Int) -> NSAttributedString {
        // Render nested content one indent level deeper; the bar is drawn by the
        // layout fragment. Body text uses the secondary color.
        let inner = NSMutableAttributedString()
        for block in content {
            inner.append(attributedQuoted(for: block, indent: indent + 1))
        }
        if inner.length == 0 {
            inner.append(terminatedParagraph(
                NSAttributedString(string: "", attributes: InlineContext.body(theme).attributes),
                style: paragraphStyle(indent: indent + 1, spacingAfter: theme.paragraphSpacing)
            ))
        }
        inner.addAttribute(
            .markdownBlockDecoration,
            value: MarkdownBlockDecoration(.blockQuote(level: indent + 1)),
            range: NSRange(location: 0, length: inner.length)
        )
        return inner
    }

    /// Builds a block with its body text recolored to the secondary color, so it reads as quoted.
    ///
    /// Only runs already painted in the theme's text color are recolored, which leaves inline code,
    /// links, and headings with their own colors intact.
    private func attributedQuoted(for block: MarkdownBlock, indent: Int) -> NSAttributedString {
        let piece = attributed(for: block, indent: indent)
        let mutable = NSMutableAttributedString(attributedString: piece)
        mutable.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: mutable.length)) { value, range, _ in
            if (value as? PlatformColor) == theme.textColor {
                mutable.addAttribute(.foregroundColor, value: theme.secondaryColor, range: range)
            }
        }
        return mutable
    }

    /// Renders an aside as a tinted callout: a colored label header above the content, with a colored bar.
    ///
    /// Only an aside with an explicit kind gets this treatment; anything else stays a plain quote. A
    /// GitHub-style `[!NOTE]` marker counts as an explicit kind and is stripped from the displayed text.
    private func aside(kind modelKind: AsideKind, content: [MarkdownBlock], indent: Int) -> NSAttributedString {
        var kind = modelKind
        var content = content
        var explicit = false
        if case .paragraph(let inlines)? = content.first,
           let (detected, stripped) = strippedAlertMarker(inlines) {
            kind = detected
            explicit = true
            content[0] = .paragraph(stripped)
        }

        // A plain `> quote` (no marker, default note kind) stays a simple quote
        // rather than being labelled "Note".
        guard explicit || kind != .note else {
            return blockQuote(content, indent: indent)
        }

        let style = asideStyle(for: kind)
        let out = NSMutableAttributedString()

        var headerContext = InlineContext.body(theme)
        headerContext.font = theme.bodyFont(bold: true)
        headerContext.color = style.color
        out.append(terminatedParagraph(
            NSAttributedString(string: style.label, attributes: headerContext.attributes),
            style: paragraphStyle(indent: indent + 1, spacingAfter: theme.paragraphSpacing * 0.2)
        ))

        for block in content {
            out.append(attributedQuoted(for: block, indent: indent + 1))
        }

        let full = NSRange(location: 0, length: out.length)
        out.addAttribute(.markdownBlockDecoration, value: MarkdownBlockDecoration(.blockQuote(level: indent + 1)), range: full)
        out.addAttribute(.markdownDecorationBar, value: style.color, range: full)
        return out
    }

    private func asideStyle(for kind: AsideKind) -> (color: PlatformColor, label: String) {
        let color: PlatformColor
        switch kind {
        case .tip, .experiment:
            color = .systemGreen
        case .important, .attention:
            color = .systemOrange
        case .warning, .bug:
            color = .systemRed
        case .todo:
            color = .systemPurple
        case .custom(let name):
            switch name.lowercased() {
            case "caution", "warning": color = .systemRed
            case "tip": color = .systemGreen
            case "important": color = .systemOrange
            default: color = theme.secondaryColor
            }
        default:
            color = .systemBlue
        }
        return (color, kind.displayName)
    }

    /// Detects a `[!KIND]` marker at the start of the leading text run.
    ///
    /// - Returns: The kind it names together with the inlines minus the marker, or `nil` when the run
    ///   does not open with one.
    private func strippedAlertMarker(_ inlines: [MarkdownInline]) -> (AsideKind, [MarkdownInline])? {
        guard case .text(let text) = inlines.first else { return nil }
        let body = text.drop(while: { $0 == " " || $0 == "\t" })
        guard body.hasPrefix("[!"), let close = body.firstIndex(of: "]") else { return nil }
        let nameStart = body.index(body.startIndex, offsetBy: 2)
        guard nameStart < close else { return nil }
        let name = body[nameStart..<close]
        guard !name.isEmpty, name.allSatisfy({ $0.isLetter }) else { return nil }

        let remainder = String(body[body.index(after: close)...].drop(while: { $0 == " " || $0 == "\t" || $0 == "\n" }))
        var rest = Array(inlines.dropFirst())
        if remainder.isEmpty {
            if case .softBreak = rest.first { rest.removeFirst() }
            else if case .hardBreak = rest.first { rest.removeFirst() }
        } else {
            rest.insert(.text(remainder), at: 0)
        }
        return (AsideKind(rawValue: String(name)), rest)
    }

    private func list(_ items: [ListItem], ordered start: Int?, indent: Int) -> NSAttributedString {
        let out = NSMutableAttributedString()
        for (offset, item) in items.enumerated() {
            let marker = listMarker(ordered: start, position: offset, isChecked: item.isChecked)
            out.append(listItem(item, marker: marker, indent: indent))
        }
        return out
    }

    private func listItem(_ item: ListItem, marker: String, indent: Int) -> NSAttributedString {
        let markerColumn = CGFloat(indent + 1) * theme.indentStep
        let firstLineIndent = CGFloat(indent) * theme.indentStep
        let style = listParagraphStyle(
            firstLineIndent: firstLineIndent,
            hangingIndent: markerColumn,
            spacingAfter: theme.paragraphSpacing * 0.35
        )

        // The marker + the item's first block share the first line.
        let blocks = item.blocks
        let out = NSMutableAttributedString()

        var markerAttrs = InlineContext.body(theme).attributes
        markerAttrs[.foregroundColor] = theme.secondaryColor
        markerAttrs[.paragraphStyle] = style

        if let first = blocks.first, case .paragraph(let inlines) = first {
            let line = NSMutableAttributedString(string: marker, attributes: markerAttrs)
            let body = NSMutableAttributedString(attributedString: inlineText(inlines, context: .body(theme)))
            body.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: body.length))
            line.append(body)
            line.append(NSAttributedString(string: "\n", attributes: markerAttrs))
            out.append(line)
            // Remaining blocks in the item render indented one level deeper.
            for block in blocks.dropFirst() {
                out.append(attributed(for: block, indent: indent + 1))
            }
        } else {
            // Non-paragraph first block: marker on its own line, content nested.
            out.append(NSAttributedString(string: marker + "\n", attributes: markerAttrs))
            for block in blocks {
                out.append(attributed(for: block, indent: indent + 1))
            }
        }
        return out
    }

    private func displayMath(_ latex: String, indent: Int) -> NSAttributedString {
        let style = paragraphStyle(indent: indent, spacingAfter: theme.paragraphSpacing)
        let body = attachmentOrFallback(
            kind: .displayMath(latex: latex),
            fallback: latex,
            context: codeContext()
        )
        return terminatedParagraph(body, style: style)
    }

    private func mermaid(_ source: String, indent: Int) -> NSAttributedString {
        // A zero-bounds placeholder attachment the view layer swaps for a WebView
        // attachment that renders the diagram; the fenced source travels in the
        // attachment's own `.mermaid` kind.
        let style = paragraphStyle(indent: indent, spacingAfter: theme.paragraphSpacing)
        let body = makeAttachment(image: nil, bounds: .zero, kind: .mermaid(source: source))
        return terminatedParagraph(body, style: style)
    }

    private func thematicBreak(indent: Int) -> NSAttributedString {
        // The rule itself is painted full-width by the layout fragment; the line
        // holds a single (near-invisible) space purely to give the fragment a
        // line to draw over and a sane copy result.
        let style = paragraphStyle(indent: indent, spacingAfter: theme.paragraphSpacing)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: theme.baseFont,
            .foregroundColor: theme.ruleColor,
            .paragraphStyle: style,
            .markdownBlockDecoration: MarkdownBlockDecoration(.thematicBreak),
        ]
        return NSAttributedString(string: " \n", attributes: attrs)
    }

    /// Lays a table out as tab-separated rows at computed column tab stops.
    ///
    /// The cells are real text, so selection works cell by cell and the default copy yields tab-separated
    /// rows that paste straight into a spreadsheet. The fragment draws the grid.
    private func table(_ data: TableData, indent: Int) -> NSAttributedString {
        let rows = [data.headerRow] + data.bodyRows
        let columnCount = rows.map(\.cells.count).max() ?? 0
        guard columnCount > 0 else { return NSAttributedString() }

        // Measure column widths from the rendered (single-line) cell text.
        let headerFont = theme.bodyFont(bold: true)
        var widths = [CGFloat](repeating: 0, count: columnCount)
        for (rowIndex, row) in rows.enumerated() {
            let font = rowIndex == 0 ? headerFont : theme.baseFont
            for column in 0..<columnCount {
                let text = cellPlainText(row, column: column)
                let width = (text as NSString).size(withAttributes: [.font: font]).width
                widths[column] = max(widths[column], width)
            }
        }

        let cellPadding: CGFloat = 18
        let baseIndent = CGFloat(indent) * theme.indentStep
        var columnStarts: [CGFloat] = []
        var cursor = baseIndent
        for column in 0..<columnCount {
            columnStarts.append(cursor)
            cursor += widths[column] + cellPadding
        }

        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = theme.lineHeightMultiple
        style.firstLineHeadIndent = baseIndent
        style.headIndent = baseIndent
        style.tabStops = columnStarts.dropFirst().map { NSTextTab(textAlignment: .left, location: $0) }

        let out = NSMutableAttributedString()
        for (rowIndex, row) in rows.enumerated() {
            let bold = rowIndex == 0
            var context = InlineContext.body(theme)
            if bold { context.font = headerFont }
            let line = NSMutableAttributedString()
            for column in 0..<columnCount {
                if column > 0 { line.append(NSAttributedString(string: "\t", attributes: context.attributes)) }
                let cellInlines = column < row.cells.count ? row.cells[column] : []
                let cell = NSMutableAttributedString(attributedString: inlineText(cellInlines, context: context))
                stripNewlines(cell)
                line.append(cell)
            }
            line.append(NSAttributedString(string: "\n", attributes: context.attributes))
            line.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: line.length))
            out.append(line)
        }

        let fullRange = NSRange(location: 0, length: out.length)
        out.addAttribute(
            .markdownBlockDecoration,
            value: MarkdownBlockDecoration(.table(columns: columnCount)),
            range: fullRange
        )
        // Inter-block spacing after the table.
        if out.length > 0 {
            let lastParagraph = NSMutableParagraphStyle()
            lastParagraph.setParagraphStyle(style)
            lastParagraph.paragraphSpacing = theme.paragraphSpacing
            // Apply spacing to the final row only.
            let lastRowRange = (out.string as NSString).paragraphRange(for: NSRange(location: out.length - 1, length: 0))
            out.addAttribute(.paragraphStyle, value: lastParagraph, range: lastRowRange)
        }
        return out
    }

    private func cellPlainText(_ row: TableRow, column: Int) -> String {
        guard column < row.cells.count else { return "" }
        return plainText(inlineText(row.cells[column], context: .body(theme)))
    }

    private func stripNewlines(_ string: NSMutableAttributedString) {
        while true {
            let range = (string.string as NSString).range(of: "\n")
            guard range.location != NSNotFound else { break }
            string.replaceCharacters(in: range, with: " ")
        }
    }

    // MARK: - Inlines

    /// Converts inline content into an attributed string carrying an explicit font and color on every run.
    ///
    /// Being explicit keeps a view-level font from overriding the leading run.
    func inlineText(_ inlines: [MarkdownInline], context: InlineContext) -> NSAttributedString {
        let out = NSMutableAttributedString()
        for inline in inlines {
            switch inline {
            case .text(let string):
                out.append(NSAttributedString(string: string, attributes: context.attributes))

            case .emphasis(let children):
                out.append(inlineText(children, context: context.with(italic: true)))

            case .strong(let children):
                out.append(inlineText(children, context: context.with(bold: true)))

            case .strikethrough(let children):
                out.append(inlineText(children, context: context.with(strikethrough: true)))

            case .code(let code):
                var attrs = context.attributes
                attrs[.font] = theme.codeFont
                attrs[.foregroundColor] = theme.inlineCodeForeground
                attrs[.backgroundColor] = theme.inlineCodeBackground
                out.append(NSAttributedString(string: code, attributes: attrs))

            case .link(let destination, _, let children):
                var ctx = context.with(link: true)
                ctx.color = theme.linkColor
                let attributed = NSMutableAttributedString(attributedString: inlineText(children, context: ctx))
                if let url = URL(string: destination) {
                    attributed.addAttribute(.link, value: url, range: NSRange(location: 0, length: attributed.length))
                }
                out.append(attributed)

            case .image(let source, let alt, _):
                out.append(imageInline(source: source, alt: alt, context: context))

            case .inlineMath(let latex):
                var mathContext = context
                mathContext.font = theme.codeFont
                mathContext.color = theme.inlineCodeForeground
                out.append(attachmentOrFallback(
                    kind: .inlineMath(latex: latex),
                    fallback: "$\(latex)$",
                    context: mathContext
                ))

            case .softBreak:
                out.append(NSAttributedString(string: " ", attributes: context.attributes))

            case .hardBreak:
                out.append(NSAttributedString(string: "\n", attributes: context.attributes))
            }
        }
        return out
    }

    // MARK: - Attachments

    private func codeContext() -> InlineContext {
        var ctx = InlineContext.body(theme)
        ctx.font = theme.codeFont
        ctx.color = theme.inlineCodeForeground
        return ctx
    }

    /// Returns a one-character attachment (U+FFFC) when the renderer produced an image, readable text otherwise.
    ///
    /// Either way the run carries a `.markdownAttachment` tag naming what it stands for.
    private func attachmentOrFallback(
        kind: MarkdownAttachment.Kind,
        fallback: String,
        context: InlineContext
    ) -> NSAttributedString {
        if let rendered = attachmentRenderer?.renderedImage(for: kind, theme: theme) {
            return makeAttachment(
                image: rendered.image,
                bounds: CGRect(x: 0, y: rendered.baselineOffset, width: rendered.size.width, height: rendered.size.height),
                kind: kind
            )
        }
        var attrs = context.attributes
        attrs[.markdownAttachment] = MarkdownAttachment(kind)
        return NSAttributedString(string: fallback, attributes: attrs)
    }

    /// Builds an image as an attachment the view fills in asynchronously, with zero bounds until it loads.
    ///
    /// A synchronous renderer takes precedence, and an empty source degrades to the alt text in brackets.
    private func imageInline(source: String, alt: String, context: InlineContext) -> NSAttributedString {
        let kind = MarkdownAttachment.Kind.image(source: source, alt: alt)
        if let rendered = attachmentRenderer?.renderedImage(for: kind, theme: theme) {
            return makeAttachment(
                image: rendered.image,
                bounds: CGRect(origin: .zero, size: rendered.size),
                kind: kind
            )
        }
        guard !source.isEmpty else {
            return NSAttributedString(string: "[\(alt)]", attributes: context.attributes)
        }
        return makeAttachment(image: nil, bounds: .zero, kind: kind)
    }

    private func makeAttachment(image: PlatformImage?, bounds: CGRect, kind: MarkdownAttachment.Kind) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = bounds
        let result = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        result.addAttribute(
            .markdownAttachment,
            value: MarkdownAttachment(kind),
            range: NSRange(location: 0, length: result.length)
        )
        return result
    }

    // MARK: - Helpers

    private func listMarker(ordered start: Int?, position: Int, isChecked: Bool?) -> String {
        if let isChecked {
            return (isChecked ? "\u{2611}" : "\u{2610}") + "\t" // ☑ / ☐
        }
        if let start {
            return "\(start + position).\t"
        }
        return "\u{2022}\t" // •
    }

    private func terminatedParagraph(_ body: NSAttributedString, style: NSParagraphStyle) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: body)
        result.append(NSAttributedString(string: "\n"))
        result.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: result.length))
        return result
    }

    private func paragraphStyle(indent: Int, spacingAfter: CGFloat, spacingBefore: CGFloat = 0) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = spacingAfter
        style.paragraphSpacingBefore = spacingBefore
        style.lineHeightMultiple = theme.lineHeightMultiple
        let indentPoints = CGFloat(indent) * theme.indentStep
        style.firstLineHeadIndent = indentPoints
        style.headIndent = indentPoints
        return style
    }

    /// Paragraph style for code blocks, indenting the text inside its filled background box.
    ///
    /// The vertical breathing room around the box is added when the background is drawn, not here.
    private func codeParagraphStyle(indent: Int) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = theme.paragraphSpacing
        style.paragraphSpacingBefore = 0
        style.lineHeightMultiple = 1.0
        let indentPoints = CGFloat(indent) * theme.indentStep + theme.codeBlockPadding
        style.firstLineHeadIndent = indentPoints
        style.headIndent = indentPoints
        // Symmetric right padding so code text doesn't touch the box's edge
        // (tailIndent <= 0 is measured from the trailing margin).
        style.tailIndent = -theme.codeBlockPadding
        return style
    }

    private func listParagraphStyle(firstLineIndent: CGFloat, hangingIndent: CGFloat, spacingAfter: CGFloat) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = spacingAfter
        style.lineHeightMultiple = theme.lineHeightMultiple
        style.firstLineHeadIndent = firstLineIndent
        style.headIndent = hangingIndent
        style.tabStops = [NSTextTab(textAlignment: .left, location: hangingIndent)]
        return style
    }

    private func plainText(_ attributed: NSAttributedString) -> String {
        attributed.string.replacingOccurrences(of: "\n", with: " ")
    }

    private func trimTrailingNewline(_ string: NSMutableAttributedString) {
        let s = string.string
        if s.hasSuffix("\n") {
            string.deleteCharacters(in: NSRange(location: string.length - 1, length: 1))
        }
    }
}

// MARK: - Inline styling context

/// The inline styles in effect, already resolved to a concrete font and color.
struct InlineContext {
    var font: PlatformFont
    var color: PlatformColor
    var bold: Bool = false
    var italic: Bool = false
    var strikethrough: Bool = false
    var link: Bool = false

    static func body(_ theme: MarkdownTextTheme) -> InlineContext {
        InlineContext(font: theme.baseFont, color: theme.textColor)
    }

    func with(bold: Bool = false, italic: Bool = false, strikethrough: Bool = false, link: Bool = false) -> InlineContext {
        var copy = self
        copy.bold = copy.bold || bold
        copy.italic = copy.italic || italic
        copy.strikethrough = copy.strikethrough || strikethrough
        copy.link = copy.link || link
        return copy
    }

    var attributes: [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font.withTraits(bold: bold, italic: italic),
            .foregroundColor: color,
        ]
        if strikethrough {
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        if link {
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        return attrs
    }
}
