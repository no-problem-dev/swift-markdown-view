import Foundation
import SwiftMarkdownView

/// The immutable state of the editor at a point in time.
///
/// Following CodeMirror's `EditorState`/ProseMirror's `EditorState`, this is a
/// pure value: the document text plus the current selection. All edits produce
/// a *new* `EditorState` rather than mutating in place, which keeps undo,
/// decoration mapping, and (future) collaboration on a single well-defined
/// transform pipeline.
///
/// The parsed Markdown document is *derived* from `text` on demand — the plain
/// `.md` string is always the single source of truth (never a rich tree), which
/// is what keeps the format round-trip-safe and diff-friendly.
public struct EditorState: Equatable, Sendable {

    /// The full document text (the source of truth).
    public private(set) var text: String

    /// The current selection over `text`.
    public var selection: Selection

    /// Creates an editor state.
    ///
    /// - Parameters:
    ///   - text: The document text.
    ///   - selection: The selection. Defaults to a caret at the end of the text.
    public init(text: String, selection: Selection? = nil) {
        self.text = text
        self.selection = selection ?? Selection(caret: text.utf16Length)
    }

    /// The document length in UTF-16 code units.
    public var length: Int { text.utf16Length }

    /// Parses `text` into render-ready blocks using the shared parser.
    ///
    /// This reuses `SwiftMarkdownView`'s parser so the editor and the renderer
    /// always agree on structure. It is computed on demand; callers that render
    /// every keystroke should cache the result.
    public func parsedContent() -> MarkdownContent {
        MarkdownContent(parsing: text)
    }

    // MARK: - Transforms

    /// Returns a new state with `change` applied and the selection mapped or
    /// replaced.
    ///
    /// - Parameters:
    ///   - change: The edit to apply.
    ///   - selection: An explicit selection for the new state. When `nil`, the
    ///     current selection is mapped across the change (typing pushes the
    ///     caret to the right of inserted text).
    public func applying(_ change: TextChange, selection newSelection: Selection? = nil) -> EditorState {
        var next = self
        next.text = change.apply(to: text)
        next.selection = newSelection ?? change.mapSelection(selection)
        return next
    }

    /// Convenience: replace `range` with `replacement`, placing the caret after
    /// the inserted text.
    public func replacing(_ range: TextSpan, with replacement: String) -> EditorState {
        let change = TextChange(range: range, replacement: replacement)
        let caret = range.lowerBound + replacement.utf16Length
        return applying(change, selection: Selection(caret: caret))
    }

    /// Convenience: replace the current selection with `replacement`.
    public func replacingSelection(with replacement: String) -> EditorState {
        replacing(selection.range, with: replacement)
    }
}
