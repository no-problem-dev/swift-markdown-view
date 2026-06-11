import Foundation

/// A syntactic token in Markdown source, used to drive source-side syntax
/// highlighting.
///
/// Tokens carry a ``TextSpan`` (UTF-16 offsets) and a ``Kind``. The TextKit
/// layer maps each kind to text attributes. Tokens never overlap, so they can be
/// applied to an `NSAttributedString` in a single left-to-right pass.
public struct MarkdownToken: Equatable, Sendable {

    /// The category of a token. The set is intentionally small and source-mode
    /// oriented (tint the markers, color spans) — full inline matching is a
    /// live-preview concern handled later.
    public enum Kind: Equatable, Hashable, Sendable, CaseIterable {
        /// The `#` run that opens an ATX heading.
        case headingMarker
        /// The text of a heading line (after the marker).
        case heading
        /// A run of `*`/`_` of length 1 (emphasis delimiters).
        case emphasis
        /// A run of `*`/`_` of length >= 2 (strong delimiters).
        case strong
        /// A `~~` run (strikethrough delimiters).
        case strikethrough
        /// An inline code span, including its backticks.
        case inlineCode
        /// A fenced code block delimiter line (```` ``` ```` / `~~~`).
        case codeFence
        /// A line of content inside a fenced code block.
        case codeBlock
        /// A list bullet/number marker (`-`, `*`, `+`, `1.`).
        case listMarker
        /// A task list checkbox (`[ ]` / `[x]`).
        case taskMarker
        /// A blockquote `>` marker run.
        case blockquote
        /// A thematic break line (`---`, `***`, `___`).
        case thematicBreak
        /// The bracketed text of a link/image (`[text]`, `![alt]`).
        case linkText
        /// The parenthesized destination of a link/image (`(url)`).
        case linkURL
    }

    public var range: TextSpan
    public var kind: Kind

    public init(range: TextSpan, kind: Kind) {
        self.range = range
        self.kind = kind
    }
}
