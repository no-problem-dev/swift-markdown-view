import Testing
import SwiftUI
@testable import SwiftMarkdownViewHighlightJS

/// Tests for HighlightJSSyntaxHighlighter.
@Suite("HighlightJS Syntax Highlighter")
struct HighlightJSSyntaxHighlighterTests {

    @Test
    func highlightsSwiftCode() async throws {
        let highlighter = HighlightJSSyntaxHighlighter()
        let code = """
        func greet(_ name: String) -> String {
            return "Hello, \\(name)!"
        }
        """

        let result = try await highlighter.highlight(code, language: "swift")

        // Result should not be empty
        #expect(!result.characters.isEmpty)
    }

    @Test
    func highlightsPythonCode() async throws {
        let highlighter = HighlightJSSyntaxHighlighter()
        let code = """
        def greet(name: str) -> str:
            return f"Hello, {name}!"
        """

        let result = try await highlighter.highlight(code, language: "python")

        #expect(!result.characters.isEmpty)
    }

    @Test
    func autoDetectsLanguage() async throws {
        let highlighter = HighlightJSSyntaxHighlighter()
        let code = """
        function greet(name) {
            return `Hello, ${name}!`;
        }
        """

        // Should auto-detect as JavaScript
        let result = try await highlighter.highlight(code, language: nil)

        #expect(!result.characters.isEmpty)
    }

    @Test
    func handlesEmptyCode() async throws {
        let highlighter = HighlightJSSyntaxHighlighter()

        let result = try await highlighter.highlight("", language: "swift")

        #expect(result.characters.isEmpty)
    }

    @Test
    func usesCustomTheme() async throws {
        let highlighter = HighlightJSSyntaxHighlighter(theme: .github, colorMode: .dark)
        let code = "let x = 42"

        let result = try await highlighter.highlight(code, language: "swift")

        #expect(!result.characters.isEmpty)
    }

    @Test
    func staticPresetsExist() {
        // Just verify the static presets compile and are accessible
        _ = HighlightJSSyntaxHighlighter.xcodeLight
        _ = HighlightJSSyntaxHighlighter.xcodeDark
        _ = HighlightJSSyntaxHighlighter.githubLight
        _ = HighlightJSSyntaxHighlighter.githubDark
        _ = HighlightJSSyntaxHighlighter.atomOneLight
        _ = HighlightJSSyntaxHighlighter.atomOneDark
        _ = HighlightJSSyntaxHighlighter.solarizedLight
        _ = HighlightJSSyntaxHighlighter.solarizedDark
        _ = HighlightJSSyntaxHighlighter.tokyoNightDark
    }
}
