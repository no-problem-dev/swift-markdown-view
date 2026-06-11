import Testing
@testable import SwiftMarkdownEditorCore

struct InlineSpanParserTests {

    private func spans(_ text: String) -> [(InlineSpan.Kind, content: String, markers: [String])] {
        InlineSpanParser.parse(text).map { span in
            (span.kind,
             text.substring(in: span.contentRange),
             span.markerRanges.map { text.substring(in: $0) })
        }
    }

    @Test("Strong pairs ** and exposes content + markers")
    func strong() {
        let result = spans("a **bold** b")
        #expect(result.count == 1)
        #expect(result[0].0 == .strong)
        #expect(result[0].content == "bold")
        #expect(result[0].markers == ["**", "**"])
    }

    @Test("Emphasis pairs single *")
    func emphasis() {
        let result = spans("an *italic* word")
        #expect(result.count == 1)
        #expect(result[0].0 == .emphasis)
        #expect(result[0].content == "italic")
        #expect(result[0].markers == ["*", "*"])
    }

    @Test("Underscore strong and emphasis")
    func underscore() {
        #expect(spans("__b__").first?.0 == .strong)
        #expect(spans("_i_").first?.0 == .emphasis)
    }

    @Test("Strikethrough requires ~~")
    func strikethrough() {
        let result = spans("~~gone~~ and ~no~")
        #expect(result.count == 1)
        #expect(result[0].0 == .strikethrough)
        #expect(result[0].content == "gone")
    }

    @Test("Code span pairs backticks and excludes interior markup")
    func code() {
        let result = spans("use `a *b* c` now")
        #expect(result.count == 1)
        #expect(result[0].0 == .code)
        #expect(result[0].content == "a *b* c")
        #expect(result[0].markers == ["`", "`"])
    }

    @Test("Multi-backtick code span")
    func multiBacktick() {
        let result = spans("``a ` b``")
        #expect(result.first?.0 == .code)
        #expect(result.first?.content == "a ` b")
    }

    @Test("Simple nesting: outer strong, inner emphasis")
    func nesting() {
        let result = spans("**a *b* c**")
        #expect(result.contains { $0.0 == .strong && $0.content == "a *b* c" })
        #expect(result.contains { $0.0 == .emphasis && $0.content == "b" })
    }

    @Test("Triple markers resolve to strong")
    func triple() {
        #expect(spans("***x***").first?.0 == .strong)
        #expect(spans("***x***").first?.content == "x")
    }

    @Test("Unmatched markers produce no span")
    func unmatched() {
        #expect(spans("a **b").isEmpty)
        #expect(spans("trailing *").isEmpty)
        #expect(spans("**a*").isEmpty) // length mismatch
    }

    @Test("Empty content is not a span")
    func emptyContent() {
        #expect(spans("****").isEmpty)
        #expect(spans("``").isEmpty)
    }

    @Test("Emphasis does not cross newlines")
    func noCrossLine() {
        #expect(spans("*a\nb*").isEmpty)
    }

    @Test("Intraword underscores are literal")
    func intraword() {
        #expect(spans("snake_case_name").isEmpty)
        #expect(spans("_word_").first?.0 == .emphasis)
    }

    @Test("Offsets stay correct across emoji (UTF-16)")
    func emoji() {
        // "🎉" is 2 UTF-16 units; **x** after it must locate correctly.
        let text = "🎉 **x**"
        let result = InlineSpanParser.parse(text)
        #expect(result.count == 1)
        #expect(text.substring(in: result[0].contentRange) == "x")
        #expect(text.substring(in: result[0].markerRanges[0]) == "**")
    }

    @Test("Multiple spans on one line in order")
    func multiple() {
        let result = spans("*a* and **b** and `c`")
        #expect(result.map(\.0) == [.emphasis, .strong, .code])
    }
}
