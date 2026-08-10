import Foundation
import SwiftMarkdownEditorCore

/// Wraps the selection in a delimiter when the user types that delimiter over it.
///
/// Selecting `word` and pressing `*` gives `*word*` with the inner text still selected — the "smart
/// wrapping" behaviour of Bear, Typora and Ulysses. Multi-character wrapping, such as `**` for bold,
/// is offered explicitly by the toolbar; this rule covers the single characters a user types
/// directly.
public struct WrapSelectionRule: InputRule {

    /// The single-character delimiters that trigger wrapping.
    public var delimiters: Set<String>

    public init(delimiters: Set<String> = ["*", "_", "`"]) {
        self.delimiters = delimiters
    }

    public func transform(
        state: EditorState,
        inserting text: String,
        replacing range: TextSpan
    ) -> RuleTransform? {
        guard !range.isEmpty, delimiters.contains(text) else { return nil }

        let selected = state.text.substring(in: range)
        let replacement = text + selected + text
        let change = TextChange(range: range, replacement: replacement)

        let innerStart = range.lowerBound + text.utf16Length
        let selection = Selection(anchor: innerStart, head: innerStart + selected.utf16Length)

        return RuleTransform(change: change, selection: selection)
    }
}
