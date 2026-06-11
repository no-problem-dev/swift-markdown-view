import Foundation

/// A range over a text buffer, expressed in **UTF-16 code unit offsets**.
///
/// Offsets are UTF-16 code units (not `Character`s, not Unicode scalars) so that
/// ranges produced in this UI-independent layer map directly onto
/// `NSAttributedString`, `NSRange`, and `UITextView`/`NSTextView` selection APIs
/// without any re-measuring in the TextKit layer.
///
/// This mirrors the document-model conventions of authoritative editors
/// (CodeMirror's `EditorState`, ProseMirror's integer positions): a position is
/// a plain integer offset into the buffer, which keeps selection and decoration
/// math to simple arithmetic.
public struct TextSpan: Equatable, Hashable, Sendable {

    /// The inclusive start offset (UTF-16 code units).
    public var lowerBound: Int

    /// The exclusive end offset (UTF-16 code units).
    public var upperBound: Int

    /// Creates a range from explicit bounds.
    ///
    /// - Precondition: `lowerBound <= upperBound` and both are non-negative.
    public init(lowerBound: Int, upperBound: Int) {
        precondition(lowerBound >= 0, "lowerBound must be non-negative")
        precondition(lowerBound <= upperBound, "lowerBound must not exceed upperBound")
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }

    /// Creates a range from a location and length (NSRange-style).
    public init(location: Int, length: Int) {
        self.init(lowerBound: location, upperBound: location + length)
    }

    /// An empty (caret) range at the given offset.
    public init(caret offset: Int) {
        self.init(lowerBound: offset, upperBound: offset)
    }

    /// The length of the range in UTF-16 code units.
    public var length: Int { upperBound - lowerBound }

    /// Whether the range is empty (a caret position).
    public var isEmpty: Bool { lowerBound == upperBound }

    /// Whether `offset` falls within `[lowerBound, upperBound)`.
    public func contains(_ offset: Int) -> Bool {
        offset >= lowerBound && offset < upperBound
    }

    /// Whether this range shares any offset with `other`.
    ///
    /// Two empty ranges, or an empty range touching a non-empty one, count as
    /// overlapping only when the caret sits strictly inside the other range or
    /// at a shared boundary — this is the predicate used for cursor-aware
    /// "reveal" in live preview, so touching boundaries must count.
    public func overlaps(_ other: TextSpan) -> Bool {
        lowerBound <= other.upperBound && other.lowerBound <= upperBound
    }
}

public extension TextSpan {

    /// Bridges to a Foundation `NSRange` for use in the TextKit layer.
    var nsRange: NSRange { NSRange(location: lowerBound, length: length) }

    /// Creates a range from a Foundation `NSRange`.
    init(_ nsRange: NSRange) {
        self.init(location: nsRange.location, length: nsRange.length)
    }
}
