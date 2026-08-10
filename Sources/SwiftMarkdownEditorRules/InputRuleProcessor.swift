import Foundation
import SwiftMarkdownEditorCore

/// Runs an ordered list of input rules and takes the first match.
///
/// Each rule is an ``InputRule``; the order they are given in is the order they are tried.
public struct InputRuleProcessor: Sendable {

    public var rules: [any InputRule]

    public init(rules: [any InputRule]) {
        self.rules = rules
    }

    /// The default rule set: list continuation, then smart wrapping.
    public static var standard: InputRuleProcessor {
        InputRuleProcessor(rules: [
            ListContinuationRule(),
            WrapSelectionRule()
        ])
    }

    /// The transformation from the first rule that claims this input, or `nil` if none do.
    ///
    /// Rules are tried in order and later rules never see an input an earlier one has claimed.
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
