import Foundation

/// Undo/redo history as a pure value type.
///
/// Each committed edit is stored as an ``Entry`` holding both the forward change
/// and its inverse plus the selections on each side, so stepping in either
/// direction is a simple stack move + change application (this is the
/// transaction-history model used by CodeMirror's `history` and
/// `prosemirror-history`).
///
/// Consecutive single insertions from typing are *coalesced* into one entry so
/// that one undo removes a word's worth of typing rather than one character —
/// without depending on wall-clock time, which keeps it deterministic and
/// testable.
public struct EditorHistory: Equatable, Sendable {

    /// One reversible step in the history.
    public struct Entry: Equatable, Sendable {
        /// The change that moved the document forward (old → new).
        public var forward: TextChange
        /// The change that moves the document back (new → old).
        public var inverse: TextChange
        /// The selection before the forward change was applied.
        public var selectionBefore: Selection
        /// The selection after the forward change was applied.
        public var selectionAfter: Selection
    }

    private(set) public var undoStack: [Entry] = []
    private(set) public var redoStack: [Entry] = []

    public init() {}

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    /// Records a committed edit, coalescing with the previous entry when it is a
    /// natural continuation of typing.
    ///
    /// Recording any new edit clears the redo stack (the standard linear-history
    /// behavior).
    ///
    /// - Parameter allowCoalescing: When `false`, forces a new history group
    ///   (used after input-rule transforms, paste, or selection jumps so they
    ///   undo as discrete steps).
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

    /// Pops the most recent undo entry and moves it onto the redo stack.
    public mutating func popForUndo() -> Entry? {
        guard let entry = undoStack.popLast() else { return nil }
        redoStack.append(entry)
        return entry
    }

    /// Pops the most recent redo entry and moves it back onto the undo stack.
    public mutating func popForRedo() -> Entry? {
        guard let entry = redoStack.popLast() else { return nil }
        undoStack.append(entry)
        return entry
    }

    /// Drops all recorded history.
    public mutating func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }

    // MARK: - Coalescing

    /// Whether `next` is a continuation of typing immediately after `previous`.
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

    /// Merges two contiguous insertions into a single entry.
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
