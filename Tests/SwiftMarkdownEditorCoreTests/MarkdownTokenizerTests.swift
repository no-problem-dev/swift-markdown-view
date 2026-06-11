import Foundation
import Testing
@testable import SwiftMarkdownEditorCore

struct MarkdownTokenizerTests {

    /// Returns tokens as (kind, sliced source) pairs for readable assertions.
    private func tokens(_ source: String) -> [(MarkdownToken.Kind, String)] {
        MarkdownTokenizer.tokenize(source).map { token in
            (token.kind, source.substring(in: token.range))
        }
    }

    private func assertNoOverlap(_ source: String, sourceLine: Int = #line) {
        let ts = MarkdownTokenizer.tokenize(source)
        for (a, b) in zip(ts, ts.dropFirst()) {
            #expect(a.range.upperBound <= b.range.lowerBound, "tokens overlap: \(a) / \(b)")
        }
    }

    // MARK: - Headings

    @Test("ATX heading marker and text")
    func heading() {
        let result = tokens("## Hello")
        #expect(result.contains { $0 == (.headingMarker, "##") })
        #expect(result.contains { $0 == (.heading, "Hello") })
    }

    @Test("Too many hashes is not a heading")
    func notHeading() {
        let result = tokens("####### Nope")
        #expect(!result.contains { $0.0 == .headingMarker })
    }

    @Test("Hash without trailing space is not a heading")
    func hashtagNotHeading() {
        let result = tokens("#tag here")
        #expect(!result.contains { $0.0 == .headingMarker })
    }

    // MARK: - Emphasis / strong / strikethrough

    @Test("Strong and emphasis delimiters distinguished by run length")
    func emphasisStrong() {
        let result = tokens("a *b* and **c**")
        #expect(result.filter { $0.0 == .emphasis }.map(\.1) == ["*", "*"])
        #expect(result.filter { $0.0 == .strong }.map(\.1) == ["**", "**"])
    }

    @Test("Strikethrough requires double tilde")
    func strikethrough() {
        let result = tokens("~~gone~~ but ~not~")
        #expect(result.filter { $0.0 == .strikethrough }.map(\.1) == ["~~", "~~"])
    }

    @Test("Intraword underscores are not emphasis")
    func intrawordUnderscore() {
        let result = tokens("snake_case_name")
        #expect(!result.contains { $0.0 == .emphasis || $0.0 == .strong })
    }

    @Test("Underscore emphasis at word boundary is detected")
    func boundaryUnderscore() {
        let result = tokens("_word_")
        #expect(result.filter { $0.0 == .emphasis }.map(\.1) == ["_", "_"])
    }

    // MARK: - Inline code

    @Test("Inline code span includes backticks")
    func inlineCode() {
        let result = tokens("use `let x = 1` now")
        #expect(result.contains { $0 == (.inlineCode, "`let x = 1`") })
    }

    @Test("Code span suppresses inner markup")
    func codeSuppressesMarkup() {
        let result = tokens("`a *b* c`")
        #expect(result.filter { $0.0 == .emphasis }.isEmpty)
        #expect(result.contains { $0 == (.inlineCode, "`a *b* c`") })
    }

    // MARK: - Lists

    @Test("Bullet list marker")
    func bulletList() {
        let result = tokens("- item")
        #expect(result.contains { $0 == (.listMarker, "-") })
    }

    @Test("Ordered list marker")
    func orderedList() {
        let result = tokens("12. item")
        #expect(result.contains { $0 == (.listMarker, "12.") })
    }

    @Test("Task checkbox after bullet")
    func taskCheckbox() {
        let result = tokens("- [x] done")
        #expect(result.contains { $0 == (.listMarker, "-") })
        #expect(result.contains { $0 == (.taskMarker, "[x]") })
    }

    @Test("Dash without space is not a list (could be text)")
    func dashNotList() {
        let result = tokens("-notalist")
        #expect(!result.contains { $0.0 == .listMarker })
    }

    // MARK: - Blockquote

    @Test("Blockquote marker")
    func blockquote() {
        let result = tokens("> quoted *text*")
        #expect(result.contains { $0 == (.blockquote, "> ") })
        // Inline still scanned after the marker.
        #expect(result.contains { $0 == (.emphasis, "*") })
    }

    // MARK: - Thematic break

    @Test("Thematic break")
    func thematicBreak() {
        #expect(tokens("---").contains { $0 == (.thematicBreak, "---") })
        #expect(tokens("***").contains { $0 == (.thematicBreak, "***") })
        #expect(tokens("- - -").contains { $0.0 == .thematicBreak })
    }

    // MARK: - Links

    @Test("Link text and URL")
    func link() {
        let result = tokens("see [Apple](https://apple.com) ok")
        #expect(result.contains { $0 == (.linkText, "[Apple]") })
        #expect(result.contains { $0 == (.linkURL, "(https://apple.com)") })
    }

    @Test("Image includes bang in link text")
    func image() {
        let result = tokens("![alt](img.png)")
        #expect(result.contains { $0 == (.linkText, "![alt]") })
        #expect(result.contains { $0 == (.linkURL, "(img.png)") })
    }

    // MARK: - Fenced code blocks

    @Test("Fenced code block: fence lines and content")
    func fencedCode() {
        let source = """
        ```swift
        let x = *1*
        ```
        """
        let result = tokens(source)
        #expect(result.filter { $0.0 == .codeFence }.count == 2)
        #expect(result.contains { $0 == (.codeBlock, "let x = *1*") })
        // No emphasis inside the fence.
        #expect(result.filter { $0.0 == .emphasis }.isEmpty)
    }

    @Test("Unterminated fence keeps everything as code")
    func unterminatedFence() {
        let source = """
        ```
        still code
        """
        let result = tokens(source)
        #expect(result.contains { $0 == (.codeBlock, "still code") })
    }

    // MARK: - Invariants

    @Test("Tokens never overlap across many constructs")
    func noOverlap() {
        assertNoOverlap("# H *e* `c` [l](u) ~~s~~")
        assertNoOverlap("- [ ] task with **bold** and `code`")
        assertNoOverlap("> quote with [link](x) and _em_")
        assertNoOverlap("text with 🎉 emoji and *star*")
    }

    @Test("Emoji offsets stay correct (UTF-16)")
    func emojiOffsets() {
        // "🎉" is 2 UTF-16 units; the * after it must be located correctly.
        let source = "🎉 *x*"
        let result = tokens(source)
        #expect(result.filter { $0.0 == .emphasis }.map(\.1) == ["*", "*"])
    }
}
