import Foundation

/// A syntax token in Markdown source, used to highlight the source side.
///
/// A token carries a ``TextSpan`` of UTF-16 offsets and a ``Kind``, which the TextKit layer maps to
/// text attributes. Tokens never overlap, so they can be applied to an `NSAttributedString` in a
/// single left-to-right pass.
public struct MarkdownToken: Equatable, Sendable {

    /// What a token is.
    ///
    /// The set is deliberately small and aimed at source mode: colour the markers, tint the spans.
    /// Full inline matching is live preview's job.
    public enum Kind: Equatable, Hashable, Sendable, CaseIterable {
        /// The `#` run that opens an ATX heading.
        case headingMarker
        /// The text of a heading line, after its marker.
        case heading
        /// A `*` or `_` run of length 1, an emphasis delimiter.
        case emphasis
        /// A `*` or `_` run of length 2 or more, a strong delimiter.
        case strong
        /// A `~~` run, a strikethrough delimiter.
        case strikethrough
        /// An inline code span, backticks included.
        case inlineCode
        /// The delimiter line of a fenced code block, written with three backticks or three tildes.
        case codeFence
        /// A content line inside a fenced code block.
        case codeBlock
        /// A list bullet or number marker (`-`, `*`, `+`, `1.`).
        case listMarker
        /// A task list checkbox (`[ ]` or `[x]`).
        case taskMarker
        /// A run of blockquote `>` markers.
        case blockquote
        /// A thematic break (`---`, `***`, `___`).
        case thematicBreak
        /// The bracketed text of a link or image (`[text]`, `![alt]`).
        case linkText
        /// The parenthesised destination of a link or image (`(url)`).
        case linkURL
    }

    public var range: TextSpan
    public var kind: Kind

    public init(range: TextSpan, kind: Kind) {
        self.range = range
        self.kind = kind
    }
}
