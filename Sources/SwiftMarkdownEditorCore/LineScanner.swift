import Foundation

/// Line boundary utilities over UTF-16 offsets.
///
/// Input rules and the TextKit layer frequently need "the line the caret is on".
/// These helpers compute line ranges without allocating per-line substrings for
/// the whole document.
public extension String {

    /// The range of the line containing `offset`, excluding the trailing
    /// newline. Offsets are UTF-16 code units.
    func lineRange(containing offset: Int) -> TextSpan {
        let units = Array(utf16)
        let clamped = Swift.max(0, Swift.min(offset, units.count))

        var start = clamped
        while start > 0 && units[start - 1] != 0x0A { start -= 1 }

        var end = clamped
        while end < units.count && units[end] != 0x0A { end += 1 }

        return TextSpan(lowerBound: start, upperBound: end)
    }

    /// The text of the line containing `offset` (without the newline).
    func line(containing offset: Int) -> String {
        substring(in: lineRange(containing: offset))
    }
}
