import Foundation

public extension NSAttributedString.Key {
    /// Marks a paragraph range as a decorated block so the TextKit layout
    /// fragment can draw its background or ornament (code-block fill, quote bar,
    /// thematic rule). The value is a ``MarkdownBlockDecoration``.
    static let markdownBlockDecoration = NSAttributedString.Key("markdownBlockDecoration")

    /// The language string of a code block (empty when unspecified). Marks the
    /// code's character range so an async syntax highlighter can locate and
    /// recolor it after the initial layout.
    static let markdownCodeLanguage = NSAttributedString.Key("markdownCodeLanguage")

    /// The Markdown source for a run that renders as something other than its
    /// literal text (an image/math attachment, a list marker). Used to
    /// reconstruct Markdown on a "Copy as Markdown" command.
    static let markdownSource = NSAttributedString.Key("markdownSource")

    /// Identifies an attachment run (image or math) as a ``MarkdownAttachment``,
    /// so an async resolver can fill or refresh its image after layout.
    static let markdownAttachment = NSAttributedString.Key("markdownAttachment")

    /// A `PlatformColor` for the leading bar of a blockquote/aside, overriding
    /// the palette's default. Used to tint an aside's bar by its kind.
    static let markdownDecorationBar = NSAttributedString.Key("markdownDecorationBar")
}

/// Describes an inline object (image or math) that occupies a single attachment
/// character (U+FFFC) in the rendered text, so selection passes through it as one
/// character and Copy-as-Markdown can reconstruct its source.
public final class MarkdownAttachment: NSObject {

    public enum Kind: Equatable, Sendable {
        case image(source: String, alt: String)
        case inlineMath(latex: String)
        case displayMath(latex: String)
        /// A Mermaid diagram; rendered by a WebView attachment.
        case mermaid(source: String)
    }

    public let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public override func isEqual(_ object: Any?) -> Bool {
        (object as? MarkdownAttachment).map { $0.kind == kind } ?? false
    }

    public override var hash: Int {
        switch kind {
        case .image(let s, _): return s.hashValue
        case .inlineMath(let l), .displayMath(let l): return l.hashValue
        case .mermaid(let s): return s.hashValue
        }
    }
}

/// Describes how a block range should be ornamented by the custom layout
/// fragment. A reference type (`NSObject`) so it is a valid `NSTextStorage`
/// attribute value that survives copy/edit operations.
public final class MarkdownBlockDecoration: NSObject {

    public enum Kind: Equatable, Sendable {
        /// A fenced/indented code block; the fragment fills a rounded background.
        case codeBlock(language: String?)
        /// A blockquote at the given nesting depth (1 = top level); the fragment
        /// draws a leading bar per level.
        case blockQuote(level: Int)
        /// A thematic break; the fragment draws a horizontal rule.
        case thematicBreak
        /// A table; the fragment draws a header underline and row separators.
        /// `headerLength` is the character length of the header row (incl. its
        /// trailing newline) so the fragment can distinguish header from body.
        case table(columns: Int)
    }

    public let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public override func isEqual(_ object: Any?) -> Bool {
        (object as? MarkdownBlockDecoration).map { $0.kind == kind } ?? false
    }

    public override var hash: Int {
        switch kind {
        case .codeBlock(let language): return language.hashValue
        case .blockQuote(let level): return level.hashValue
        case .thematicBreak: return 0x7B12EAC
        case .table(let columns): return 0x7AB1E ^ columns.hashValue
        }
    }
}
