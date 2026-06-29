import SwiftUI

/// シンタックスハイライトを適用しないプレーンテキストハイライター。
///
/// デフォルトのハイライター。コードをカラー書式なしのプレーンテキストとして返す。
/// 以下のケースで使用する:
/// - コードブロックのスタイリングを最小限にしたい場合
/// - シンタックスハイライトが不要な場合
/// - ユーザーがハイライトをオプトインする設計にしたい場合
///
/// シンタックスハイライトを有効にするには、カスタムハイライターを注入する:
///
/// ```swift
/// import SwiftMarkdownViewHighlightJS
///
/// MarkdownView(source)
///     .syntaxHighlighter(HighlightJSSyntaxHighlighter())
///
/// // または自動ライト/ダーク対応のアダプティブハイライトを使用
/// MarkdownView(source)
///     .adaptiveSyntaxHighlighting()
/// ```
public struct PlainTextHighlighter: SyntaxHighlighter, Sendable {

    /// プレーンテキストハイライターを生成する。
    public init() {}

    /// コードをカラー書式なしのプレーンテキストとして返す。
    ///
    /// - Parameters:
    ///   - code: ハイライト対象のソースコード。
    ///   - language: プログラミング言語。このハイライターでは使用しない。
    /// - Returns: 書式なしの `AttributedString`。
    public func highlight(_ code: String, language: String?) async throws -> AttributedString {
        AttributedString(code)
    }
}
