import Foundation

/// UTF-16 オフセット上の行境界ユーティリティ。
///
/// 入力ルールと TextKit 層は「キャレットが乗っている行」を頻繁に必要とする。
/// これらのヘルパーはドキュメント全体の行ごとの部分文字列を確保せずに行範囲を計算する。
public extension String {

    /// `offset` を含む行の範囲（末尾の改行は含まない）。オフセットは UTF-16 コードユニット。
    func lineRange(containing offset: Int) -> TextSpan {
        let units = Array(utf16)
        let clamped = Swift.max(0, Swift.min(offset, units.count))

        var start = clamped
        while start > 0 && units[start - 1] != 0x0A { start -= 1 }

        var end = clamped
        while end < units.count && units[end] != 0x0A { end += 1 }

        return TextSpan(lowerBound: start, upperBound: end)
    }

    /// `offset` を含む行のテキスト（改行は含まない）。
    func line(containing offset: Int) -> String {
        substring(in: lineRange(containing: offset))
    }
}
