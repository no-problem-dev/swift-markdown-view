import Foundation

/// UTF-16 offset conversion helpers shared by the editor core.
///
/// The whole editor model addresses text by UTF-16 code unit offset (see
/// ``TextSpan``). Swift `String` mutation works on `String.Index`, so these
/// helpers translate between the two safely, clamping out-of-range offsets to
/// the buffer bounds rather than trapping.
public extension String {

    /// The total length of the string in UTF-16 code units.
    var utf16Length: Int { utf16.count }

    /// Returns the `String.Index` for a UTF-16 offset, clamped to valid bounds.
    func index(utf16Offset offset: Int) -> String.Index {
        let clamped = Swift.max(0, Swift.min(offset, utf16Length))
        return String.Index(utf16Offset: clamped, in: self)
    }

    /// Returns the `Range<String.Index>` for a ``TextSpan``, clamped to bounds.
    func range(for textRange: TextSpan) -> Range<String.Index> {
        index(utf16Offset: textRange.lowerBound) ..< index(utf16Offset: textRange.upperBound)
    }

    /// Returns the substring covered by a ``TextSpan``.
    func substring(in textRange: TextSpan) -> String {
        String(self[range(for: textRange)])
    }
}
