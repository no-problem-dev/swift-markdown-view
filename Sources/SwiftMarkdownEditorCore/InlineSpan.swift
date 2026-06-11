import Foundation

/// A matched inline span: a styled run of text together with the delimiter
/// (marker) ranges that produced it.
///
/// Phase 1's ``MarkdownToken`` scanner emits *flat* delimiter runs for source
/// highlighting. Live preview needs more: to render `**bold**` as **bold** with
/// the `**` hidden, it must know both the *content* range (to style) and the
/// *marker* ranges (to conceal). ``InlineSpan`` pairs the delimiters and carries
/// exact UTF-16 offsets so the TextKit layer can apply attributes without any
/// re-measuring.
public struct InlineSpan: Equatable, Sendable {

    public enum Kind: Equatable, Hashable, Sendable {
        case strong          // **x** / __x__
        case emphasis        // *x* / _x_
        case strikethrough   // ~~x~~
        case code            // `x`
    }

    public var kind: Kind
    /// The whole span including markers.
    public var fullRange: TextSpan
    /// The content between the markers (what gets styled).
    public var contentRange: TextSpan
    /// The delimiter ranges (opening then closing) — what gets concealed.
    public var markerRanges: [TextSpan]

    public init(kind: Kind, fullRange: TextSpan, contentRange: TextSpan, markerRanges: [TextSpan]) {
        self.kind = kind
        self.fullRange = fullRange
        self.contentRange = contentRange
        self.markerRanges = markerRanges
    }
}
