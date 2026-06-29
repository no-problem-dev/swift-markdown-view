import Foundation

/// ``EditorState`` と ``EditorHistory`` を結びつけるコントローラ。
///
/// UI 層が操作するオブジェクトで、現在の状態を保持し、編集のたびに undo 履歴を記録し、
/// undo/redo を公開する。Foundation のみに依存し（UIKit/SwiftUI 不要）、
/// テキストビューなしで編集パイプライン全体をユニットテストできる。
/// TextKit 層はこれを監視してプラットフォームテキストビューに変更を反映する。
public final class MarkdownEditorEngine {

    /// 現在のエディタ状態。
    public private(set) var state: EditorState

    /// undo/redo 履歴。
    public private(set) var history: EditorHistory

    /// `state` が変更されるたびに呼ばれる（編集・undo・redo・外部セット）。
    /// UI 層はこれを使ってテキストビューを再同期する。
    public var onStateChange: ((EditorState) -> Void)?

    public init(state: EditorState = EditorState(text: "")) {
        self.state = state
        self.history = EditorHistory()
    }

    public convenience init(text: String) {
        self.init(state: EditorState(text: text))
    }

    public var text: String { state.text }
    public var selection: Selection { state.selection }
    public var canUndo: Bool { history.canUndo }
    public var canRedo: Bool { history.canRedo }

    // MARK: - Editing

    /// 変更を適用し、履歴に記録する。
    ///
    /// - Parameters:
    ///   - change: 適用する編集。
    ///   - selection: 結果の状態のセレクション。`nil` のとき現在のセレクションを変更にマッピングする。
    ///   - allowCoalescing: この編集を前の undo エントリと合成してよいか（タイプ入力）。
    ///     ルール変換・ペーストなどは `false` を渡す。
    @discardableResult
    public func apply(
        _ change: TextChange,
        selection newSelection: Selection? = nil,
        allowCoalescing: Bool = true
    ) -> EditorState {
        let before = state
        let inverse = change.inverted(in: before.text)
        let next = before.applying(change, selection: newSelection)

        history.record(
            EditorHistory.Entry(
                forward: change,
                inverse: inverse,
                selectionBefore: before.selection,
                selectionAfter: next.selection
            ),
            allowCoalescing: allowCoalescing
        )

        setState(next)
        return next
    }

    /// 現在のセレクションを `text` で置換し、キャレットをその後ろに置く。
    @discardableResult
    public func replaceSelection(with text: String, allowCoalescing: Bool = true) -> EditorState {
        let range = state.selection.range
        let change = TextChange(range: range, replacement: text)
        let caret = Selection(caret: range.lowerBound + text.utf16Length)
        return apply(change, selection: caret, allowCoalescing: allowCoalescing)
    }

    // MARK: - Undo / Redo

    @discardableResult
    public func undo() -> Bool {
        guard let entry = history.popForUndo() else { return false }
        let reverted = state.applying(entry.inverse, selection: entry.selectionBefore)
        setState(reverted)
        return true
    }

    @discardableResult
    public func redo() -> Bool {
        guard let entry = history.popForRedo() else { return false }
        let redone = state.applying(entry.forward, selection: entry.selectionAfter)
        setState(redone)
        return true
    }

    // MARK: - External updates

    /// ドキュメント全体を置換する（例：外部からのバインディングセット）。undo 履歴は記録しない。
    /// セレクションは新しいテキストの範囲内にクランプされる。
    public func setText(_ newText: String) {
        guard newText != state.text else { return }
        let clamped = clampSelection(state.selection, to: newText.utf16Length)
        setState(EditorState(text: newText, selection: clamped))
    }

    /// セレクションのみ更新する（例：ユーザーがビュー内でキャレットを移動した場合）。
    public func setSelection(_ selection: Selection) {
        guard selection != state.selection else { return }
        var next = state
        next.selection = clampSelection(selection, to: state.length)
        setState(next, notify: false)
    }

    // MARK: - Private

    private func setState(_ newState: EditorState, notify: Bool = true) {
        state = newState
        if notify { onStateChange?(newState) }
    }

    private func clampSelection(_ selection: Selection, to length: Int) -> Selection {
        Selection(
            anchor: min(max(0, selection.anchor), length),
            head: min(max(0, selection.head), length)
        )
    }
}
