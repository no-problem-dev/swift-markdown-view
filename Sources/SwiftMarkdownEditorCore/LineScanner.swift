import Foundation

/// Line boundaries over UTF-16 offsets.
///
/// Input rules and the TextKit layer constantly need "the line the caret sits on". These helpers
/// compute the line range without allocating a substring per line across the whole document.
public extension String {

    /// The range of the line containing the given offset, excluding the trailing newline.
    ///
    /// The offset is in UTF-16 code units and is clamped to the string, so an out-of-range value
    /// returns the first or last line rather than trapping.
    func lineRange(containing offset: Int) -> TextSpan {
        let units = Array(utf16)
        let clamped = Swift.max(0, Swift.min(offset, units.count))

        var start = clamped
        while start > 0 && units[start - 1] != 0x0A { start -= 1 }

        var end = clamped
        while end < units.count && units[end] != 0x0A { end += 1 }

        return TextSpan(lowerBound: start, upperBound: end)
    }

    /// The text of the line containing the given offset, without the newline.
    func line(containing offset: Int) -> String {
        substring(in: lineRange(containing: offset))
    }
}
