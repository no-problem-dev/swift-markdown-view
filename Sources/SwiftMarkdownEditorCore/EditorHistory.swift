import Foundation

/// undo/redo 履歴を純粋値型で管理する。
///
/// コミットされた編集は各々 ``Entry`` として格納される。``Entry`` は
/// 順方向変更・逆方向変更・前後のセレクションを保持するため、
/// どちら方向への移動もスタック操作＋変更適用のみで完結する
/// （CodeMirror の `history` / `prosemirror-history` が採用するトランザクション履歴モデル）。
///
/// 連続したタイプ入力の単一挿入は 1 エントリに *合成* される。
/// 1 回の undo で単語単位の入力が取り消され、
/// ウォールクロック時間に依存しないため決定論的かつテスト可能。
public struct EditorHistory: Equatable, Sendable {

    /// 1 つの可逆ステップ。
    public struct Entry: Equatable, Sendable {
        /// ドキュメントを前進させた変更（old → new）。
        public var forward: TextChange
        /// ドキュメントを巻き戻す変更（new → old）。
        public var inverse: TextChange
        /// 順方向変更適用前のセレクション。
        public var selectionBefore: Selection
        /// 順方向変更適用後のセレクション。
        public var selectionAfter: Selection
    }

    private(set) public var undoStack: [Entry] = []
    private(set) public var redoStack: [Entry] = []

    public init() {}

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    /// コミット済み編集を記録し、前のエントリへの自然な継続であれば合成する。
    ///
    /// 新しい編集を記録するとリドゥスタックがクリアされる（標準的な線形履歴の挙動）。
    ///
    /// - Parameter allowCoalescing: `false` のとき新しい履歴グループを強制する
    ///   （入力ルール変換・ペースト・セレクションジャンプ後など、個別の undo ステップとして扱う場合）。
    public mutating func record(_ entry: Entry, allowCoalescing: Bool = true) {
        redoStack.removeAll()

        if allowCoalescing,
           let previous = undoStack.last,
           Self.canCoalesce(previous: previous, next: entry) {
            undoStack[undoStack.count - 1] = Self.coalesce(previous: previous, next: entry)
        } else {
            undoStack.append(entry)
        }
    }

    /// 最新の undo エントリをポップし、redo スタックへ移す。
    public mutating func popForUndo() -> Entry? {
        guard let entry = undoStack.popLast() else { return nil }
        redoStack.append(entry)
        return entry
    }

    /// 最新の redo エントリをポップし、undo スタックへ戻す。
    public mutating func popForRedo() -> Entry? {
        guard let entry = redoStack.popLast() else { return nil }
        undoStack.append(entry)
        return entry
    }

    /// 記録されたすべての履歴を削除する。
    public mutating func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    // MARK: - Coalescing

    /// `next` が `previous` の直後に続くタイプ入力かどうか。
    private static func canCoalesce(previous: Entry, next: Entry) -> Bool {
        // Both must be pure insertions (the replaced range is empty).
        guard previous.forward.range.isEmpty, next.forward.range.isEmpty else { return false }
        // `next` must be typed immediately after `previous`'s inserted text.
        guard next.forward.range.lowerBound == previous.forward.insertedRange.upperBound else { return false }
        // Don't merge across line breaks or whitespace boundaries — these are
        // natural undo checkpoints.
        if previous.forward.replacement.last?.isNewline == true { return false }
        if next.forward.replacement.contains(where: { $0.isNewline || $0 == " " }) { return false }
        return true
    }

    /// 2 つの連続する挿入を 1 エントリにまとめる。
    private static func coalesce(previous: Entry, next: Entry) -> Entry {
        let start = previous.forward.range.lowerBound
        let combinedText = previous.forward.replacement + next.forward.replacement
        let forward = TextChange(insert: combinedText, at: start)
        let inverse = TextChange(
            range: TextSpan(location: start, length: combinedText.utf16Length),
            replacement: ""
        )
        return Entry(
            forward: forward,
            inverse: inverse,
            selectionBefore: previous.selectionBefore,
            selectionAfter: next.selectionAfter
        )
    }
}
