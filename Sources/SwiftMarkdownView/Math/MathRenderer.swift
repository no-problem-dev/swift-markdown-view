import SwiftUI
import DesignSystem

// MARK: - MathRenderer Protocol

/// Markdownコンテンツ内の数式をレンダリングする型。
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

    /// インライン数式を `Text` セグメントとしてレンダリングする。
    ///
    /// 結果は周囲の段落テキストと連結されるため、`Text` である必要がある
    ///（画像はベースラインオフセット付きの `Text(Image)` 補間で参加できる）。
    ///
    /// - Parameters:
    ///   - latex: デリミタなしの LaTeX ソース。
    ///   - palette: 環境から取得した現在のカラーパレット。
    @MainActor func inlineMath(_ latex: String, palette: any ColorPalette) -> Text

    /// 特定のフォントサイズでインライン数式をレンダリングする。
    ///
    /// 見出しやラベルなど非ボディテキストに埋め込まれた数式（``MathText`` 参照）に使用し、
    /// 周囲のフォントに合わせる。デフォルト実装はサイズを無視して
    /// ``inlineMath(_:palette:)`` にフォールバックする。
    @MainActor func inlineMath(_ latex: String, fontSize: CGFloat, palette: any ColorPalette) -> Text

    /// ディスプレイ数式をブロックビューとしてレンダリングする。
    ///
    /// - Parameter latex: デリミタなしの LaTeX ソース。
    @MainActor func displayMath(_ latex: String) -> AnyView
}

extension MathRenderer {

    @MainActor
    public func inlineMath(_ latex: String, fontSize: CGFloat, palette: any ColorPalette) -> Text {
        inlineMath(latex, palette: palette)
    }
}

// MARK: - PlainMathRenderer

/// 組版なしで LaTeX ソースを表示するデフォルト数式レンダラー。
///
/// インライン数式は等幅の `$...$` テキスト、ディスプレイ数式は `math` コードブロックとして表示する。
/// コアモジュールを依存なしに保ちつつ、グレースフルなデグレードを実現する。
public struct PlainMathRenderer: MathRenderer {

    public init() {}

    @MainActor
    public func inlineMath(_ latex: String, palette: any ColorPalette) -> Text {
        Text("$\(latex)$")
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(MarkdownColors.inlineCodeText(palette))
    }

    @MainActor
    public func displayMath(_ latex: String) -> AnyView {
        AnyView(CodeBlockView(language: "math", code: latex))
    }
}

// MARK: - Environment Key

private struct MathRendererKey: EnvironmentKey {
    static let defaultValue: any MathRenderer = PlainMathRenderer()
}

extension EnvironmentValues {

    /// 数式のレンダリングに使用するレンダラー。
    ///
    /// この値を設定するには ``SwiftUICore/View/mathRenderer(_:)`` モディファイアを使用する。
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

// MARK: - MathBlockView

/// 環境の数式レンダラーを使用してディスプレイ数式ブロックをレンダリングする。
struct MathBlockView: View {
    let latex: String

    @Environment(\.mathRenderer) private var renderer
    @Environment(\.markdownRenderingOptions) private var options

    var body: some View {
        if options.renderMath {
            renderer.displayMath(latex)
        } else {
            CodeBlockView(language: "math", code: latex)
        }
    }
}
