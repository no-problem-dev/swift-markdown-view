import Foundation
import SwiftMarkdownEditorCore

/// セレクション上でデリミタをタイプしたとき、セレクションをデリミタで囲む。
///
/// `word` を選択して `*` を押すと `*word*` になり内側のテキストが選択状態を維持する
/// （Bear/Typora/Ulysses の「スマートラッピング」挙動）。
/// ツールバーは複数文字の囲み（例：太字の `**`）を明示的に提供し、
/// このルールは直接タイプする単一文字デリミタを担当する。
public struct WrapSelectionRule: InputRule {

    /// ラッピングを発火させる単一文字デリミタ。
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
