import Foundation

/// UTF-16 offset conversions shared across the editor core.
///
/// The whole editor model addresses text by UTF-16 code unit offsets (see ``TextSpan``),
/// while mutating a Swift `String` works in terms of `String.Index`. These helpers convert
/// between the two.
///
/// An offset that lands in the middle of a grapheme cluster — between the halves of a
/// surrogate pair, or between a base character and a combining mark — cannot be split, so
/// it is **snapped outward to the enclosing character boundary**. Handing such an offset
/// straight to `String.Index(utf16Offset:in:)` instead leaves `replaceSubrange` to round it
/// to a boundary itself, and the range you meant to delete is not deleted: replacing
/// `1..<2` of `"a👍b"` degenerates into a pure insertion. The computed length and the actual
/// text then disagree, and every position mapping and undo from that point on is off.
public extension String {

    var utf16Length: Int { utf16.count }

    /// Returns the string index corresponding to a UTF-16 offset.
    ///
    /// - Parameters:
    ///   - offset: The UTF-16 code unit offset. Values outside the string are clamped to
    ///     its bounds.
    ///   - roundingUp: Which way to snap when the offset lands inside a grapheme cluster.
    ///     Pass `false` to snap to the boundary before it and `true` to snap to the boundary
    ///     after it. Use `false` for the lower bound of a range and `true` for the upper.
    func index(utf16Offset offset: Int, roundingUp: Bool = false) -> String.Index {
        let clamped = Swift.max(0, Swift.min(offset, utf16Length))
        let raw = String.Index(utf16Offset: clamped, in: self)
        guard raw.samePosition(in: self) == nil else { return raw }
        let enclosing = rangeOfComposedCharacterSequence(at: raw)
        return roundingUp ? enclosing.upperBound : enclosing.lowerBound
    }

    /// Returns the string index range corresponding to a span.
    ///
    /// The lower bound snaps backward and the upper bound snaps forward, so a span that cuts
    /// through a character boundary widens to take in the whole character.
    func range(for textRange: TextSpan) -> Range<String.Index> {
        let lower = index(utf16Offset: textRange.lowerBound, roundingUp: false)
        let upper = index(utf16Offset: textRange.upperBound, roundingUp: true)
        return lower ..< Swift.max(lower, upper)
    }

    /// Returns the substring a span covers.
    ///
    /// The span is resolved with the same outward snapping as `range(for:)`, so a span that
    /// cuts a grapheme cluster yields the whole character rather than half of one.
    func substring(in textRange: TextSpan) -> String {
        String(self[range(for: textRange)])
    }

    /// Returns the span normalized to this string's character boundaries.
    ///
    /// Put offsets through this before they reach the model whenever they were assembled by
    /// arithmetic — values handed in from outside, or sums and differences of lengths. It
    /// keeps a `TextChange`'s length arithmetic in agreement with the text its replacement
    /// actually produces.
    func alignedSpan(_ textRange: TextSpan) -> TextSpan {
        let range = range(for: textRange)
        return TextSpan(
            lowerBound: range.lowerBound.utf16Offset(in: self),
            upperBound: range.upperBound.utf16Offset(in: self)
        )
    }
}
