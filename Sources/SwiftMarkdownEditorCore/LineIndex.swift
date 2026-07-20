import Foundation

/// ドキュメントの行境界を一度だけ求めて保持し、以降の行範囲問い合わせを二分探索で答える。
///
/// `String.lineRange(containing:)` は呼び出しのたびに `Array(utf16)` で全文を複製する。
/// 1 回だけなら問題ないが、ライブプレビューはインラインスパン 1 件につき 1 回呼ぶため、
/// 文書長 × スパン数 ＝ 実質二次に膨らむ。打鍵ごとにこれが走るので、長い文書では
/// 1 打鍵が数秒になる。同じ文書を何度も走査する呼び出し側はこの型を使うこと。
public struct LineIndex: Sendable {

    /// 各行の開始位置（UTF-16 オフセット）。常に 0 から始まる。
    private let lineStarts: [Int]
    /// 各行の内容の終端（改行を含まない）。`lineStarts` と同じ要素数。
    private let lineEnds: [Int]

    public init(_ text: String) {
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

    /// `offset` を含む行の範囲（末尾の改行は含まない）。
    public func lineRange(containing offset: Int) -> TextSpan {
        let index = lineIndex(containing: offset)
        return TextSpan(lowerBound: lineStarts[index], upperBound: lineEnds[index])
    }

    /// `offset` が乗っている行の番号。範囲外は端にクランプする。
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
