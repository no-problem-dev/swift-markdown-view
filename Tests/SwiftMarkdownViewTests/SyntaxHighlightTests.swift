import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Tests for syntax highlighting with the SyntaxHighlighter protocol.
@Suite("Syntax Highlighting")
struct SyntaxHighlightTests {

    // MARK: - PlainTextHighlighter Tests

    @Test("PlainTextHighlighter returns plain AttributedString")
    func plainHighlighterReturnsPlainText() async throws {
        let highlighter = PlainTextHighlighter()
        let code = """
        func greet(_ name: String) -> String {
            return "Hello, \\(name)!"
        }
        """

        let result = try await highlighter.highlight(code, language: "swift")

        #expect(!result.characters.isEmpty)
        #expect(String(result.characters) == code)
    }

    @Test("PlainTextHighlighter returns empty for empty code")
    func emptyCodeReturnsEmpty() async throws {
        let highlighter = PlainTextHighlighter()

        let result = try await highlighter.highlight("", language: "swift")

        #expect(result.characters.isEmpty)
    }

    @Test("PlainTextHighlighter handles nil language")
    func nilLanguageWorks() async throws {
        let highlighter = PlainTextHighlighter()
        let code = "let x = 42"

        let result = try await highlighter.highlight(code, language: nil)

        #expect(!result.characters.isEmpty)
        #expect(String(result.characters) == code)
    }

    @Test("PlainTextHighlighter handles any language identifier")
    func anyLanguageWorks() async throws {
        let highlighter = PlainTextHighlighter()
        let code = "print('hello')"

        let swiftResult = try await highlighter.highlight(code, language: "swift")
        let pythonResult = try await highlighter.highlight(code, language: "python")
        let unknownResult = try await highlighter.highlight(code, language: "unknown")

        // All should return the same plain text
        #expect(String(swiftResult.characters) == code)
        #expect(String(pythonResult.characters) == code)
        #expect(String(unknownResult.characters) == code)
    }

    // MARK: - HighlightState Tests

    @Test("HighlightState cases are equatable")
    func highlightStateEquality() {
        let idle1 = HighlightState.idle
        let idle2 = HighlightState.idle
        #expect(idle1 == idle2)

        let loading1 = HighlightState.loading
        let loading2 = HighlightState.loading
        #expect(loading1 == loading2)

        let success1 = HighlightState.success(AttributedString("test"))
        let success2 = HighlightState.success(AttributedString("test"))
        #expect(success1 == success2)

        // Different states should not be equal
        #expect(idle1 != loading1)
    }

    @Test("HighlightState convenience properties work correctly")
    func highlightStateProperties() {
        let loading = HighlightState.loading
        #expect(loading.isLoading)
        #expect(loading.result == nil)
        #expect(loading.error == nil)

        let attributed = AttributedString("test")
        let success = HighlightState.success(attributed)
        #expect(!success.isLoading)
        #expect(success.result == attributed)
        #expect(success.error == nil)

        struct TestError: Error {}
        let failure = HighlightState.failure(TestError())
        #expect(!failure.isLoading)
        #expect(failure.result == nil)
        #expect(failure.error != nil)
    }
}
