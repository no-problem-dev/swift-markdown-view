import Foundation

/// A matched inline span: the text to style, paired with the delimiter runs that produced it.
///
/// The ``MarkdownToken`` scanner emits a flat list of delimiter runs, which is all source
/// highlighting needs. Live preview needs more: rendering `**bold**` as **bold** with the `**`
/// hidden requires both the *content* range to style and the *marker* ranges to hide.
/// An inline span pairs the delimiters and keeps exact UTF-16 offsets, so the TextKit layer can
/// apply attributes without measuring anything again.
package struct InlineSpan: Equatable, Sendable {

    package enum Kind: Equatable, Hashable, Sendable {
        case strong          // **x** / __x__
        case emphasis        // *x* / _x_
        case strikethrough   // ~~x~~
        case code            // `x`
    }

    package var kind: Kind
    /// The whole span, delimiters included.
    package var fullRange: TextSpan
    /// The text between the delimiters — the part that gets styled.
    package var contentRange: TextSpan
    /// The delimiter runs to hide, opening marker first, then the closing one.
    package var markerRanges: [TextSpan]

    package init(kind: Kind, fullRange: TextSpan, contentRange: TextSpan, markerRanges: [TextSpan]) {
        self.kind = kind
        self.fullRange = fullRange
        self.contentRange = contentRange
        self.markerRanges = markerRanges
    }
}
