import Testing
@testable import SwiftMarkdownEditorCore

struct MarkdownFormattingTests {

    private func apply(_ transform: EditTransform, to text: String) -> String {
        transform.change.apply(to: text)
    }

    // MARK: - Wrap

    @Test("Wrap a selection in bold")
    func wrapBold() {
        let t = MarkdownFormatting.wrap(text: "a word b", selection: Selection(range: TextSpan(location: 2, length: 4)), delimiter: "**")
        #expect(apply(t, to: "a word b") == "a **word** b")
        #expect(t.selection == Selection(anchor: 4, head: 8)) // inner "word" selected
    }

    @Test("Wrap at a caret inserts a pair with caret between")
    func wrapCaret() {
        let t = MarkdownFormatting.wrap(text: "ab", selection: Selection(caret: 1), delimiter: "*")
        #expect(apply(t, to: "ab") == "a**b")
        #expect(t.selection == Selection(caret: 2))
    }

    @Test("Wrapping an already-wrapped selection toggles it off")
    func wrapToggleOff() {
        // Selection covers "**word**".
        let text = "a **word** b"
        let t = MarkdownFormatting.wrap(text: text, selection: Selection(range: TextSpan(location: 2, length: 8)), delimiter: "**")
        #expect(apply(t, to: text) == "a word b")
        #expect(t.selection == Selection(anchor: 2, head: 6))
    }

    @Test("Wrap in code")
    func wrapCode() {
        let t = MarkdownFormatting.wrap(text: "run foo", selection: Selection(range: TextSpan(location: 4, length: 3)), delimiter: "`")
        #expect(apply(t, to: "run foo") == "run `foo`")
    }

    // MARK: - Line prefix

    @Test("Toggle heading prefix on a single line")
    func headingPrefix() {
        let t = MarkdownFormatting.toggleLinePrefix(text: "Title", selection: Selection(caret: 2), prefix: "# ")
        #expect(apply(t, to: "Title") == "# Title")
    }

    @Test("Toggle heading prefix off when already present")
    func headingPrefixOff() {
        let t = MarkdownFormatting.toggleLinePrefix(text: "# Title", selection: Selection(caret: 3), prefix: "# ")
        #expect(apply(t, to: "# Title") == "Title")
    }

    @Test("Toggle quote prefix across multiple selected lines")
    func quoteMultiline() {
        let text = "one\ntwo\nthree"
        // selection spanning all three lines
        let t = MarkdownFormatting.toggleLinePrefix(text: text, selection: Selection(anchor: 0, head: 13), prefix: "> ")
        #expect(apply(t, to: text) == "> one\n> two\n> three")
    }

    @Test("Toggle list prefix on the caret's line only")
    func listSingleLine() {
        let text = "alpha\nbravo"
        let t = MarkdownFormatting.toggleLinePrefix(text: text, selection: Selection(caret: 8), prefix: "- ")
        #expect(apply(t, to: text) == "alpha\n- bravo")
    }

    @Test("Toggle heading on an empty document inserts the marker, caret after it")
    func headingPrefixEmptyDoc() {
        let t = MarkdownFormatting.toggleLinePrefix(text: "", selection: Selection(caret: 0), prefix: "# ")
        #expect(apply(t, to: "") == "# ")
        #expect(t.selection == Selection(caret: 2))
    }

    @Test("Toggle heading on a blank line between text inserts only on that line")
    func headingPrefixBlankLine() {
        let text = "a\n\nb"
        let t = MarkdownFormatting.toggleLinePrefix(text: text, selection: Selection(caret: 2), prefix: "# ")
        #expect(apply(t, to: text) == "a\n# \nb")
        #expect(t.selection == Selection(caret: 4))
    }

    @Test("Multi-line selection with a blank line skips the blank")
    func headingPrefixMultilineSkipsBlank() {
        let text = "a\n\nb"
        let t = MarkdownFormatting.toggleLinePrefix(text: text, selection: Selection(anchor: 0, head: 4), prefix: "# ")
        #expect(apply(t, to: text) == "# a\n\n# b")
    }

    // MARK: - Link

    @Test("Insert link around a selection, selecting url placeholder")
    func linkWithSelection() {
        let text = "see Apple now"
        let t = MarkdownFormatting.insertLink(text: text, selection: Selection(range: TextSpan(location: 4, length: 5)))
        #expect(apply(t, to: text) == "see [Apple](url) now")
        // "url" should be selected.
        let sel = t.selection.range
        #expect(text.isEmpty == false)
        #expect(apply(t, to: text).substring(in: sel) == "url")
    }

    @Test("Insert link at a caret")
    func linkAtCaret() {
        let t = MarkdownFormatting.insertLink(text: "", selection: Selection(caret: 0))
        #expect(apply(t, to: "") == "[](url)")
        #expect(apply(t, to: "").substring(in: t.selection.range) == "url")
    }
}
