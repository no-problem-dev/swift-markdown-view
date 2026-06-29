import Foundation
import SwiftMarkdownEditorCore

/// ``InputRule`` の順序付きリストを実行し、最初にマッチしたものを返す。
public struct InputRuleProcessor: Sendable {

    public var rules: [any InputRule]

    public init(rules: [any InputRule]) {
        self.rules = rules
    }

    /// デフォルトの Phase 1 ルールセット：リスト継続＋スマートラッピング。
    public static var standard: InputRuleProcessor {
        InputRuleProcessor(rules: [
            ListContinuationRule(),
            WrapSelectionRule()
        ])
    }

    /// この入力を処理する最初のルールの変換を返す。該当するルールがない場合は `nil`。
    public func transform(
        state: EditorState,
        inserting text: String,
        replacing range: TextSpan
    ) -> RuleTransform? {
        for rule in rules {
            if let result = rule.transform(state: state, inserting: text, replacing: range) {
                return result
            }
        }
        return nil
    }
}
