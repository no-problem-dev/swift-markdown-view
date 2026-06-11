import Testing
@testable import SwiftMarkdownEditorCore

struct EditorEngineTests {

    /// Simulates typing one character at the caret (as the text view would).
    private func type(_ ch: String, into engine: MarkdownEditorEngine) {
        let caret = engine.selection.head
        engine.apply(TextChange(insert: ch, at: caret), selection: Selection(caret: caret + ch.utf16Length))
    }

    // MARK: - Basic editing

    @Test("Replacing selection updates text and caret")
    func replaceSelection() {
        let engine = MarkdownEditorEngine(text: "hello world")
        engine.setSelection(Selection(anchor: 0, head: 5))
        engine.replaceSelection(with: "goodbye")
        #expect(engine.text == "goodbye world")
        #expect(engine.selection == Selection(caret: 7))
    }

    @Test("onStateChange fires on edits")
    func stateChangeCallback() {
        let engine = MarkdownEditorEngine(text: "")
        var captured: [String] = []
        engine.onStateChange = { captured.append($0.text) }
        type("a", into: engine)
        type("b", into: engine)
        #expect(captured == ["a", "ab"])
    }

    // MARK: - Undo / redo

    @Test("Single undo reverts and restores selection")
    func undoRestoresState() {
        let engine = MarkdownEditorEngine(text: "abc")
        engine.setSelection(Selection(caret: 3))
        engine.apply(TextChange(insert: "!", at: 3), selection: Selection(caret: 4), allowCoalescing: false)
        #expect(engine.text == "abc!")
        #expect(engine.undo())
        #expect(engine.text == "abc")
        #expect(engine.selection == Selection(caret: 3))
    }

    @Test("Redo re-applies the undone edit")
    func redoReapplies() {
        let engine = MarkdownEditorEngine(text: "abc")
        engine.apply(TextChange(insert: "!", at: 3), selection: Selection(caret: 4), allowCoalescing: false)
        _ = engine.undo()
        #expect(engine.redo())
        #expect(engine.text == "abc!")
        #expect(engine.selection == Selection(caret: 4))
    }

    @Test("Typing coalesces into a single undo step")
    func typingCoalesces() {
        let engine = MarkdownEditorEngine(text: "")
        type("h", into: engine)
        type("e", into: engine)
        type("l", into: engine)
        type("l", into: engine)
        type("o", into: engine)
        #expect(engine.text == "hello")
        #expect(engine.canUndo)
        #expect(engine.undo())
        // One undo removes the whole coalesced run.
        #expect(engine.text == "")
        #expect(!engine.canUndo)
    }

    @Test("Whitespace produces word-level undo granularity")
    func spaceBreaksCoalescing() {
        let engine = MarkdownEditorEngine(text: "")
        type("h", into: engine)
        type("i", into: engine)
        type(" ", into: engine)
        type("y", into: engine)
        type("o", into: engine)
        type("u", into: engine)
        #expect(engine.text == "hi you")
        // A space starts a new group; the following characters merge onto it, so
        // the leading space attaches to the next word: groups are ["hi", " you"].
        _ = engine.undo()
        #expect(engine.text == "hi")
        _ = engine.undo()
        #expect(engine.text == "")
        #expect(!engine.canUndo)
    }

    @Test("allowCoalescing:false forces a discrete undo step")
    func ruleBreaksCoalescing() {
        let engine = MarkdownEditorEngine(text: "")
        type("a", into: engine)
        type("b", into: engine)
        // A rule-style transform that should be its own undo step.
        engine.apply(TextChange(insert: "X", at: 2), selection: Selection(caret: 3), allowCoalescing: false)
        #expect(engine.text == "abX")
        _ = engine.undo()
        #expect(engine.text == "ab") // only the rule edit undone
        _ = engine.undo()
        #expect(engine.text == "")  // then the typed run
    }

    @Test("New edit after undo clears redo")
    func newEditClearsRedo() {
        let engine = MarkdownEditorEngine(text: "")
        engine.apply(TextChange(insert: "a", at: 0), selection: Selection(caret: 1), allowCoalescing: false)
        _ = engine.undo()
        #expect(engine.canRedo)
        engine.apply(TextChange(insert: "b", at: 0), selection: Selection(caret: 1), allowCoalescing: false)
        #expect(!engine.canRedo)
        #expect(engine.text == "b")
    }

    // MARK: - External updates

    @Test("setText replaces document and clamps selection")
    func setTextClamps() {
        let engine = MarkdownEditorEngine(text: "long document")
        engine.setSelection(Selection(caret: 12))
        engine.setText("hi")
        #expect(engine.text == "hi")
        #expect(engine.selection.head <= 2)
    }
}
