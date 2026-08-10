import Foundation

package extension NSAttributedString.Key {
    /// Marks a paragraph range as a decoration block that the TextKit layout fragment paints behind or beside.
    ///
    /// Covers code block fills, quote bars, and horizontal rules. The value is a ``MarkdownBlockDecoration``.
    static let markdownBlockDecoration = NSAttributedString.Key("markdownBlockDecoration")

    /// The language of a code block, or the empty string when the fence gave none.
    ///
    /// Tagged on the code characters only, so an asynchronous syntax highlighter can find the range and
    /// recolor it after the initial layout.
    static let markdownCodeLanguage = NSAttributedString.Key("markdownCodeLanguage")

    /// The Markdown source of a run that is drawn as something other than its literal text.
    ///
    /// Attachments, the readable text they fall back to, and table rows carry it, so a consumer can
    /// recover the source text behind a range of the rendered string.
    static let markdownSource = NSAttributedString.Key("markdownSource")

    /// Identifies an attachment run, either an image or a formula.
    ///
    /// An asynchronous resolver uses it to fill in or update the image after layout. The value is a
    /// ``MarkdownAttachment``.
    static let markdownAttachment = NSAttributedString.Key("markdownAttachment")

    /// The color of the leading bar drawn beside a block quote or aside.
    ///
    /// Overrides the palette default so an aside's bar can be tinted by its kind. The value is a
    /// `PlatformColor`.
    static let markdownDecorationBar = NSAttributedString.Key("markdownDecorationBar")
}

/// An inline object — an image or a formula — occupying one attachment character (U+FFFC) in the text.
///
/// Selection passes over it as a single character, and its `.markdownSource` tag holds the Markdown it
/// was rendered from.
public final class MarkdownAttachment: NSObject {

    public enum Kind: Equatable, Sendable {
        case image(source: String, alt: String)
        case inlineMath(latex: String)
        case displayMath(latex: String)
        /// A Mermaid diagram, drawn by a web view attachment.
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

/// Describes how the custom layout fragment should decorate a block range.
///
/// A reference type (`NSObject`) so it can serve as an `NSTextStorage` attribute value and survive copy
/// and edit operations.
package final class MarkdownBlockDecoration: NSObject {

    public enum Kind: Equatable, Sendable {
        /// A fenced or indented code block.
        ///
        /// The fragment fills a rounded background behind it.
        case codeBlock(language: String?)
        /// A block quote at the given nesting depth, where 1 is the outermost level.
        ///
        /// The fragment draws one leading bar per level.
        case blockQuote(level: Int)
        /// A thematic break, drawn by the fragment as a horizontal rule.
        case thematicBreak
        /// A table.
        ///
        /// The fragment draws the rule under the header and the separators between rows.
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
