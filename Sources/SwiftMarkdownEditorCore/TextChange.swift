import Foundation

/// 編集境界上の位置をどう変換するかの指定。
///
/// CodeMirror の `assoc` / ProseMirror の `bias` に相当する。
/// ある位置にテキストが挿入されるとき、その位置にあるキャレットは
/// 挿入の前（`.left`）か後（`.right`）に留まる。
/// タイプ入力ではキャレットを入力テキストの右に押し出すため `.right` がデフォルト。
public enum AssociationBias: Sendable {
    case left
    case right
}

/// 単一のアトミックな編集：旧テキストの `range` を `replacement` で置換する。
///
/// エディタの変更単位（CodeMirror の `ChangeSpec` / ProseMirror の `ReplaceStep`）。
/// 純粋値として文字列に適用でき、保存済みの位置（キャレット・デコレーション）を
/// 変更にマッピングでき、undo のために逆変換できる。
public struct TextChange: Equatable, Sendable {

    /// 置換対象の **旧テキスト** における範囲（UTF-16 オフセット）。
    public var range: TextSpan

    /// `range` の位置に挿入するテキスト。
    public var replacement: String

    public init(range: TextSpan, replacement: String) {
        self.range = range
        self.replacement = replacement
    }

    /// キャレットオフセット位置への挿入を作成する。
    public init(insert text: String, at offset: Int) {
        self.init(range: TextSpan(caret: offset), replacement: text)
    }

    /// 挿入テキストの長さ（UTF-16 コードユニット数）。
    public var insertedLength: Int { replacement.utf16Length }

    /// この編集によるドキュメント長の符号付き変化量。
    public var lengthDelta: Int { insertedLength - range.length }

    /// **新テキスト** における置換後テキストの範囲。
    public var insertedRange: TextSpan {
        TextSpan(location: range.lowerBound, length: insertedLength)
    }

    // MARK: - Apply

    /// この変更を適用した `text` を返す。
    public func apply(to text: String) -> String {
        var result = text
        result.replaceSubrange(text.range(for: range), with: replacement)
        return result
    }

    // MARK: - Position mapping

    /// 旧テキスト上のオフセットを新テキスト上の対応するオフセットにマッピングする。
    ///
    /// - 編集より前の位置は変化しない。
    /// - 編集より後の位置は `lengthDelta` だけシフトする。
    /// - 置換範囲の厳密な内部にある位置は挿入の開始（`.left`）または終端（`.right`）に折り畳まれる。
    /// - 編集開始位置に正確に一致する位置は `.left` でそのまま、`.right` で挿入終端に移動する。
    public func mapOffset(_ offset: Int, bias: AssociationBias = .right) -> Int {
        if offset < range.lowerBound { return offset }
        if offset > range.upperBound { return offset + lengthDelta }
        // offset is within [lowerBound, upperBound]
        switch bias {
        case .left:
            return range.lowerBound
        case .right:
            return range.lowerBound + insertedLength
        }
    }

    /// この変更にわたってセレクションをマッピングし、方向を保持する。
    public func mapSelection(_ selection: Selection, bias: AssociationBias = .right) -> Selection {
        Selection(
            anchor: mapOffset(selection.anchor, bias: bias),
            head: mapOffset(selection.head, bias: bias)
        )
    }

    // MARK: - Invert

    /// この変更を取り消す逆変換を返す。
    ///
    /// 逆変換は置換されたバイト列を復元する必要があるため、元のテキストが必要。
    public func inverted(in oldText: String) -> TextChange {
        let replaced = oldText.substring(in: range)
        return TextChange(range: insertedRange, replacement: replaced)
    }
}
