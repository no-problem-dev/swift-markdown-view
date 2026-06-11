import Foundation
import SwiftMarkdownEditorCore

/// Wraps the current selection when a delimiter is typed over it.
///
/// Selecting `word` and pressing `*` yields `*word*` with the inner text kept
/// selected — the "smart wrapping" behavior of Bear/Typora/Ulysses. The toolbar
/// provides multi-character wraps (e.g. `**` for bold) explicitly; this rule
/// covers the single-character delimiters typed directly.
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
