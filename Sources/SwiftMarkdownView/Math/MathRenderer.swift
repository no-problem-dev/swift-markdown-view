import SwiftUI
import MarkdownAttributedKit

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
///
/// TextKit のアタッチメント描画（ディスプレイ数式の画像化）も同じ実装が担うため、
/// ``MarkdownAttachmentRendering`` を継承する。以前は無関係な 2 プロトコルを
/// 実行時の `as?` で繋いでおり、**自作レンダラーを注入しても無言で無視されて
/// 数式が `$latex$` のまま表示される**という失敗の仕方をした。継承にすることで
/// 適合漏れがコンパイルエラーになる。
///
/// 数式を組版しない実装は ``MarkdownAttachmentRendering/renderedImage(for:theme:)``
/// で `nil` を返せばよい（``PlainMathRenderer`` がそうしている）。読み取り可能な
/// フォールバックテキストに落ちる。
public protocol MathRenderer: MarkdownAttachmentRendering, Sendable {

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

    /// 組版しないので画像は返さない。呼び出し側が `$latex$` のテキストに落とす。
    public func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage? {
        nil
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
}
