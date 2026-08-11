import Foundation
import SwiftMarkdownEditorCore

/// The transformation an input rule applies in place of the ordinary insertion.
public struct RuleTransform: Equatable, Sendable {
    /// The change to apply instead of the user's raw insertion.
    public var change: TextChange
    /// Where the selection lands once the change has been applied.
    public var selection: Selection

    public init(change: TextChange, selection: Selection) {
        self.change = change
        self.selection = selection
    }
}

/// A rule that rewrites the user's text input, which is how Markdown autoformatting works.
///
/// Modelled on ProseMirror's input rules. Implement this to add your own autoformatting: the rule
/// is asked about every insertion, before it happens, and may answer with a ``RuleTransform`` to
/// apply in place of what the user typed.
///
/// Rules run in the order the ``InputRuleProcessor`` holds them and the first match wins, so
/// returning `nil` means "not mine" and lets the next rule decide. A rule is a pure function of its
/// input, which is what makes the whole autoformatting layer unit testable without a text view.
///
/// ```swift
/// struct EmDashRule: InputRule {
///     func transform(state: EditorState, inserting text: String, replacing range: TextSpan) -> RuleTransform? {
///         guard text == "-", range.isEmpty, range.lowerBound > 0 else { return nil }
///         let previous = TextSpan(lowerBound: range.lowerBound - 1, upperBound: range.lowerBound)
///         guard state.text.substring(in: previous) == "-" else { return nil }
///         return RuleTransform(
///             change: TextChange(range: previous, replacement: "—"),
///             selection: Selection(caret: previous.lowerBound + 1)
///         )
///     }
/// }
/// ```
public protocol InputRule: Sendable {
    /// Asks the rule what to do about an insertion that is about to happen.
    ///
    /// - Parameters:
    ///   - state: The state *before* the insertion.
    ///   - text: The text the user is inserting — a typed character, a newline, or a paste.
    ///   - range: The range the insertion replaces, empty at a caret.
    /// - Returns: The transformation to apply instead, or `nil` to let the next rule handle it.
    func transform(state: EditorState, inserting text: String, replacing range: TextSpan) -> RuleTransform?
}
