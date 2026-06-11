import Foundation

/// The controller that ties ``EditorState`` together with ``EditorHistory``.
///
/// This is the object the UI layer drives: it owns the current state, records
/// undo history as edits are applied, and exposes undo/redo. It deliberately
/// depends only on Foundation (no UIKit/SwiftUI) so the entire edit pipeline can
/// be unit-tested without a running text view; the TextKit layer observes it and
/// mirrors changes into the platform text view.
public final class MarkdownEditorEngine {

    /// The current editor state.
    public private(set) var state: EditorState

    /// The undo/redo history.
    public private(set) var history: EditorHistory

    /// Called after `state` changes for any reason (edit, undo, redo, external
    /// set). The UI layer uses this to re-sync the text view.
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

    /// Applies a change, recording it in history.
    ///
    /// - Parameters:
    ///   - change: The edit to apply.
    ///   - selection: The selection for the resulting state. When `nil`, the
    ///     current selection is mapped across the change.
    ///   - allowCoalescing: Whether this edit may merge with the previous undo
    ///     entry (typing). Pass `false` for rule transforms, paste, etc.
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

    /// Replaces the current selection with `text`, placing the caret after it.
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

    /// Replaces the whole document (e.g. a binding set from outside) without
    /// recording undo history. The selection is clamped into the new text.
    public func setText(_ newText: String) {
        guard newText != state.text else { return }
        let clamped = clampSelection(state.selection, to: newText.utf16Length)
        setState(EditorState(text: newText, selection: clamped))
    }

    /// Updates just the selection (e.g. the user moved the caret in the view).
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
