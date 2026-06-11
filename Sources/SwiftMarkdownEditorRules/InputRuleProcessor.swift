import Foundation
import SwiftMarkdownEditorCore

/// Runs an ordered list of ``InputRule``s and returns the first match.
public struct InputRuleProcessor: Sendable {

    public var rules: [any InputRule]

    public init(rules: [any InputRule]) {
        self.rules = rules
    }

    /// The default Phase 1 rule set: list continuation + smart wrapping.
    public static var standard: InputRuleProcessor {
        InputRuleProcessor(rules: [
            ListContinuationRule(),
            WrapSelectionRule()
        ])
    }

    /// Returns the transform of the first rule that handles this input, if any.
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
