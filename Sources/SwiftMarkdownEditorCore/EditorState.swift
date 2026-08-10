import Foundation
import MarkdownModel

/// An immutable snapshot of the editor at one point in time.
///
/// After the `EditorState` of CodeMirror and ProseMirror, this is a pure value type holding
/// nothing but the document text and the current selection. An edit returns a *new* state
/// rather than mutating in place, which is what lets undo, decoration mapping, and eventual
/// collaborative editing all run through a single transformation pipeline.
///
/// The parsed Markdown document is *derived* from the text on demand. The plain `.md` string
/// is the single source of truth — there is no rich tree — which keeps formatting
/// round-trips safe and diffs well behaved.
public struct EditorState: Equatable, Sendable {

    /// The full text of the document, from which everything else is derived.
    public private(set) var text: String

    /// The current selection, in UTF-16 code unit offsets into the document text.
    ///
    /// Nothing here clamps it to the document length.
    public var selection: Selection

    /// Creates an editor state.
    ///
    /// - Parameters:
    ///   - text: The document text.
    ///   - selection: The initial selection. Defaults to a caret at the end of the text.
    public init(text: String, selection: Selection? = nil) {
        self.text = text
        self.selection = selection ?? Selection(caret: text.utf16Length)
    }

    /// The length of the document, in UTF-16 code units.
    public var length: Int { text.utf16Length }

    /// Parses the text with the shared parser and returns the blocks to render.
    ///
    /// Reusing the parser from `SwiftMarkdownView` keeps the editor and the renderer in
    /// agreement about document structure. The result is computed on demand, so cache it if
    /// you render on every keystroke.
    public func parsedContent() -> MarkdownContent {
        MarkdownContent(parsing: text)
    }

    // MARK: - Transforms

    /// Returns a new state with the change applied and the selection mapped or replaced.
    ///
    /// - Parameters:
    ///   - change: The edit to apply.
    ///   - newSelection: An explicit selection for the new state. When `nil`, the current
    ///     selection is mapped across the change, which for typing moves the caret to the
    ///     right of the inserted text.
    public func applying(_ change: TextChange, selection newSelection: Selection? = nil) -> EditorState {
        var next = self
        next.text = change.apply(to: text)
        next.selection = newSelection ?? change.mapSelection(selection)
        return next
    }

    /// Returns a new state with the range replaced and the caret left after the new text.
    ///
    /// The caret is derived from the range exactly as passed in. A range whose lower bound
    /// cuts a grapheme cluster is widened when the replacement is applied, but the caret is
    /// not adjusted to follow, so pass a span already aligned to character boundaries — see
    /// ``TextChange/aligned(in:)``.
    public func replacing(_ range: TextSpan, with replacement: String) -> EditorState {
        let change = TextChange(range: range, replacement: replacement)
        let caret = range.lowerBound + replacement.utf16Length
        return applying(change, selection: Selection(caret: caret))
    }

    /// Returns a new state with the current selection replaced by the given text.
    public func replacingSelection(with replacement: String) -> EditorState {
        replacing(selection.range, with: replacement)
    }
}
