import SwiftUI
import DesignSystem

/// A SwiftUI view that renders syntax-highlighted code.
///
/// This view takes an array of syntax tokens and renders them as
/// concatenated `Text` views with appropriate colors from the
/// DesignSystem's ColorPalette.
///
/// Example:
/// ```swift
/// let tokens = tokenizer.tokenize(code, language: "swift")
/// HighlightedCodeView(tokens: tokens)
/// ```
public struct HighlightedCodeView: View {

    /// The tokens to render.
    private let tokens: [SyntaxToken]

    /// Optional custom syntax colors.
    private let customColors: SyntaxColors?

    @Environment(\.colorPalette) private var palette

    /// Creates a highlighted code view from tokens.
    ///
    /// - Parameters:
    ///   - tokens: The syntax tokens to render.
    ///   - colors: Optional custom syntax colors. If nil, derives from ColorPalette.
    public init(tokens: [SyntaxToken], colors: SyntaxColors? = nil) {
        self.tokens = tokens
        self.customColors = colors
    }

    public var body: some View {
        highlightedText
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
    }

    /// The concatenated text with syntax highlighting applied.
    private var highlightedText: Text {
        let colors = customColors ?? SyntaxColors(from: palette)

        return tokens.reduce(Text("")) { result, token in
            result + Text(token.text)
                .foregroundColor(colors.color(for: token.kind))
        }
    }
}

// MARK: - Convenience Initializer

extension HighlightedCodeView {

    /// Creates a highlighted code view by tokenizing the given code.
    ///
    /// - Parameters:
    ///   - code: The source code to highlight.
    ///   - language: The programming language for syntax rules.
    ///   - tokenizer: The tokenizer to use. Defaults to RegexSyntaxTokenizer.
    ///   - colors: Optional custom syntax colors.
    public init(
        code: String,
        language: String?,
        tokenizer: some SyntaxTokenizer = RegexSyntaxTokenizer(),
        colors: SyntaxColors? = nil
    ) {
        self.tokens = tokenizer.tokenize(code, language: language)
        self.customColors = colors
    }
}

// MARK: - Environment Key for Tokenizer

/// Environment key for injecting a custom syntax tokenizer.
private struct SyntaxTokenizerKey: EnvironmentKey {
    static let defaultValue: any SyntaxTokenizer = RegexSyntaxTokenizer()
}

extension EnvironmentValues {
    /// The syntax tokenizer used for code highlighting.
    public var syntaxTokenizer: any SyntaxTokenizer {
        get { self[SyntaxTokenizerKey.self] }
        set { self[SyntaxTokenizerKey.self] = newValue }
    }
}

// MARK: - View Modifier

public extension View {
    /// Sets a custom syntax tokenizer for code highlighting.
    ///
    /// - Parameter tokenizer: The tokenizer to use.
    /// - Returns: A view with the custom tokenizer applied.
    func syntaxTokenizer(_ tokenizer: some SyntaxTokenizer) -> some View {
        environment(\.syntaxTokenizer, tokenizer)
    }
}
