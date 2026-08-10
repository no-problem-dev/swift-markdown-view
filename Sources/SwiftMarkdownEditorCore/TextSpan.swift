import Foundation

/// A range within a text buffer, measured in **UTF-16 code unit offsets**.
///
/// Offsets count UTF-16 code units, not `Character`s and not Unicode scalars. That is what
/// lets a range produced in this UI-independent layer map directly onto `NSAttributedString`,
/// `NSRange`, and the `UITextView`/`NSTextView` selection APIs without being remeasured in
/// the TextKit layer.
///
/// This follows the document-model convention of established editors — CodeMirror's
/// `EditorState` and ProseMirror's integer positions. A position is a plain integer offset
/// into the buffer, which keeps selection and decoration math to simple arithmetic.
public struct TextSpan: Equatable, Hashable, Sendable {

    /// The inclusive start offset, in UTF-16 code units.
    public var lowerBound: Int

    /// The exclusive end offset, in UTF-16 code units.
    public var upperBound: Int

    /// Creates a span from explicit bounds.
    ///
    /// - Precondition: `lowerBound <= upperBound`, and both are non-negative.
    public init(lowerBound: Int, upperBound: Int) {
        precondition(lowerBound >= 0, "lowerBound must be non-negative")
        precondition(lowerBound <= upperBound, "lowerBound must not exceed upperBound")
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    /// Creates a span from a start offset and a length.
    public init(location: Int, length: Int) {
        self.init(lowerBound: location, upperBound: location + length)
    }

    /// Creates an empty span — a caret — at the given offset.
    public init(caret offset: Int) {
        self.init(lowerBound: offset, upperBound: offset)
    }

    /// The length of the span, in UTF-16 code units.
    public var length: Int { upperBound - lowerBound }

    /// Whether the span is empty, which is how a caret position is represented.
    public var isEmpty: Bool { lowerBound == upperBound }

    /// Whether the offset falls inside the span.
    ///
    /// The span is half-open: the lower bound is included and the upper bound is not.
    /// Contrast with ``overlaps(_:)``, where both bounds count.
    public func contains(_ offset: Int) -> Bool {
        offset >= lowerBound && offset < upperBound
    }

    /// Whether this span shares any offset with another span.
    ///
    /// Both bounds are inclusive here, unlike ``contains(_:)``, so spans that merely touch
    /// count as overlapping: two empty spans at the same offset, or a caret sitting exactly
    /// on the edge of a span. This is the predicate behind the live preview's
    /// cursor-follows reveal, where a caret resting on a boundary must still reveal the
    /// span it borders.
    public func overlaps(_ other: TextSpan) -> Bool {
        lowerBound <= other.upperBound && other.lowerBound <= upperBound
    }
}

public extension TextSpan {

    /// The span as a Foundation range, for handing to the TextKit layer.
    var nsRange: NSRange { NSRange(location: lowerBound, length: length) }

    /// Creates a span from a Foundation range.
    init(_ nsRange: NSRange) {
        self.init(location: nsRange.location, length: nsRange.length)
    }
}
