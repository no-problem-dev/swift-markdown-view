import Testing
import SwiftMarkdownEditorCore
@testable import SwiftMarkdownEditorRules

struct InputRuleTests {

    private let processor = InputRuleProcessor.standard

    /// Applies the standard rules to an Enter press at `caret` in `text`.
    private func pressEnter(_ text: String, at caret: Int) -> (text: String, caret: Int)? {
        let state = EditorState(text: text, selection: Selection(caret: caret))
        guard let t = processor.transform(state: state, inserting: "\n", replacing: TextSpan(caret: caret)) else {
            return nil
        }
        let newText = t.change.apply(to: text)
        return (newText, t.selection.head)
    }

    /// Applies the standard rules to typing `delim` over a selection.
    private func wrap(_ text: String, selecting range: TextSpan, with delim: String) -> (text: String, selection: Selection)? {
        let state = EditorState(text: text, selection: Selection(range: range))
        guard let t = processor.transform(state: state, inserting: delim, replacing: range) else {
            return nil
        }
        return (t.change.apply(to: text), t.selection)
    }

    // MARK: - List continuation

    @Test("Enter continues a bullet list")
    func continueBullet() {
        let result = pressEnter("- apple", at: 7)
        #expect(result?.text == "- apple\n- ")
        #expect(result?.caret == 10)
    }

    @Test("Enter continues a star bullet preserving the bullet char")
    func continueStarBullet() {
        let result = pressEnter("* one", at: 5)
        #expect(result?.text == "* one\n* ")
    }

    @Test("Enter increments an ordered list")
    func continueOrdered() {
        let result = pressEnter("1. first", at: 8)
        #expect(result?.text == "1. first\n2. ")
    }

    @Test("Ordered list keeps a high starting number incrementing")
    func continueOrderedHigh() {
        let result = pressEnter("9. nine", at: 7)
        #expect(result?.text == "9. nine\n10. ")
    }

    @Test("Enter continues a task list with an unchecked box")
    func continueTask() {
        let result = pressEnter("- [x] done", at: 10)
        #expect(result?.text == "- [x] done\n- [ ] ")
    }

    @Test("Enter preserves indentation")
    func continueIndented() {
        let result = pressEnter("  - nested", at: 10)
        #expect(result?.text == "  - nested\n  - ")
    }

    @Test("Enter on an empty bullet exits the list")
    func exitEmptyBullet() {
        // "- " then Enter → blank line.
        let result = pressEnter("- ", at: 2)
        #expect(result?.text == "")
        #expect(result?.caret == 0)
    }

    @Test("Enter on an empty ordered item exits the list")
    func exitEmptyOrdered() {
        let result = pressEnter("1. ", at: 3)
        #expect(result?.text == "")
    }

    @Test("Enter on a non-list line is not handled")
    func notAList() {
        #expect(pressEnter("just text", at: 9) == nil)
    }

    @Test("List continuation works mid-document")
    func continueMidDocument() {
        let text = "intro\n\n- a\n\nmore"
        // caret at end of "- a" (offset 10)
        let result = pressEnter(text, at: 10)
        #expect(result?.text == "intro\n\n- a\n- \n\nmore")
    }

    // MARK: - Smart wrapping

    @Test("Typing * over a selection wraps it in emphasis")
    func wrapEmphasis() {
        let result = wrap("a word b", selecting: TextSpan(location: 2, length: 4), with: "*")
        #expect(result?.text == "a *word* b")
        // Inner text stays selected.
        #expect(result?.selection == Selection(anchor: 3, head: 7))
    }

    @Test("Typing backtick over a selection wraps it in code")
    func wrapCode() {
        let result = wrap("call foo now", selecting: TextSpan(location: 5, length: 3), with: "`")
        #expect(result?.text == "call `foo` now")
    }

    @Test("Typing a non-delimiter over a selection is not handled")
    func noWrapForNormalChar() {
        #expect(wrap("a word b", selecting: TextSpan(location: 2, length: 4), with: "x") == nil)
    }

    @Test("Wrapping requires a non-empty selection")
    func noWrapWithoutSelection() {
        let state = EditorState(text: "abc", selection: Selection(caret: 1))
        #expect(processor.transform(state: state, inserting: "*", replacing: TextSpan(caret: 1)) == nil)
    }
}
