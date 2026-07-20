import SwiftUI

/// ソースコードを非同期にハイライトできる型。
///
/// このプロトコルの実装はソースコードを受け取り、
/// シンタックスハイライトを適用した `AttributedString` を生成する。
///
/// デフォルト実装は ``PlainTextHighlighter`` で、カラー付けを行わない。
/// シンタックスハイライトを有効にするには `SwiftMarkdownViewHighlightJS` モジュールを使用する:
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// MarkdownView(source)
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
///
/// // またはアダプティブハイライトを使用
/// MarkdownView(source)
///     .adaptiveSyntaxHighlighting()   // 要 import SwiftMarkdownViewHighlightJS
/// ```
public protocol SyntaxHighlighter: Sendable {
    /// 指定したソースコードをハイライトする。
    ///
    /// - Parameters:
    ///   - code: ハイライト対象のソースコード。
    ///   - language: プログラミング言語（例: "swift"、"python"）。
    ///               `nil` の場合、ハイライターは自動検出を試みることがある。
    /// - Returns: シンタックスハイライトを適用した `AttributedString`。
    /// - Throws: ハイライトが失敗した場合にエラーをスローする。
    func highlight(_ code: String, language: String?) async throws -> AttributedString
}

// MARK: - Environment Key

/// カスタムシンタックスハイライターを注入するための環境キー。
private struct SyntaxHighlighterKey: EnvironmentKey {
    static let defaultValue: any SyntaxHighlighter = PlainTextHighlighter()
}

extension EnvironmentValues {
    /// コードハイライトに使用するシンタックスハイライター。
    ///
    /// カスタムハイライターをビュー階層に注入するには以下を使用する:
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownSyntaxHighlighter(CustomHighlighter())
    /// ```
    public var syntaxHighlighter: any SyntaxHighlighter {
        get { self[SyntaxHighlighterKey.self] }
        set { self[SyntaxHighlighterKey.self] = newValue }
    }
}

// MARK: - View Modifier

extension View {
    /// コードハイライト用のカスタムシンタックスハイライターを設定する。
    ///
    /// デフォルトではカラー付けなしの ``PlainTextHighlighter`` が使用される。
    /// シンタックスハイライトを有効にするにはこのモディファイアを使用する:
    ///
    /// ```swift
    /// import SwiftMarkdownViewHighlightJS
    ///
    /// MarkdownView(source)
    ///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
    /// ```
    ///
    /// - Parameter highlighter: 使用するハイライター。
    /// - Returns: カスタムハイライターが適用されたビュー。
    public func markdownSyntaxHighlighter(_ highlighter: some SyntaxHighlighter) -> some View {
        environment(\.syntaxHighlighter, highlighter)
    }

}
