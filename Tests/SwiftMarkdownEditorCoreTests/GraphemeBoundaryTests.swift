import Testing
@testable import SwiftMarkdownEditorCore

/// 書記素クラスタの途中を指すオフセットで編集が黙って壊れないことの検証。
///
/// `String.Index(utf16Offset:in:)` はサロゲートペアの片割れを指すインデックスを作れるが、
/// `replaceSubrange` はそれを文字境界へ丸める。丸めに気づかないと「削除したはずの範囲が
/// 削除されていないのに長さは減ったと報告される」状態になり、以降の位置写像と undo が
/// すべて実テキストとずれる。
@Suite("書記素境界の扱い")
struct GraphemeBoundaryTests {

    private let emoji = "a👍b"   // utf16: a=1, 👍=2, b=1 → 全長 4

    @Test("サロゲートペアの途中を指す範囲は文字を丸ごと含む")
    func substringSnapsOutward() {
        // 0..<2 は「a + 高サロゲート」。分割できないので 👍 を丸ごと含める。
        #expect(emoji.substring(in: TextSpan(lowerBound: 0, upperBound: 2)) == "a👍")
    }

    @Test("サロゲートペアの途中を指す置換が実際に削除を行う")
    func applyActuallyReplaces() {
        let change = TextChange(range: TextSpan(lowerBound: 1, upperBound: 2), replacement: "Z")
        // 修正前は "aZ👍b"（何も削除されず純粋な挿入になっていた）。
        #expect(change.apply(to: emoji) == "aZb")
    }

    @Test("aligned で長さ計算と実テキストが一致する")
    func alignedKeepsLengthConsistent() {
        let raw = TextChange(range: TextSpan(lowerBound: 1, upperBound: 2), replacement: "Z")
        let aligned = raw.aligned(in: emoji)
        #expect(aligned.range == TextSpan(lowerBound: 1, upperBound: 3))
        #expect(aligned.lengthDelta == -1)
        #expect(aligned.apply(to: emoji).utf16Length == emoji.utf16Length + aligned.lengthDelta)
    }

    @Test("境界に揃った範囲は aligned で変化しない")
    func alignedIsIdentityWhenAlreadyAligned() {
        let change = TextChange(range: TextSpan(lowerBound: 1, upperBound: 3), replacement: "Z")
        #expect(change.aligned(in: emoji) == change)
    }

    @Test("結合文字の途中も外側へ寄せる")
    func combiningMarkSnapsOutward() {
        let combining = "e\u{0301}f"   // e + 結合アキュート + f
        // 1 は e と結合記号の間。分割できない。
        #expect(combining.substring(in: TextSpan(lowerBound: 0, upperBound: 1)) == "e\u{0301}")
    }

    @Test("ASCII のみの文字列は従来どおり")
    func asciiIsUnaffected() {
        let plain = "hello"
        #expect(plain.substring(in: TextSpan(lowerBound: 1, upperBound: 3)) == "el")
        let change = TextChange(range: TextSpan(lowerBound: 1, upperBound: 3), replacement: "X")
        #expect(change.apply(to: plain) == "hXlo")
        #expect(change.aligned(in: plain) == change)
    }

    @Test("末尾を越えるオフセットは従来どおりクランプされる")
    func outOfRangeStillClamps() {
        // 負のオフセットは TextSpan が precondition で弾くので、上端だけを確認する。
        #expect(emoji.substring(in: TextSpan(lowerBound: 0, upperBound: 99)) == emoji)
        #expect(emoji.substring(in: TextSpan(lowerBound: 4, upperBound: 99)) == "")
    }
}
