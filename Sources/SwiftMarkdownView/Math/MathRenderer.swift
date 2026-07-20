import SwiftUI

// MARK: - MathRenderer Protocol

/// Markdown コンテンツ内の数式をレンダリングする型。
///
/// コアモジュールは LaTeX ソースを組版なしで表示する ``PlainMathRenderer`` を同梱する。
/// 本格的な組版を行うには `SwiftMarkdownViewLaTeX` モジュールを追加して
/// `LaTeXMathRenderer` を注入する:
///
/// ```swift
/// MarkdownView(source)
///     .markdownMathRenderer(LaTeXMathRenderer())
/// ```
///
/// ``SyntaxHighlighter`` パターンを踏襲し、コアは依存なしのままで
/// 実装を環境経由で注入する設計。
public protocol MathRenderer: Sendable {

    /// 数式を `Text` セグメントとしてレンダリングする。
    ///
    /// 結果は周囲の段落テキストと連結されるため、`Text` である必要がある
    ///（画像はベースラインオフセット付きの `Text(Image)` 補間で参加できる）。
    ///
    /// - Parameters:
    ///   - latex: デリミタなしの LaTeX ソース。
    ///   - fontSize: 周囲のテキストのポイントサイズ。`nil` ならレンダラー自身の既定を使う。
    ///   - textColor: 周囲のテキストの色。
    @MainActor func inlineMath(_ latex: String, fontSize: CGFloat?, textColor: Color) -> Text
}

// MARK: - PlainMathRenderer

/// 組版なしで LaTeX ソースを表示する既定の数式レンダラー。
///
/// 数式は等幅の `$...$` テキストとして表示する。
/// コアモジュールを依存なしに保ちつつ、グレースフルなデグレードを実現する。
public struct PlainMathRenderer: MathRenderer {

    public init() {}

    @MainActor
    public func inlineMath(_ latex: String, fontSize: CGFloat?, textColor: Color) -> Text {
        Text("$\(latex)$")
            .font(.system(size: fontSize ?? 17, design: .monospaced))
            .foregroundStyle(textColor)
    }
}

// MARK: - Environment Key

private struct MathRendererKey: EnvironmentKey {
    static let defaultValue: any MathRenderer = PlainMathRenderer()
}

extension EnvironmentValues {

    /// 数式のレンダリングに使用するレンダラー。
    ///
    /// この値を設定するには ``SwiftUICore/View/markdownMathRenderer(_:)`` モディファイアを使用する。
    public var mathRenderer: any MathRenderer {
        get { self[MathRendererKey.self] }
        set { self[MathRendererKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層にカスタム数式レンダラーを設定する。
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("The identity $e^{i\\pi} + 1 = 0$ holds.")
    ///     .markdownMathRenderer(LaTeXMathRenderer())
    /// ```
    ///
    /// - Parameter renderer: 使用する数式レンダラー。
    /// - Returns: 数式レンダラーが適用されたビュー。
    public func markdownMathRenderer(_ renderer: some MathRenderer) -> some View {
        environment(\.mathRenderer, renderer)
    }

    @available(*, deprecated, renamed: "markdownMathRenderer(_:)")
    public func mathRenderer(_ renderer: some MathRenderer) -> some View {
        markdownMathRenderer(renderer)
    }
}
