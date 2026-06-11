import Foundation
import SwiftMarkdownEditorCore

/// A transform an input rule wants to perform *instead of* the plain insertion.
public struct RuleTransform: Equatable, Sendable {
    /// The change to apply in place of the user's raw insertion.
    public var change: TextChange
    /// The selection for the resulting state.
    public var selection: Selection
    /// Whether the resulting undo entry may coalesce with neighbors. Rule edits
    /// are usually discrete undo steps, so this defaults to `false`.
    public var allowCoalescing: Bool

    public init(change: TextChange, selection: Selection, allowCoalescing: Bool = false) {
        self.change = change
        self.selection = selection
        self.allowCoalescing = allowCoalescing
    }
}

/// A rule that can rewrite a user's text input — Markdown autoformatting.
///
/// Modeled on ProseMirror's input rules: given the state and the text about to
/// be inserted over `range`, a rule may return a ``RuleTransform`` to apply
/// instead. Rules are pure functions of their inputs, which keeps the whole
/// autoformatting layer unit-testable without a text view.
public protocol InputRule: Sendable {
    /// - Parameters:
    ///   - state: The state *before* the insertion.
    ///   - text: The text the user is inserting (a typed char, a newline, a paste).
    ///   - range: The range the insertion replaces (empty at a caret).
    /// - Returns: A transform to apply instead, or `nil` to not handle this input.
    func transform(state: EditorState, inserting text: String, replacing range: TextSpan) -> RuleTransform?
}
