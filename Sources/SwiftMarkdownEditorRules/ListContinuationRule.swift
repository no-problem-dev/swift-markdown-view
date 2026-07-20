import Foundation
import SwiftMarkdownEditorCore

/// リストアイテム内で Enter を押したときに Markdown リストを継続する。
///
/// - 空でないアイテムでは改行を挿入し、マーカーを引き継ぐ
///   （順序付きリストでは番号をインクリメントし、タスクチェックボックスは未チェックにリセット）。
/// - *空* のアイテム（マーカーのみ）では Enter でマーカーを削除してアウトデント —
///   「Enter を 2 回押してリストを抜ける」という普遍的な挙動。
public struct ListContinuationRule: InputRule {

    public init() {}

    public func transform(
        state: EditorState,
        inserting text: String,
        replacing range: TextSpan
    ) -> RuleTransform? {
        // Only fires on a plain Enter at a caret.
        guard text == "\n", range.isEmpty else { return nil }
        let caret = range.lowerBound

        // フェンスコードの中ではリスト記法はただの文字列。マーカーを自動挿入すると
        // ユーザーが書いているコードが書き換わる。
        guard !MarkdownTokenizer.isInsideFencedCode(state.text, offset: caret) else { return nil }

        let lineRange = state.text.lineRange(containing: caret)
        let line = state.text.substring(in: lineRange)
        guard let prefix = ListPrefix.parse(line) else { return nil }

        let lineStart = lineRange.lowerBound
        let contentStartGlobal = lineStart + prefix.contentStart
        let contentEndGlobal = lineRange.upperBound

        // キャレットがマーカーより前にあるなら、これは「項目の継続」ではなく行の分割。
        // 内容の有無だけで判定すると、行頭で Enter を押したときにマーカーが二重になる。
        guard caret >= contentStartGlobal else { return nil }

        let content = state.text.substring(in: TextSpan(lowerBound: contentStartGlobal, upperBound: contentEndGlobal))
        let isEmptyItem = content.trimmingCharacters(in: .whitespaces).isEmpty

        if isEmptyItem {
            // Exit the list: clear the marker on this line, place caret at line start.
            let change = TextChange(
                range: TextSpan(lowerBound: lineStart, upperBound: lineRange.upperBound),
                replacement: ""
            )
            return RuleTransform(change: change, selection: Selection(caret: lineStart))
        }

        // Continue the list: newline + the next marker.
        let nextMarker = prefix.nextMarker()
        let insertion = "\n" + nextMarker
        let change = TextChange(insert: insertion, at: caret)
        let caretAfter = caret + insertion.utf16Length
        return RuleTransform(change: change, selection: Selection(caret: caretAfter))
    }
}

/// リストアイテム行の先頭マーカーのパース結果。
struct ListPrefix {

    enum Kind {
        case bullet(Character)            // -, *, +
        case ordered(number: Int, delimiter: Character) // 1. / 1)
    }

    var indentation: String
    var kind: Kind
    var hasCheckbox: Bool
    /// アイテムコンテンツが始まる行内の UTF-16 オフセット。
    var contentStart: Int

    /// 次のアイテムを開始するマーカーを構築する（番号インクリメント・チェックボックスリセット）。
    func nextMarker() -> String {
        var marker = indentation
        switch kind {
        case .bullet(let ch):
            marker.append(ch)
        case .ordered(let number, let delimiter):
            marker += "\(number + 1)"
            marker.append(delimiter)
        }
        marker += " "
        if hasCheckbox { marker += "[ ] " }
        return marker
    }

    /// `line` の先頭のリストマーカーをパースする。該当しない場合は `nil`。
    static func parse(_ line: String) -> ListPrefix? {
        let u = Array(line.utf16)
        var i = 0

        // Indentation.
        while i < u.count && (u[i] == 0x20 || u[i] == 0x09) { i += 1 }
        let indentEnd = i
        guard i < u.count else { return nil }

        let c = u[i]
        var kind: Kind
        if c == 0x2D || c == 0x2A || c == 0x2B { // - * +
            // Must be followed by a space to be a list item.
            guard i + 1 < u.count, u[i + 1] == 0x20 else { return nil }
            kind = .bullet(Character(UnicodeScalar(c)!))
            i += 2
        } else if c >= 0x30 && c <= 0x39 { // digit
            var numEnd = i
            while numEnd < u.count && u[numEnd] >= 0x30 && u[numEnd] <= 0x39 { numEnd += 1 }
            guard numEnd < u.count, u[numEnd] == 0x2E || u[numEnd] == 0x29 else { return nil } // . or )
            let delimiterIndex = numEnd
            guard delimiterIndex + 1 < u.count, u[delimiterIndex + 1] == 0x20 else { return nil }
            let digits = u[i..<numEnd].map { Character(UnicodeScalar($0)!) }
            let number = Int(String(digits)) ?? 1
            kind = .ordered(number: number, delimiter: Character(UnicodeScalar(u[delimiterIndex])!))
            i = delimiterIndex + 2
        } else {
            return nil
        }

        // Optional task checkbox.
        var hasCheckbox = false
        if i + 3 <= u.count, u[i] == 0x5B, u[i + 2] == 0x5D { // [ _ ]
            let mid = u[i + 1]
            if mid == 0x20 || mid == 0x78 || mid == 0x58 { // space, x, X
                hasCheckbox = true
                i += 3
                if i < u.count && u[i] == 0x20 { i += 1 } // consume trailing space
            }
        }

        let indentation = String(decoding: Array(u[0..<indentEnd]), as: UTF16.self)
        return ListPrefix(indentation: indentation, kind: kind, hasCheckbox: hasCheckbox, contentStart: i)
    }
}
