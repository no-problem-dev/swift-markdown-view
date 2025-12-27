import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Tests for syntax highlighting with the new async SyntaxHighlighter protocol.
@Suite("Syntax Highlighting")
struct SyntaxHighlightTests {

    // MARK: - RegexSyntaxHighlighter Tests

    @Test("Highlighter returns AttributedString for Swift code")
    func highlightsSwiftCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        func greet(_ name: String) -> String {
            return "Hello, \\(name)!"
        }
        """

        let result = try await highlighter.highlight(code, language: "swift")

        #expect(!result.characters.isEmpty)
    }

    @Test("Highlighter returns AttributedString for Python code")
    func highlightsPythonCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        def greet(name: str) -> str:
            return f"Hello, {name}!"
        """

        let result = try await highlighter.highlight(code, language: "python")

        #expect(!result.characters.isEmpty)
    }

    @Test("Empty code returns empty AttributedString")
    func emptyCodeReturnsEmpty() async throws {
        let highlighter = RegexSyntaxHighlighter()

        let result = try await highlighter.highlight("", language: "swift")

        #expect(result.characters.isEmpty)
    }

    @Test("Unknown language uses generic highlighting")
    func unknownLanguageFallback() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = "some code here"

        let result = try await highlighter.highlight(code, language: "unknown")

        #expect(!result.characters.isEmpty)
    }

    @Test("Nil language uses generic highlighting")
    func nilLanguageUsesGeneric() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = "let x = 42"

        let result = try await highlighter.highlight(code, language: nil)

        #expect(!result.characters.isEmpty)
    }

    // MARK: - TypeScript/JavaScript Tests

    @Test("Highlighter handles TypeScript code")
    func highlightsTypeScriptCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        const msg = "hello"
        const name = 'world'
        const tmpl = `template`
        """

        let result = try await highlighter.highlight(code, language: "typescript")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - Go Tests

    @Test("Highlighter handles Go code")
    func highlightsGoCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        func main() {
            // This is a comment
            msg := "Hello, Go!"
            fmt.Println(msg)
        }
        """

        let result = try await highlighter.highlight(code, language: "go")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - Rust Tests

    @Test("Highlighter handles Rust code")
    func highlightsRustCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        fn main() {
            // Rust comment
            let msg = "Hello, Rust!";
            println!("{}", msg);
        }
        """

        let result = try await highlighter.highlight(code, language: "rust")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - Java Tests

    @Test("Highlighter handles Java code")
    func highlightsJavaCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        public class Main {
            // Java comment
            public static void main(String[] args) {
                System.out.println("Hello, Java!");
            }
        }
        """

        let result = try await highlighter.highlight(code, language: "java")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - Ruby Tests

    @Test("Highlighter handles Ruby code")
    func highlightsRubyCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        def greet(name)
          # Ruby comment
          puts "Hello, #{name}!"
        end
        """

        let result = try await highlighter.highlight(code, language: "ruby")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - Shell Tests

    @Test("Highlighter handles Shell code")
    func highlightsShellCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        #!/bin/bash
        # Shell comment
        echo "Hello, Shell!"
        """

        let result = try await highlighter.highlight(code, language: "bash")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - SQL Tests

    @Test("Highlighter handles SQL code")
    func highlightsSQLCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        -- SQL comment
        SELECT name, age FROM users WHERE age > 18;
        """

        let result = try await highlighter.highlight(code, language: "sql")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - HTML Tests

    @Test("Highlighter handles HTML code")
    func highlightsHTMLCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = "<div class=\"container\"><p>Hello</p></div>"

        let result = try await highlighter.highlight(code, language: "html")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - CSS Tests

    @Test("Highlighter handles CSS code")
    func highlightsCSSCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        .container {
            color: red;
            font-size: 16px;
        }
        """

        let result = try await highlighter.highlight(code, language: "css")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - JSON Tests

    @Test("Highlighter handles JSON code")
    func highlightsJSONCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        {
            "name": "John",
            "age": 30,
            "active": true
        }
        """

        let result = try await highlighter.highlight(code, language: "json")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - YAML Tests

    @Test("Highlighter handles YAML code")
    func highlightsYAMLCode() async throws {
        let highlighter = RegexSyntaxHighlighter()
        let code = """
        # YAML comment
        name: John
        age: 30
        active: true
        """

        let result = try await highlighter.highlight(code, language: "yaml")

        #expect(!result.characters.isEmpty)
    }

    // MARK: - Color Scheme Tests

    @Test("SyntaxColorScheme provides adaptive colors")
    func adaptiveColorsExist() {
        let colors = SyntaxColorScheme.adaptive

        // Verify colors are set
        #expect(colors.keyword != colors.string)
        #expect(colors.comment != colors.number)
    }

    @Test("SyntaxColorScheme provides light and dark presets")
    func presetsExist() {
        let light = SyntaxColorScheme.light
        let dark = SyntaxColorScheme.dark

        // Light and dark should have different plain colors
        #expect(light.plain != dark.plain)
    }

    @Test("Custom color scheme can be created")
    func customColorScheme() {
        let custom = SyntaxColorScheme(
            keyword: .red,
            string: .green,
            comment: .gray,
            number: .blue,
            type: .orange,
            property: .purple,
            punctuation: .secondary,
            plain: .primary
        )

        #expect(custom.keyword == .red)
        #expect(custom.string == .green)
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
