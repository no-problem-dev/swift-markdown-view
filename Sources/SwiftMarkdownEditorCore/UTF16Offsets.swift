import Foundation

/// エディタコアが共有する UTF-16 オフセット変換ヘルパー。
///
/// エディタモデル全体は UTF-16 コードユニットオフセット（``TextSpan`` 参照）でテキストを扱う。
/// Swift の `String` 変更は `String.Index` で動作するため、これらのヘルパーが変換する。
///
/// オフセットが書記素クラスタの途中（サロゲートペアの片割れ・結合文字の間）を指す場合は、
/// 分割できないので**外側の文字境界へ寄せる**。寄せずに `String.Index(utf16Offset:in:)` を
/// そのまま使うと、`replaceSubrange` 側で境界に丸められた結果、削除したはずの範囲が
/// 削除されない（`"a👍b"` の 1..<2 を置換すると純粋な挿入になる）。長さの計算とテキストの
/// 実体が食い違い、以降の位置写像と undo がすべてずれる。
public extension String {

    /// 文字列の UTF-16 コードユニット数。
    var utf16Length: Int { utf16.count }

    /// UTF-16 オフセットに対応する `String.Index` を返す。
    ///
    /// - Parameter roundingUp: 書記素クラスタの途中を指していたとき、後ろ側の境界へ寄せる。
    ///   範囲の下端は `false`（前へ）、上端は `true`（後ろへ）を使う。
    func index(utf16Offset offset: Int, roundingUp: Bool = false) -> String.Index {
        let clamped = Swift.max(0, Swift.min(offset, utf16Length))
        let raw = String.Index(utf16Offset: clamped, in: self)
        guard raw.samePosition(in: self) == nil else { return raw }
        let enclosing = rangeOfComposedCharacterSequence(at: raw)
        return roundingUp ? enclosing.upperBound : enclosing.lowerBound
    }

    /// ``TextSpan`` に対応する `Range<String.Index>` を返す。
    ///
    /// 下端は前、上端は後ろへ寄せるので、境界を割った範囲は文字を丸ごと含む形に広がる。
    func range(for textRange: TextSpan) -> Range<String.Index> {
        let lower = index(utf16Offset: textRange.lowerBound, roundingUp: false)
        let upper = index(utf16Offset: textRange.upperBound, roundingUp: true)
        return lower ..< Swift.max(lower, upper)
    }

    /// ``TextSpan`` が示す部分文字列を返す。
    func substring(in textRange: TextSpan) -> String {
        String(self[range(for: textRange)])
    }

    /// ``TextSpan`` を、この文字列の文字境界に揃えた範囲へ正規化する。
    ///
    /// オフセットを算術で組み立てた場合（外部から渡された値・長さの加減算）は、
    /// モデルに入れる前にこれを通すこと。`TextChange` の長さ計算と実際の置換結果が
    /// 食い違わなくなる。
    func alignedSpan(_ textRange: TextSpan) -> TextSpan {
        let range = range(for: textRange)
        return TextSpan(
            lowerBound: range.lowerBound.utf16Offset(in: self),
            upperBound: range.upperBound.utf16Offset(in: self)
        )
    }
}
