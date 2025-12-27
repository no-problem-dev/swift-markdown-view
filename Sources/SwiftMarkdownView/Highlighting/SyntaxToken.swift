import Foundation

/// The kind of syntax token for highlighting purposes.
///
/// Each kind maps to a specific color in the syntax highlighting theme.
public enum SyntaxTokenKind: String, Sendable, Equatable, CaseIterable {
    /// Plain text without special highlighting.
    case plain
    /// Language keywords (func, let, const, if, etc.).
    case keyword
    /// String literals ("hello", 'world', `template`).
    case string
    /// Comments (// single-line, /* multi-line */).
    case comment
    /// Numeric literals (42, 3.14, 0xFF).
    case number
    /// Type names (String, Int, Array).
    case type
    /// Property access (.count, .length).
    case property
    /// Punctuation and operators ({ } ( ) [ ] ; + - =).
    case punctuation
}

/// A token representing a piece of code with its syntax kind.
///
/// Tokens are produced by a `SyntaxTokenizer` and consumed by
/// the rendering layer to apply appropriate colors.
public struct SyntaxToken: Sendable, Equatable {
    /// The text content of this token.
    public let text: String

    /// The syntactic kind of this token.
    public let kind: SyntaxTokenKind

    /// Creates a new syntax token.
    ///
    /// - Parameters:
    ///   - text: The text content.
    ///   - kind: The syntactic kind.
    public init(text: String, kind: SyntaxTokenKind) {
        self.text = text
        self.kind = kind
    }
}
