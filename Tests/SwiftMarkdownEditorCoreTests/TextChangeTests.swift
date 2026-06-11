import Testing
@testable import SwiftMarkdownEditorCore

/// Tests for the atomic edit type: applying, position mapping, and inversion.
struct TextChangeTests {

    // MARK: - Apply

    @Test("Insertion at caret inserts text")
    func insertAtCaret() {
        let change = TextChange(insert: "ABC", at: 2)
        #expect(change.apply(to: "12345") == "12ABC345")
    }

    @Test("Replacing a range substitutes text")
    func replaceRange() {
        let change = TextChange(range: TextSpan(location: 1, length: 3), replacement: "X")
        #expect(change.apply(to: "12345") == "1X5")
    }

    @Test("Deletion removes the range")
    func deleteRange() {
        let change = TextChange(range: TextSpan(location: 0, length: 2), replacement: "")
        #expect(change.apply(to: "12345") == "345")
    }

    @Test("Apply handles multi-byte (UTF-16) content by offset")
    func applyUnicode() {
        // "🎉" is 2 UTF-16 code units. Insert after it (offset 2).
        let change = TextChange(insert: "!", at: 2)
        #expect(change.apply(to: "🎉x") == "🎉!x")
    }

    @Test("Length delta reflects growth and shrinkage")
    func lengthDelta() {
        #expect(TextChange(insert: "AB", at: 0).lengthDelta == 2)
        #expect(TextChange(range: TextSpan(location: 0, length: 3), replacement: "A").lengthDelta == -2)
    }

    // MARK: - Position mapping

    @Test("Positions before the edit are unchanged")
    func mapBeforeEdit() {
        let change = TextChange(insert: "XXX", at: 5)
        #expect(change.mapOffset(3) == 3)
    }

    @Test("Positions after the edit shift by delta")
    func mapAfterEdit() {
        let change = TextChange(insert: "XXX", at: 5)
        #expect(change.mapOffset(8) == 11)
    }

    @Test("Position at insertion point honors bias")
    func mapAtInsertionPoint() {
        let change = TextChange(insert: "XXX", at: 5)
        #expect(change.mapOffset(5, bias: .left) == 5)
        #expect(change.mapOffset(5, bias: .right) == 8)
    }

    @Test("Position inside a replaced range collapses per bias")
    func mapInsideReplacedRange() {
        // Replace [2,6) (length 4) with "AB" (length 2).
        let change = TextChange(range: TextSpan(location: 2, length: 4), replacement: "AB")
        #expect(change.mapOffset(4, bias: .left) == 2)
        #expect(change.mapOffset(4, bias: .right) == 4) // 2 + insertedLength(2)
        #expect(change.mapOffset(1) == 1)               // before
        #expect(change.mapOffset(6, bias: .right) == 4) // boundary == upper -> inside
        #expect(change.mapOffset(7) == 5)               // after: 7 + (-2)
    }

    @Test("Selection maps preserving direction")
    func mapSelectionPreservesDirection() {
        let change = TextChange(insert: "XX", at: 0)
        let sel = Selection(anchor: 5, head: 3)
        let mapped = change.mapSelection(sel)
        #expect(mapped.anchor == 7)
        #expect(mapped.head == 5)
    }

    // MARK: - Invert

    @Test("Inverting an insertion yields a deletion that restores the text")
    func invertInsertion() {
        let old = "12345"
        let change = TextChange(insert: "ABC", at: 2)
        let new = change.apply(to: old)
        let inverse = change.inverted(in: old)
        #expect(inverse.apply(to: new) == old)
    }

    @Test("Inverting a replacement restores the original substring")
    func invertReplacement() {
        let old = "Hello World"
        let change = TextChange(range: TextSpan(location: 6, length: 5), replacement: "Swift")
        let new = change.apply(to: old)
        #expect(new == "Hello Swift")
        let inverse = change.inverted(in: old)
        #expect(inverse.apply(to: new) == old)
    }

    @Test("Inverting a deletion re-inserts the deleted text")
    func invertDeletion() {
        let old = "abcdef"
        let change = TextChange(range: TextSpan(location: 1, length: 2), replacement: "")
        let new = change.apply(to: old)
        #expect(new == "adef")
        #expect(change.inverted(in: old).apply(to: new) == old)
    }
}
