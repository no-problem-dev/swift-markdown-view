import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Tests for syntax highlighting tokenization
struct SyntaxHighlightTests {

    // MARK: - SyntaxColors Tests

    @Test("SyntaxColors returns correct color for each token kind")
    func syntaxColorsReturnsCorrectColors() {
        let colors = SyntaxColors.light

        #expect(colors.color(for: .keyword) == colors.keyword)
        #expect(colors.color(for: .string) == colors.string)
        #expect(colors.color(for: .comment) == colors.comment)
        #expect(colors.color(for: .number) == colors.number)
        #expect(colors.color(for: .type) == colors.type)
        #expect(colors.color(for: .property) == colors.property)
        #expect(colors.color(for: .punctuation) == colors.punctuation)
        #expect(colors.color(for: .plain) == colors.plain)
    }

    @Test("SyntaxColors provides light and dark presets")
    func syntaxColorsPresetsExist() {
        let light = SyntaxColors.light
        let dark = SyntaxColors.dark

        // Light and dark should have different plain colors
        #expect(light.plain != dark.plain)
    }

    // MARK: - Token Kind Tests

    @Test("SyntaxTokenKind has all required cases")
    func tokenKindHasRequiredCases() {
        // Verify all token kinds exist
        let kinds: [SyntaxTokenKind] = [
            .plain,
            .keyword,
            .string,
            .comment,
            .number,
            .type,
            .property,
            .punctuation
        ]
        #expect(kinds.count == 8)
    }

    @Test("SyntaxToken stores text and kind correctly")
    func tokenStoresValues() {
        let token = SyntaxToken(text: "func", kind: .keyword)
        #expect(token.text == "func")
        #expect(token.kind == .keyword)
    }

    // MARK: - Swift Tokenization Tests

    @Test("Swift keywords are tokenized correctly")
    func swiftKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "func let var if else guard return"
        let tokens = tokenizer.tokenize(code, language: "swift")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 7)
    }

    @Test("Swift string literals are tokenized correctly")
    func swiftStringsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        let message = "Hello, World!"
        """
        let tokens = tokenizer.tokenize(code, language: "swift")

        let strings = tokens.filter { $0.kind == .string }
        #expect(strings.count >= 1)
        #expect(strings.first?.text.contains("Hello") == true)
    }

    @Test("Swift single-line comments are tokenized correctly")
    func swiftSingleLineCommentsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        // This is a comment
        let x = 1
        """
        let tokens = tokenizer.tokenize(code, language: "swift")

        let comments = tokens.filter { $0.kind == .comment }
        #expect(comments.count >= 1)
        #expect(comments.first?.text.contains("This is a comment") == true)
    }

    @Test("Swift numbers are tokenized correctly")
    func swiftNumbersTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "let x = 42 + 3.14"
        let tokens = tokenizer.tokenize(code, language: "swift")

        let numbers = tokens.filter { $0.kind == .number }
        #expect(numbers.count >= 2)
    }

    @Test("Swift types are tokenized correctly")
    func swiftTypesTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "let name: String = value as? Int"
        let tokens = tokenizer.tokenize(code, language: "swift")

        let types = tokens.filter { $0.kind == .type }
        #expect(types.count >= 2)
    }

    @Test("Swift punctuation is tokenized correctly")
    func swiftPunctuationTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "func foo() { }"
        let tokens = tokenizer.tokenize(code, language: "swift")

        let punctuation = tokens.filter { $0.kind == .punctuation }
        #expect(punctuation.count >= 4) // ( ) { }
    }

    // MARK: - TypeScript/JavaScript Tokenization Tests

    @Test("TypeScript keywords are tokenized correctly")
    func typescriptKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "const let function if else return async await"
        let tokens = tokenizer.tokenize(code, language: "typescript")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 7)
    }

    @Test("TypeScript string literals are tokenized correctly")
    func typescriptStringsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        const msg = "hello"
        const name = 'world'
        const tmpl = `template`
        """
        let tokens = tokenizer.tokenize(code, language: "typescript")

        let strings = tokens.filter { $0.kind == .string }
        #expect(strings.count >= 3)
    }

    // MARK: - Edge Cases

    @Test("Empty code returns empty tokens")
    func emptyCodeReturnsEmpty() {
        let tokenizer = RegexSyntaxTokenizer()
        let tokens = tokenizer.tokenize("", language: "swift")
        #expect(tokens.isEmpty)
    }

    @Test("Unknown language falls back to basic tokenization")
    func unknownLanguageFallback() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "some code here"
        let tokens = tokenizer.tokenize(code, language: "unknown")

        // Should still produce tokens (at least plain text)
        #expect(!tokens.isEmpty)
    }

    @Test("Nil language uses generic tokenization")
    func nilLanguageUsesGeneric() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "let x = 42"
        let tokens = tokenizer.tokenize(code, language: nil)

        #expect(!tokens.isEmpty)
    }

    @Test("Tokens concatenation reproduces original code")
    func tokensConcatenateToOriginal() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        func greet(name: String) {
            print("Hello, \\(name)!")
        }
        """
        let tokens = tokenizer.tokenize(code, language: "swift")

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - Multi-line Code Tests

    @Test("Multi-line Swift code tokenizes correctly")
    func multiLineSwiftTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        struct Person {
            let name: String
            let age: Int

            func greet() {
                print("Hello, I'm \\(name)")
            }
        }
        """
        let tokens = tokenizer.tokenize(code, language: "swift")

        let keywords = tokens.filter { $0.kind == .keyword }
        let types = tokens.filter { $0.kind == .type }

        #expect(keywords.count >= 4) // struct, let, let, func
        #expect(types.count >= 3)    // String, Int, Person(?)
    }

    // MARK: - Go Tokenization Tests

    @Test("Go keywords are tokenized correctly")
    func goKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "func package import if else for range return defer go chan"
        let tokens = tokenizer.tokenize(code, language: "go")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 9)
    }

    @Test("Go code tokenizes correctly")
    func goCodeTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        func main() {
            // This is a comment
            msg := "Hello, Go!"
            fmt.Println(msg)
        }
        """
        let tokens = tokenizer.tokenize(code, language: "go")

        let comments = tokens.filter { $0.kind == .comment }
        let strings = tokens.filter { $0.kind == .string }
        #expect(comments.count >= 1)
        #expect(strings.count >= 1)

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - Rust Tokenization Tests

    @Test("Rust keywords are tokenized correctly")
    func rustKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "fn let mut if else match loop while for pub struct impl"
        let tokens = tokenizer.tokenize(code, language: "rust")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 10)
    }

    @Test("Rust code tokenizes correctly")
    func rustCodeTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        fn main() {
            // Rust comment
            let msg = "Hello, Rust!";
            println!("{}", msg);
        }
        """
        let tokens = tokenizer.tokenize(code, language: "rust")

        let comments = tokens.filter { $0.kind == .comment }
        let strings = tokens.filter { $0.kind == .string }
        #expect(comments.count >= 1)
        #expect(strings.count >= 1)

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - Java Tokenization Tests

    @Test("Java keywords are tokenized correctly")
    func javaKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "public class static void if else for while return new"
        let tokens = tokenizer.tokenize(code, language: "java")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 9)
    }

    @Test("Java code tokenizes correctly")
    func javaCodeTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        public class Main {
            // Java comment
            public static void main(String[] args) {
                System.out.println("Hello, Java!");
            }
        }
        """
        let tokens = tokenizer.tokenize(code, language: "java")

        let comments = tokens.filter { $0.kind == .comment }
        let strings = tokens.filter { $0.kind == .string }
        let types = tokens.filter { $0.kind == .type }
        #expect(comments.count >= 1)
        #expect(strings.count >= 1)
        #expect(types.count >= 2) // Main, String, System

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - Kotlin Tokenization Tests

    @Test("Kotlin keywords are tokenized correctly")
    func kotlinKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "fun val var if else when for while return class object"
        let tokens = tokenizer.tokenize(code, language: "kotlin")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 10)
    }

    // MARK: - Ruby Tokenization Tests

    @Test("Ruby keywords are tokenized correctly")
    func rubyKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "def class module if elsif else end do begin rescue"
        let tokens = tokenizer.tokenize(code, language: "ruby")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 9)
    }

    @Test("Ruby code tokenizes correctly")
    func rubyCodeTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        def greet(name)
          # Ruby comment
          puts "Hello, #{name}!"
        end
        """
        let tokens = tokenizer.tokenize(code, language: "ruby")

        let comments = tokens.filter { $0.kind == .comment }
        let strings = tokens.filter { $0.kind == .string }
        #expect(comments.count >= 1)
        #expect(strings.count >= 1)

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - Shell/Bash Tokenization Tests

    @Test("Shell keywords are tokenized correctly")
    func shellKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "if then else fi for do done while case esac"
        let tokens = tokenizer.tokenize(code, language: "bash")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 9)
    }

    @Test("Shell code tokenizes correctly")
    func shellCodeTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        #!/bin/bash
        # Shell comment
        echo "Hello, Shell!"
        """
        let tokens = tokenizer.tokenize(code, language: "shell")

        let comments = tokens.filter { $0.kind == .comment }
        let strings = tokens.filter { $0.kind == .string }
        #expect(comments.count >= 2) // shebang and comment
        #expect(strings.count >= 1)

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - SQL Tokenization Tests

    @Test("SQL keywords are tokenized correctly")
    func sqlKeywordsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "SELECT FROM WHERE JOIN ON INSERT INTO UPDATE DELETE CREATE TABLE"
        let tokens = tokenizer.tokenize(code, language: "sql")

        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(keywords.count >= 10)
    }

    @Test("SQL code tokenizes correctly")
    func sqlCodeTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        -- SQL comment
        SELECT name, age FROM users WHERE age > 18;
        """
        let tokens = tokenizer.tokenize(code, language: "sql")

        let comments = tokens.filter { $0.kind == .comment }
        let numbers = tokens.filter { $0.kind == .number }
        #expect(comments.count >= 1)
        #expect(numbers.count >= 1)

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - HTML Tokenization Tests

    @Test("HTML tags are tokenized correctly")
    func htmlTagsTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = "<div class=\"container\"><p>Hello</p></div>"
        let tokens = tokenizer.tokenize(code, language: "html")

        let keywords = tokens.filter { $0.kind == .keyword }
        let strings = tokens.filter { $0.kind == .string }
        #expect(keywords.count >= 3) // div, p, div (or tag markers)
        #expect(strings.count >= 1) // "container"

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - CSS Tokenization Tests

    @Test("CSS properties are tokenized correctly")
    func cssPropertiesTokenize() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        .container {
            color: red;
            font-size: 16px;
        }
        """
        let tokens = tokenizer.tokenize(code, language: "css")

        let numbers = tokens.filter { $0.kind == .number }
        #expect(numbers.count >= 1) // 16

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - JSON Tokenization Tests

    @Test("JSON tokenizes correctly")
    func jsonTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        {
            "name": "John",
            "age": 30,
            "active": true
        }
        """
        let tokens = tokenizer.tokenize(code, language: "json")

        let strings = tokens.filter { $0.kind == .string }
        let numbers = tokens.filter { $0.kind == .number }
        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(strings.count >= 2) // "name", "John", etc.
        #expect(numbers.count >= 1) // 30
        #expect(keywords.count >= 1) // true

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }

    // MARK: - YAML Tokenization Tests

    @Test("YAML tokenizes correctly")
    func yamlTokenizes() {
        let tokenizer = RegexSyntaxTokenizer()
        let code = """
        # YAML comment
        name: John
        age: 30
        active: true
        """
        let tokens = tokenizer.tokenize(code, language: "yaml")

        let comments = tokens.filter { $0.kind == .comment }
        let numbers = tokens.filter { $0.kind == .number }
        let keywords = tokens.filter { $0.kind == .keyword }
        #expect(comments.count >= 1)
        #expect(numbers.count >= 1)
        #expect(keywords.count >= 1) // true

        let reconstructed = tokens.map(\.text).joined()
        #expect(reconstructed == code)
    }
}
