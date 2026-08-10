import Foundation

/// Finds a document's line boundaries once, then answers line lookups by binary search.
///
/// `String.lineRange(containing:)` copies the entire document with `Array(utf16)` on every
/// call. That is fine once, but the live preview calls it once per inline span, so the work
/// becomes document length × span count — effectively quadratic. It runs on every
/// keystroke, which in a long document means a single keystroke takes seconds. Callers that
/// scan the same document repeatedly should use this type instead.
package struct LineIndex: Sendable {

    /// The start offset of each line, in UTF-16 code units, always beginning with 0.
    private let lineStarts: [Int]
    /// The end of each line's content, excluding the newline, one entry per line start.
    private let lineEnds: [Int]

    package init(_ text: String) {
        let units = Array(text.utf16)
        var starts: [Int] = [0]
        var ends: [Int] = []
        for (offset, unit) in units.enumerated() where unit == 0x0A {
            ends.append(offset)
            starts.append(offset + 1)
        }
        ends.append(units.count)
        self.lineStarts = starts
        self.lineEnds = ends
    }

    /// The range of the line containing the offset, excluding the trailing newline.
    package func lineRange(containing offset: Int) -> TextSpan {
        let index = lineIndex(containing: offset)
        return TextSpan(lowerBound: lineStarts[index], upperBound: lineEnds[index])
    }

    /// The number of the line the offset sits on, clamping out-of-range offsets to the ends.
    private func lineIndex(containing offset: Int) -> Int {
        let clamped = Swift.max(0, Swift.min(offset, lineEnds[lineEnds.count - 1]))
        var low = 0
        var high = lineStarts.count - 1
        while low < high {
            let mid = (low + high + 1) / 2
            if lineStarts[mid] <= clamped {
                low = mid
            } else {
                high = mid - 1
            }
        }
        return low
    }
}
