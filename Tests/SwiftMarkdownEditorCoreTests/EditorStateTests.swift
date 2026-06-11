import Testing
import SwiftMarkdownView
@testable import SwiftMarkdownEditorCore

struct EditorStateTests {

    @Test("Default selection is a caret at end of text")
    func defaultSelection() {
        let state = EditorState(text: "hello")
        #expect(state.selection == Selection(caret: 5))
        #expect(state.length == 5)
    }

    @Test("Applying a change maps the selection by default")
    func applyMapsSelection() {
        let state = EditorState(text: "world", selection: Selection(caret: 5))
        let next = state.applying(TextChange(insert: "hello ", at: 0))
        #expect(next.text == "hello world")
        #expect(next.selection == Selection(caret: 11)) // caret pushed right
    }

    @Test("Replacing places caret after inserted text")
    func replacingPlacesCaret() {
        let state = EditorState(text: "abcde")
        let next = state.replacing(TextSpan(location: 1, length: 2), with: "X")
        #expect(next.text == "aXde")
        #expect(next.selection == Selection(caret: 2))
    }

    @Test("Replacing the selection works")
    func replacingSelection() {
        let state = EditorState(text: "abcde", selection: Selection(anchor: 1, head: 4))
        let next = state.replacingSelection(with: "XY")
        #expect(next.text == "aXYe")
        #expect(next.selection == Selection(caret: 3))
    }

    @Test("Parsed content uses the shared renderer parser")
    func parsedContent() {
        let state = EditorState(text: "# Title\n\nBody")
        let blocks = state.parsedContent().blocks
        #expect(blocks.count == 2)
        guard case .heading(let level, _) = blocks.first else {
            Issue.record("Expected heading")
            return
        }
        #expect(level == 1)
    }
}
