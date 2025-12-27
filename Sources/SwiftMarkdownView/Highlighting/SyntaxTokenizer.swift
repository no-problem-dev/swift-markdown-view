import Foundation

/// A type that can tokenize source code for syntax highlighting.
///
/// Implementations of this protocol break source code into tokens
/// that can be rendered with appropriate colors.
public protocol SyntaxTokenizer: Sendable {
    /// Tokenizes the given source code.
    ///
    /// - Parameters:
    ///   - code: The source code to tokenize.
    ///   - language: The programming language (e.g., "swift", "typescript").
    /// - Returns: An array of tokens that, when concatenated, reproduce the original code.
    func tokenize(_ code: String, language: String?) -> [SyntaxToken]
}

/// A regex-based syntax tokenizer supporting common languages.
///
/// This tokenizer provides basic syntax highlighting using regular expressions.
/// It prioritizes readability over perfect accuracy.
///
/// Supported languages:
/// - Swift
/// - TypeScript, JavaScript (tsx, jsx)
/// - Python
/// - Go
/// - Rust
/// - Java, Kotlin
/// - Ruby
/// - Shell, Bash
/// - SQL
/// - HTML, XML
/// - CSS, SCSS, SASS, Less
/// - JSON
/// - YAML
public struct RegexSyntaxTokenizer: SyntaxTokenizer, Sendable {

    public init() {}

    public func tokenize(_ code: String, language: String?) -> [SyntaxToken] {
        guard !code.isEmpty else { return [] }

        let lang = language?.lowercased() ?? ""
        let patterns = tokenPatterns(for: lang)

        return tokenize(code: code, patterns: patterns)
    }

    // MARK: - Private Implementation

    private struct TokenPattern {
        let kind: SyntaxTokenKind
        let regex: NSRegularExpression
    }

    private func tokenPatterns(for language: String) -> [TokenPattern] {
        switch language {
        case "swift":
            return swiftPatterns
        case "typescript", "ts", "javascript", "js", "jsx", "tsx":
            return typescriptPatterns
        case "python", "py":
            return pythonPatterns
        case "go", "golang":
            return goPatterns
        case "rust", "rs":
            return rustPatterns
        case "java":
            return javaPatterns
        case "kotlin", "kt":
            return kotlinPatterns
        case "ruby", "rb":
            return rubyPatterns
        case "shell", "bash", "sh", "zsh":
            return shellPatterns
        case "sql":
            return sqlPatterns
        case "html", "htm", "xml":
            return htmlPatterns
        case "css", "scss", "sass", "less":
            return cssPatterns
        case "json":
            return jsonPatterns
        case "yaml", "yml":
            return yamlPatterns
        default:
            return genericPatterns
        }
    }

    private func tokenize(code: String, patterns: [TokenPattern]) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        var currentIndex = code.startIndex

        while currentIndex < code.endIndex {
            var matched = false

            for pattern in patterns {
                let range = NSRange(currentIndex..<code.endIndex, in: code)

                if let match = pattern.regex.firstMatch(in: code, range: range),
                   match.range.location == NSRange(currentIndex..<code.endIndex, in: code).location {

                    if let matchRange = Range(match.range, in: code) {
                        let text = String(code[matchRange])
                        tokens.append(SyntaxToken(text: text, kind: pattern.kind))
                        currentIndex = matchRange.upperBound
                        matched = true
                        break
                    }
                }
            }

            if !matched {
                // No pattern matched - consume one character as plain
                let nextIndex = code.index(after: currentIndex)
                let text = String(code[currentIndex..<nextIndex])
                tokens.append(SyntaxToken(text: text, kind: .plain))
                currentIndex = nextIndex
            }
        }

        return mergeAdjacentPlainTokens(tokens)
    }

    /// Merges adjacent plain tokens for efficiency.
    private func mergeAdjacentPlainTokens(_ tokens: [SyntaxToken]) -> [SyntaxToken] {
        var result: [SyntaxToken] = []

        for token in tokens {
            if let last = result.last, last.kind == .plain && token.kind == .plain {
                result[result.count - 1] = SyntaxToken(
                    text: last.text + token.text,
                    kind: .plain
                )
            } else {
                result.append(token)
            }
        }

        return result
    }

    // MARK: - Language Patterns

    private var swiftPatterns: [TokenPattern] {
        [
            // Single-line comments (must come before operators)
            pattern(.comment, #"//[^\n]*"#),
            // Multi-line comments
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // String literals (double-quoted, with escape handling)
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            // Numbers (decimal, hex, binary, float)
            pattern(.number, #"\b(?:0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:func|let|var|if|else|guard|switch|case|default|for|while|repeat|return|break|continue|throw|throws|try|catch|defer|do|import|struct|class|enum|protocol|extension|typealias|associatedtype|init|deinit|self|Self|super|nil|true|false|static|private|fileprivate|internal|public|open|final|override|mutating|nonmutating|lazy|weak|unowned|inout|async|await|actor|some|any|where|in|is|as)\b"#),
            // Types (capitalized identifiers)
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Property access
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var typescriptPatterns: [TokenPattern] {
        [
            // Single-line comments
            pattern(.comment, #"//[^\n]*"#),
            // Multi-line comments
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // Template literals
            pattern(.string, #"`(?:[^`\\]|\\.)*`"#),
            // String literals (double and single quoted)
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            // Numbers
            pattern(.number, #"\b(?:0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:function|const|let|var|if|else|switch|case|default|for|while|do|return|break|continue|throw|try|catch|finally|new|delete|typeof|instanceof|void|this|super|class|extends|implements|interface|type|enum|namespace|module|export|import|from|as|async|await|yield|static|public|private|protected|readonly|abstract|get|set|true|false|null|undefined|NaN|Infinity)\b"#),
            // Types (capitalized identifiers)
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Property access
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var pythonPatterns: [TokenPattern] {
        [
            // Single-line comments
            pattern(.comment, #"#[^\n]*"#),
            // Triple-quoted strings
            pattern(.string, #"\"\"\"[\s\S]*?\"\"\""#),
            pattern(.string, #"'''[\s\S]*?'''"#),
            // String literals
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            // Numbers
            pattern(.number, #"\b(?:0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:def|class|if|elif|else|for|while|try|except|finally|with|as|import|from|return|yield|raise|break|continue|pass|lambda|and|or|not|in|is|True|False|None|async|await|global|nonlocal)\b"#),
            // Types (capitalized identifiers)
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Property access
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var genericPatterns: [TokenPattern] {
        [
            // C-style comments
            pattern(.comment, #"//[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // String literals
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            // Numbers
            pattern(.number, #"\b\d+\.?\d*\b"#),
            // Common keywords
            pattern(.keyword, #"\b(?:if|else|for|while|return|function|class|const|let|var|true|false|null)\b"#),
            // Types
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - Go

    private var goPatterns: [TokenPattern] {
        [
            // Single-line comments
            pattern(.comment, #"//[^\n]*"#),
            // Multi-line comments
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // Raw string literals
            pattern(.string, #"`[^`]*`"#),
            // String literals
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            // Numbers
            pattern(.number, #"\b(?:0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:func|package|import|if|else|for|range|return|defer|go|chan|select|switch|case|default|break|continue|fallthrough|goto|var|const|type|struct|interface|map|make|new|append|len|cap|copy|delete|panic|recover|nil|true|false|iota)\b"#),
            // Types
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Property access
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - Rust

    private var rustPatterns: [TokenPattern] {
        [
            // Single-line comments
            pattern(.comment, #"//[^\n]*"#),
            // Multi-line comments
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // String literals
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            // Char literals
            pattern(.string, #"'(?:[^'\\]|\\.)+'"#),
            // Numbers
            pattern(.number, #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|0o[0-7_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?)\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:fn|let|mut|if|else|match|loop|while|for|in|break|continue|return|pub|struct|enum|impl|trait|type|mod|use|crate|super|self|Self|const|static|ref|move|async|await|dyn|extern|unsafe|where|as|true|false|Some|None|Ok|Err)\b"#),
            // Types
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Property access
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            // Punctuation (including Rust-specific operators)
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - Java

    private var javaPatterns: [TokenPattern] {
        [
            // Single-line comments
            pattern(.comment, #"//[^\n]*"#),
            // Multi-line comments
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // String literals
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            // Char literals
            pattern(.string, #"'(?:[^'\\]|\\.)+'"#),
            // Numbers
            pattern(.number, #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?[fFdDlL]?)\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:public|private|protected|static|final|abstract|class|interface|enum|extends|implements|new|return|if|else|for|while|do|switch|case|default|break|continue|try|catch|finally|throw|throws|import|package|void|int|long|short|byte|float|double|boolean|char|null|true|false|this|super|instanceof|synchronized|volatile|transient|native|strictfp|assert)\b"#),
            // Types
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Property access
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - Kotlin

    private var kotlinPatterns: [TokenPattern] {
        [
            // Single-line comments
            pattern(.comment, #"//[^\n]*"#),
            // Multi-line comments
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // String literals (including multiline)
            pattern(.string, #""""[\s\S]*?""""#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            // Numbers
            pattern(.number, #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?[fFdDlL]?)\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:fun|val|var|if|else|when|for|while|do|return|break|continue|class|object|interface|enum|sealed|data|open|abstract|override|private|protected|public|internal|final|companion|init|constructor|get|set|in|out|is|as|by|throw|try|catch|finally|import|package|typealias|inline|noinline|crossinline|reified|suspend|true|false|null|this|super|it)\b"#),
            // Types
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Property access
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - Ruby

    private var rubyPatterns: [TokenPattern] {
        [
            // Single-line comments
            pattern(.comment, #"#[^\n]*"#),
            // Multi-line string literals (heredoc simplified)
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            // Symbols
            pattern(.string, #":[a-zA-Z_][a-zA-Z0-9_]*"#),
            // Numbers
            pattern(.number, #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|0o[0-7_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?)\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:def|class|module|if|elsif|else|unless|case|when|then|end|do|begin|rescue|ensure|raise|return|break|next|redo|retry|yield|lambda|proc|require|require_relative|include|extend|attr_reader|attr_writer|attr_accessor|private|protected|public|self|super|nil|true|false|and|or|not|in|alias|defined\?)\b"#),
            // Types (constants)
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            // Property access
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_!?]*"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - Shell/Bash

    private var shellPatterns: [TokenPattern] {
        [
            // Shebang
            pattern(.comment, #"#![^\n]*"#),
            // Comments
            pattern(.comment, #"#[^\n]*"#),
            // Double-quoted strings
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            // Single-quoted strings
            pattern(.string, #"'[^']*'"#),
            // Numbers
            pattern(.number, #"\b\d+\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:if|then|else|elif|fi|for|do|done|while|until|case|esac|in|function|return|exit|break|continue|local|export|readonly|declare|typeset|unset|shift|source|alias|true|false)\b"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - SQL

    private var sqlPatterns: [TokenPattern] {
        [
            // Single-line comments
            pattern(.comment, #"--[^\n]*"#),
            // Multi-line comments
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // String literals
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            // Numbers
            pattern(.number, #"\b\d+\.?\d*\b"#),
            // Keywords (case-insensitive handled by regex)
            pattern(.keyword, #"(?i)\b(?:SELECT|FROM|WHERE|JOIN|INNER|LEFT|RIGHT|OUTER|ON|AND|OR|NOT|IN|IS|NULL|AS|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|ALTER|DROP|TABLE|INDEX|VIEW|DATABASE|PRIMARY|KEY|FOREIGN|REFERENCES|UNIQUE|DEFAULT|CHECK|CONSTRAINT|BETWEEN|LIKE|DISTINCT|COUNT|SUM|AVG|MIN|MAX|CASE|WHEN|THEN|ELSE|END|UNION|ALL|EXISTS|TRUE|FALSE)\b"#),
            // Types (table/column names starting with uppercase)
            pattern(.type, #"\b[A-Z][a-zA-Z0-9_]*\b"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - HTML

    private var htmlPatterns: [TokenPattern] {
        [
            // Comments
            pattern(.comment, #"<!--[\s\S]*?-->"#),
            // Attribute values
            pattern(.string, #""[^"]*""#),
            pattern(.string, #"'[^']*'"#),
            // Tag names (after < or </)
            pattern(.keyword, #"(?<=</?)[a-zA-Z][a-zA-Z0-9-]*"#),
            // Attribute names
            pattern(.property, #"\b[a-zA-Z][a-zA-Z0-9-]*(?=\s*=)"#),
            // Punctuation (including angle brackets)
            pattern(.punctuation, #"[<>{}()\[\];:,/?!=]"#),
        ]
    }

    // MARK: - CSS

    private var cssPatterns: [TokenPattern] {
        [
            // Comments
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            // String literals
            pattern(.string, #""[^"]*""#),
            pattern(.string, #"'[^']*'"#),
            // Colors
            pattern(.number, #"#[0-9a-fA-F]{3,8}\b"#),
            // Numbers with units
            pattern(.number, #"\b\d+\.?\d*(?:px|em|rem|%|vh|vw|pt|cm|mm|in|deg|rad|s|ms)?\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:important|inherit|initial|unset|none|auto|block|inline|flex|grid|absolute|relative|fixed|sticky|hidden|visible|solid|dashed|dotted|normal|bold|italic)\b"#),
            // Selectors (class and id)
            pattern(.type, #"[.#][a-zA-Z_][a-zA-Z0-9_-]*"#),
            // Property names
            pattern(.property, #"\b[a-zA-Z-]+(?=\s*:)"#),
            // Punctuation
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    // MARK: - JSON

    private var jsonPatterns: [TokenPattern] {
        [
            // String literals (keys and values)
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            // Numbers
            pattern(.number, #"-?\b\d+\.?\d*(?:[eE][+-]?\d+)?\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:true|false|null)\b"#),
            // Punctuation
            pattern(.punctuation, #"[{}\[\]:,]"#),
        ]
    }

    // MARK: - YAML

    private var yamlPatterns: [TokenPattern] {
        [
            // Comments
            pattern(.comment, #"#[^\n]*"#),
            // String literals
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            // Numbers
            pattern(.number, #"\b-?\d+\.?\d*\b"#),
            // Keywords
            pattern(.keyword, #"\b(?:true|false|null|yes|no|on|off)\b"#),
            // Keys
            pattern(.property, #"[a-zA-Z_][a-zA-Z0-9_]*(?=\s*:)"#),
            // Punctuation
            pattern(.punctuation, #"[{}\[\]:,>|&*-]"#),
        ]
    }

    private func pattern(_ kind: SyntaxTokenKind, _ pattern: String) -> TokenPattern {
        // Force try is acceptable here as patterns are compile-time constants
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: pattern)
        return TokenPattern(kind: kind, regex: regex)
    }
}
