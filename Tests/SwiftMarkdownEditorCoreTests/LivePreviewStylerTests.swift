import Testing
@testable import SwiftMarkdownEditorCore

struct LivePreviewStylerTests {

    private func runs(_ text: String, selection: Selection?, focused: Bool = true) -> [(StyleRun.Trait, String)] {
        LivePreviewStyler.runs(text: text, selection: selection, focused: focused)
            .map { ($0.trait, text.substring(in: $0.range)) }
    }

    @Test("Unfocused: content styled, markers concealed")
    func unfocused() {
        let r = runs("a **bold** b", selection: Selection(caret: 0), focused: false)
        #expect(r.contains { $0 == (.bold, "bold") })
        #expect(r.filter { $0.0 == .conceal }.map(\.1) == ["**", "**"])
    }

    @Test("Caret off the span's line: markers concealed")
    func concealedOffLine() {
        // Two lines; caret on line 2, span on line 1.
        let text = "**bold** here\nsecond line"
        let r = runs(text, selection: Selection(caret: 20)) // within "second line"
        #expect(r.contains { $0 == (.bold, "bold") })
        #expect(r.filter { $0.0 == .conceal }.count == 2)
    }

    @Test("Caret on the span's line: markers revealed (no conceal)")
    func revealedOnLine() {
        let text = "**bold** here\nsecond line"
        let r = runs(text, selection: Selection(caret: 3)) // inside "**bold**"
        #expect(r.contains { $0 == (.bold, "bold") })
        #expect(r.filter { $0.0 == .conceal }.isEmpty)
    }

    @Test("Each kind maps to the right trait")
    func traits() {
        #expect(runs("*i*", selection: nil, focused: false).contains { $0 == (.italic, "i") })
        #expect(runs("**b**", selection: nil, focused: false).contains { $0 == (.bold, "b") })
        #expect(runs("~~s~~", selection: nil, focused: false).contains { $0 == (.strikethrough, "s") })
        #expect(runs("`c`", selection: nil, focused: false).contains { $0 == (.monospace, "c") })
    }

    @Test("Selection spanning lines reveals all touched lines")
    func multiLineSelection() {
        let text = "**a** x\n**b** y\n**c** z"
        // selection from line 1 into line 2 reveals lines 1-2, conceals line 3 only.
        let r = LivePreviewStyler.runs(text: text, selection: Selection(anchor: 0, head: 10), focused: true)
        let concealed = r.filter { $0.trait == .conceal }
        #expect(concealed.count == 2) // only "**c**" markers
    }

    @Test("nil selection conceals everything")
    func nilSelection() {
        let r = runs("**b** and *i*", selection: nil)
        #expect(r.filter { $0.0 == .conceal }.count == 4) // 2 markers each
    }

    @Test("Plain text yields no runs")
    func plain() {
        #expect(LivePreviewStyler.runs(text: "just words", selection: Selection(caret: 0), focused: true).isEmpty)
    }

    // MARK: - Headings (block-level live preview)

    @Test("Heading: content enlarged, marker + space concealed")
    func heading() {
        let r = runs("# Title", selection: nil, focused: false)
        #expect(r.contains { $0 == (.heading(level: 1), "Title") })
        #expect(r.contains { $0 == (.conceal, "# ") })
    }

    @Test("Heading level derives from the marker length")
    func headingLevel() {
        #expect(runs("### Sub", selection: nil, focused: false).contains { $0 == (.heading(level: 3), "Sub") })
        #expect(runs("###### Deep", selection: nil, focused: false).contains { $0 == (.heading(level: 6), "Deep") })
    }

    @Test("Heading marker revealed when the caret is on its line, content still enlarged")
    func headingRevealed() {
        let r = runs("# Title", selection: Selection(caret: 3), focused: true)
        #expect(r.contains { $0 == (.heading(level: 1), "Title") })
        #expect(r.filter { $0.0 == .conceal }.isEmpty)
    }

    @Test("Inline emphasis inside a heading composes with the heading run")
    func headingWithInline() {
        let r = runs("# **b**", selection: nil, focused: false)
        #expect(r.contains { $0 == (.heading(level: 1), "**b**") })
        #expect(r.contains { $0 == (.bold, "b") })
        #expect(r.contains { $0 == (.conceal, "# ") })
    }

    @Test("Heading among other lines concealed when caret elsewhere")
    func headingMultiline() {
        let text = "# Title\nbody text"
        let r = runs(text, selection: Selection(caret: 12), focused: true) // in "body text"
        #expect(r.contains { $0 == (.heading(level: 1), "Title") })
        #expect(r.contains { $0 == (.conceal, "# ") })
    }
}
