import Foundation

/// エディタコアが共有する UTF-16 オフセット変換ヘルパー。
///
/// エディタモデル全体は UTF-16 コードユニットオフセット（``TextSpan`` 参照）でテキストを扱う。
/// Swift の `String` 変更は `String.Index` で動作するため、
/// これらのヘルパーは範囲外オフセットをバッファ境界にクランプしながら安全に変換する。
public extension String {

    /// 文字列の UTF-16 コードユニット数。
    var utf16Length: Int { utf16.count }

    /// UTF-16 オフセットに対応する `String.Index` を返す。有効境界にクランプする。
    func index(utf16Offset offset: Int) -> String.Index {
        let clamped = Swift.max(0, Swift.min(offset, utf16Length))
        return String.Index(utf16Offset: clamped, in: self)
    }

    /// ``TextSpan`` に対応する `Range<String.Index>` を返す。境界にクランプする。
    func range(for textRange: TextSpan) -> Range<String.Index> {
        index(utf16Offset: textRange.lowerBound) ..< index(utf16Offset: textRange.upperBound)
    }

    /// ``TextSpan`` が示す部分文字列を返す。
    func substring(in textRange: TextSpan) -> String {
        String(self[range(for: textRange)])
    }
}
