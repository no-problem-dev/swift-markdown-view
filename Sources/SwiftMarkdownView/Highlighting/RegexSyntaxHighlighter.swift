import SwiftUI
import DesignSystem

/// A regex-based syntax highlighter for basic highlighting without external dependencies.
///
/// This highlighter provides syntax highlighting using regular expressions.
/// It prioritizes simplicity and zero dependencies over perfect accuracy.
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
public struct RegexSyntaxHighlighter: SyntaxHighlighter, Sendable {

    /// The syntax colors to apply.
    private let colors: SyntaxColorScheme

    /// Creates a regex-based syntax highlighter.
    ///
    /// - Parameter colors: The color scheme to use. Defaults to adaptive light/dark.
    public init(colors: SyntaxColorScheme = .adaptive) {
        self.colors = colors
    }

    public func highlight(_ code: String, language: String?) async throws -> AttributedString {
        guard !code.isEmpty else { return AttributedString() }

        let lang = language?.lowercased() ?? ""
        let patterns = tokenPatterns(for: lang)
        let tokens = tokenize(code: code, patterns: patterns)

        return buildAttributedString(from: tokens)
    }

    // MARK: - Private Types

    private enum TokenKind: Sendable {
        case plain
        case keyword
        case string
        case comment
        case number
        case type
        case property
        case punctuation
    }

    private struct Token: Sendable {
        let text: String
        let kind: TokenKind
    }

    private struct TokenPattern: Sendable {
        let kind: TokenKind
        let regex: NSRegularExpression
    }

    // MARK: - Tokenization

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

    private func tokenize(code: String, patterns: [TokenPattern]) -> [Token] {
        var tokens: [Token] = []
        var currentIndex = code.startIndex

        while currentIndex < code.endIndex {
            var matched = false

            for pattern in patterns {
                let range = NSRange(currentIndex..<code.endIndex, in: code)

                if let match = pattern.regex.firstMatch(in: code, range: range),
                   match.range.location == NSRange(currentIndex..<code.endIndex, in: code).location {

                    if let matchRange = Range(match.range, in: code) {
                        let text = String(code[matchRange])
                        tokens.append(Token(text: text, kind: pattern.kind))
                        currentIndex = matchRange.upperBound
                        matched = true
                        break
                    }
                }
            }

            if !matched {
                let nextIndex = code.index(after: currentIndex)
                let text = String(code[currentIndex..<nextIndex])
                tokens.append(Token(text: text, kind: .plain))
                currentIndex = nextIndex
            }
        }

        return mergeAdjacentPlainTokens(tokens)
    }

    private func mergeAdjacentPlainTokens(_ tokens: [Token]) -> [Token] {
        var result: [Token] = []

        for token in tokens {
            if let last = result.last, last.kind == .plain && token.kind == .plain {
                result[result.count - 1] = Token(
                    text: last.text + token.text,
                    kind: .plain
                )
            } else {
                result.append(token)
            }
        }

        return result
    }

    // MARK: - AttributedString Building

    private func buildAttributedString(from tokens: [Token]) -> AttributedString {
        var result = AttributedString()

        for token in tokens {
            var attributed = AttributedString(token.text)
            attributed.foregroundColor = color(for: token.kind)
            result.append(attributed)
        }

        return result
    }

    private func color(for kind: TokenKind) -> Color {
        switch kind {
        case .keyword: return colors.keyword
        case .string: return colors.string
        case .comment: return colors.comment
        case .number: return colors.number
        case .type: return colors.type
        case .property: return colors.property
        case .punctuation: return colors.punctuation
        case .plain: return colors.plain
        }
    }

    // MARK: - Language Patterns

    private var swiftPatterns: [TokenPattern] {
        [
            pattern(.comment, #"//[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.number, #"\b(?:0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b"#),
            pattern(.keyword, #"\b(?:func|let|var|if|else|guard|switch|case|default|for|while|repeat|return|break|continue|throw|throws|try|catch|defer|do|import|struct|class|enum|protocol|extension|typealias|associatedtype|init|deinit|self|Self|super|nil|true|false|static|private|fileprivate|internal|public|open|final|override|mutating|nonmutating|lazy|weak|unowned|inout|async|await|actor|some|any|where|in|is|as)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var typescriptPatterns: [TokenPattern] {
        [
            pattern(.comment, #"//[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #"`(?:[^`\\]|\\.)*`"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            pattern(.number, #"\b(?:0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b"#),
            pattern(.keyword, #"\b(?:function|const|let|var|if|else|switch|case|default|for|while|do|return|break|continue|throw|try|catch|finally|new|delete|typeof|instanceof|void|this|super|class|extends|implements|interface|type|enum|namespace|module|export|import|from|as|async|await|yield|static|public|private|protected|readonly|abstract|get|set|true|false|null|undefined|NaN|Infinity)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var pythonPatterns: [TokenPattern] {
        [
            pattern(.comment, #"#[^\n]*"#),
            pattern(.string, #"\"\"\"[\s\S]*?\"\"\""#),
            pattern(.string, #"'''[\s\S]*?'''"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            pattern(.number, #"\b(?:0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b"#),
            pattern(.keyword, #"\b(?:def|class|if|elif|else|for|while|try|except|finally|with|as|import|from|return|yield|raise|break|continue|pass|lambda|and|or|not|in|is|True|False|None|async|await|global|nonlocal)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var goPatterns: [TokenPattern] {
        [
            pattern(.comment, #"//[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #"`[^`]*`"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.number, #"\b(?:0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b"#),
            pattern(.keyword, #"\b(?:func|package|import|if|else|for|range|return|defer|go|chan|select|switch|case|default|break|continue|fallthrough|goto|var|const|type|struct|interface|map|make|new|append|len|cap|copy|delete|panic|recover|nil|true|false|iota)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var rustPatterns: [TokenPattern] {
        [
            pattern(.comment, #"//[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)+'"#),
            pattern(.number, #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|0o[0-7_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?)\b"#),
            pattern(.keyword, #"\b(?:fn|let|mut|if|else|match|loop|while|for|in|break|continue|return|pub|struct|enum|impl|trait|type|mod|use|crate|super|self|Self|const|static|ref|move|async|await|dyn|extern|unsafe|where|as|true|false|Some|None|Ok|Err)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var javaPatterns: [TokenPattern] {
        [
            pattern(.comment, #"//[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)+'"#),
            pattern(.number, #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?[fFdDlL]?)\b"#),
            pattern(.keyword, #"\b(?:public|private|protected|static|final|abstract|class|interface|enum|extends|implements|new|return|if|else|for|while|do|switch|case|default|break|continue|try|catch|finally|throw|throws|import|package|void|int|long|short|byte|float|double|boolean|char|null|true|false|this|super|instanceof|synchronized|volatile|transient|native|strictfp|assert)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var kotlinPatterns: [TokenPattern] {
        [
            pattern(.comment, #"//[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #""""[\s\S]*?""""#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.number, #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?[fFdDlL]?)\b"#),
            pattern(.keyword, #"\b(?:fun|val|var|if|else|when|for|while|do|return|break|continue|class|object|interface|enum|sealed|data|open|abstract|override|private|protected|public|internal|final|companion|init|constructor|get|set|in|out|is|as|by|throw|try|catch|finally|import|package|typealias|inline|noinline|crossinline|reified|suspend|true|false|null|this|super|it)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_]*"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var rubyPatterns: [TokenPattern] {
        [
            pattern(.comment, #"#[^\n]*"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            pattern(.string, #":[a-zA-Z_][a-zA-Z0-9_]*"#),
            pattern(.number, #"\b(?:0x[0-9a-fA-F_]+|0b[01_]+|0o[0-7_]+|\d[\d_]*\.?[\d_]*(?:[eE][+-]?\d+)?)\b"#),
            pattern(.keyword, #"\b(?:def|class|module|if|elsif|else|unless|case|when|then|end|do|begin|rescue|ensure|raise|return|break|next|redo|retry|yield|lambda|proc|require|require_relative|include|extend|attr_reader|attr_writer|attr_accessor|private|protected|public|self|super|nil|true|false|and|or|not|in|alias|defined\?)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.property, #"\.[a-zA-Z_][a-zA-Z0-9_!?]*"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var shellPatterns: [TokenPattern] {
        [
            pattern(.comment, #"#![^\n]*"#),
            pattern(.comment, #"#[^\n]*"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'[^']*'"#),
            pattern(.number, #"\b\d+\b"#),
            pattern(.keyword, #"\b(?:if|then|else|elif|fi|for|do|done|while|until|case|esac|in|function|return|exit|break|continue|local|export|readonly|declare|typeset|unset|shift|source|alias|true|false)\b"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var sqlPatterns: [TokenPattern] {
        [
            pattern(.comment, #"--[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            pattern(.number, #"\b\d+\.?\d*\b"#),
            pattern(.keyword, #"(?i)\b(?:SELECT|FROM|WHERE|JOIN|INNER|LEFT|RIGHT|OUTER|ON|AND|OR|NOT|IN|IS|NULL|AS|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|ALTER|DROP|TABLE|INDEX|VIEW|DATABASE|PRIMARY|KEY|FOREIGN|REFERENCES|UNIQUE|DEFAULT|CHECK|CONSTRAINT|BETWEEN|LIKE|DISTINCT|COUNT|SUM|AVG|MIN|MAX|CASE|WHEN|THEN|ELSE|END|UNION|ALL|EXISTS|TRUE|FALSE)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9_]*\b"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var htmlPatterns: [TokenPattern] {
        [
            pattern(.comment, #"<!--[\s\S]*?-->"#),
            pattern(.string, #""[^"]*""#),
            pattern(.string, #"'[^']*'"#),
            pattern(.keyword, #"(?<=</?)[a-zA-Z][a-zA-Z0-9-]*"#),
            pattern(.property, #"\b[a-zA-Z][a-zA-Z0-9-]*(?=\s*=)"#),
            pattern(.punctuation, #"[<>{}()\[\];:,/?!=]"#),
        ]
    }

    private var cssPatterns: [TokenPattern] {
        [
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #""[^"]*""#),
            pattern(.string, #"'[^']*'"#),
            pattern(.number, #"#[0-9a-fA-F]{3,8}\b"#),
            pattern(.number, #"\b\d+\.?\d*(?:px|em|rem|%|vh|vw|pt|cm|mm|in|deg|rad|s|ms)?\b"#),
            pattern(.keyword, #"\b(?:important|inherit|initial|unset|none|auto|block|inline|flex|grid|absolute|relative|fixed|sticky|hidden|visible|solid|dashed|dotted|normal|bold|italic)\b"#),
            pattern(.type, #"[.#][a-zA-Z_][a-zA-Z0-9_-]*"#),
            pattern(.property, #"\b[a-zA-Z-]+(?=\s*:)"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private var jsonPatterns: [TokenPattern] {
        [
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.number, #"-?\b\d+\.?\d*(?:[eE][+-]?\d+)?\b"#),
            pattern(.keyword, #"\b(?:true|false|null)\b"#),
            pattern(.punctuation, #"[{}\[\]:,]"#),
        ]
    }

    private var yamlPatterns: [TokenPattern] {
        [
            pattern(.comment, #"#[^\n]*"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            pattern(.number, #"\b-?\d+\.?\d*\b"#),
            pattern(.keyword, #"\b(?:true|false|null|yes|no|on|off)\b"#),
            pattern(.property, #"[a-zA-Z_][a-zA-Z0-9_]*(?=\s*:)"#),
            pattern(.punctuation, #"[{}\[\]:,>|&*-]"#),
        ]
    }

    private var genericPatterns: [TokenPattern] {
        [
            pattern(.comment, #"//[^\n]*"#),
            pattern(.comment, #"/\*[\s\S]*?\*/"#),
            pattern(.string, #""(?:[^"\\]|\\.)*""#),
            pattern(.string, #"'(?:[^'\\]|\\.)*'"#),
            pattern(.number, #"\b\d+\.?\d*\b"#),
            pattern(.keyword, #"\b(?:if|else|for|while|return|function|class|const|let|var|true|false|null)\b"#),
            pattern(.type, #"\b[A-Z][a-zA-Z0-9]*\b"#),
            pattern(.punctuation, #"[{}()\[\];:,.<>?!@#$%^&*+=|/\\~-]"#),
        ]
    }

    private func pattern(_ kind: TokenKind, _ pattern: String) -> TokenPattern {
        // swiftlint:disable:next force_try
        let regex = try! NSRegularExpression(pattern: pattern)
        return TokenPattern(kind: kind, regex: regex)
    }
}

// MARK: - Syntax Color Scheme

/// Color scheme for syntax highlighting.
public struct SyntaxColorScheme: Sendable {
    public let keyword: Color
    public let string: Color
    public let comment: Color
    public let number: Color
    public let type: Color
    public let property: Color
    public let punctuation: Color
    public let plain: Color

    /// Creates a custom color scheme.
    public init(
        keyword: Color,
        string: Color,
        comment: Color,
        number: Color,
        type: Color,
        property: Color,
        punctuation: Color,
        plain: Color
    ) {
        self.keyword = keyword
        self.string = string
        self.comment = comment
        self.number = number
        self.type = type
        self.property = property
        self.punctuation = punctuation
        self.plain = plain
    }

    /// Adaptive color scheme that works in light and dark modes.
    public static let adaptive = SyntaxColorScheme(
        keyword: Color.purple,
        string: Color.orange,
        comment: Color.gray,
        number: Color.blue,
        type: Color.teal,
        property: Color.cyan,
        punctuation: Color.secondary,
        plain: Color.primary
    )

    /// Light mode optimized colors.
    public static let light = SyntaxColorScheme(
        keyword: Color(red: 0.61, green: 0.12, blue: 0.70),
        string: Color(red: 0.76, green: 0.24, blue: 0.16),
        comment: Color(red: 0.45, green: 0.45, blue: 0.45),
        number: Color(red: 0.11, green: 0.44, blue: 0.69),
        type: Color(red: 0.20, green: 0.50, blue: 0.60),
        property: Color(red: 0.30, green: 0.45, blue: 0.55),
        punctuation: Color(red: 0.30, green: 0.30, blue: 0.30),
        plain: Color(red: 0.13, green: 0.13, blue: 0.13)
    )

    /// Dark mode optimized colors.
    public static let dark = SyntaxColorScheme(
        keyword: Color(red: 0.78, green: 0.56, blue: 0.89),
        string: Color(red: 0.95, green: 0.55, blue: 0.46),
        comment: Color(red: 0.55, green: 0.55, blue: 0.55),
        number: Color(red: 0.55, green: 0.78, blue: 0.93),
        type: Color(red: 0.60, green: 0.80, blue: 0.75),
        property: Color(red: 0.65, green: 0.75, blue: 0.85),
        punctuation: Color(red: 0.70, green: 0.70, blue: 0.70),
        plain: Color(red: 0.90, green: 0.90, blue: 0.90)
    )
}
