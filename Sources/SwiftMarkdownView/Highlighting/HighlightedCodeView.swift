import SwiftUI

/// シンタックスハイライトを非同期で適用してコードをレンダリングする SwiftUI ビュー。
///
/// 環境から注入した `SyntaxHighlighter` を使用してコードをハイライトし結果を表示する。
/// ローディング状態とエラー状態を適切に処理する。
///
/// Example:
/// ```swift
/// HighlightedCodeView(code: swiftCode, language: "swift")
/// ```
///
/// カスタムハイライターを使用する場合:
/// ```swift
/// HighlightedCodeView(code: swiftCode, language: "swift")
///     .markdownSyntaxHighlighter(HighlightJSSyntaxHighlighter())
/// ```
public struct HighlightedCodeView: View {

    /// ハイライト対象のソースコード。
    public let code: String

    /// シンタックスルールに使用するプログラミング言語。
    public let language: String?

    @Environment(\.syntaxHighlighter) private var highlighter
    @Environment(\.markdownPalette) private var palette

    @State private var state: HighlightState = .idle

    /// ハイライト済みコードビューを生成する。
    ///
    /// - Parameters:
    ///   - code: ハイライト対象のソースコード。
    ///   - language: プログラミング言語（例: "swift"、"python"）。
    public init(code: String, language: String?) {
        self.code = code
        self.language = language
    }

    public var body: some View {
        content
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .task(id: TaskIdentifier(code: code, language: language)) {
                await performHighlighting()
            }
    }

    // MARK: - Private

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .loading:
            // Show plain text during loading for smooth transition
            Text(code)
                .foregroundStyle(palette.text)

        case .success(let attributed):
            Text(attributed)

        case .failure:
            // Fallback to plain text on error
            Text(code)
                .foregroundStyle(palette.text)
        }
    }

    private func performHighlighting() async {
        state = .loading

        do {
            let result = try await highlighter.highlight(code, language: language)
            state = .success(result)
        } catch {
            state = .failure(error)
        }
    }
}

// MARK: - Task Identifier

extension HighlightedCodeView {
    /// タスク無効化のための Hashable 識別子。
    private struct TaskIdentifier: Hashable {
        let code: String
        let language: String?
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Swift Code") {
    HighlightedCodeView(
        code: """
        func greet(_ name: String) -> String {
            return "Hello, \\(name)!"
        }

        let message = greet("World")
        print(message)
        """,
        language: "swift"
    )
    .padding()
}

#Preview("Python Code") {
    HighlightedCodeView(
        code: """
        def greet(name: str) -> str:
            return f"Hello, {name}!"

        message = greet("World")
        print(message)
        """,
        language: "python"
    )
    .padding()
}
#endif
