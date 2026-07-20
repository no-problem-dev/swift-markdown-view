#if os(iOS) || os(macOS)
import Testing
import SwiftUI
@testable import SwiftMarkdownViewLaTeX
@testable import SwiftMarkdownView
@testable import MarkdownAttributedKit

/// 数式レンダラの入力耐性。
///
/// LaTeX はドキュメント由来の文字列で、LLM 出力では閉じ忘れや空の数式が普通に混ざる。
/// 組版に失敗すること自体は許容されるが、クラッシュ・ハング・nil の伝播漏れは許容されない。
@Suite("LaTeXMathRenderer の入力耐性")
@MainActor
struct LaTeXMathRendererTests {

    private let renderer = LaTeXMathRenderer()
    private let textColor = Color.primary

    /// 組版に失敗しても Text を返すこと（呼び出し側は非 Optional を期待している）。
    @Test("不正な LaTeX でもインライン描画が返る", arguments: [
        "",
        "\\frac{",
        "$$$$",
        "\\begin{matrix}",
        "\\undefinedcommand{x}",
        "x^{2",
        "\\\\",
        String(repeating: "\\frac{1}{2}", count: 200)
    ])
    func inlineMathSurvivesMalformedInput(latex: String) {
        _ = renderer.inlineMath(latex, fontSize: nil, textColor: textColor)
        _ = renderer.inlineMath(latex, fontSize: 17, textColor: textColor)
    }

    @Test("不正な LaTeX でもディスプレイ描画がクラッシュしない", arguments: [
        "",
        "\\frac{",
        "\\begin{matrix}",
        "x^{2"
    ])
    func displayMathSurvivesMalformedInput(latex: String) {
        _ = renderer.renderedImage(for: .displayMath(latex: latex), theme: .default)
    }

    // MARK: アタッチメント描画

    @Test("画像・Mermaid のアタッチメントは扱わない")
    func ignoresNonMathAttachments() {
        #expect(renderer.renderedImage(for: .image(source: "x.png", alt: "x"), theme: .default) == nil)
        #expect(renderer.renderedImage(for: .mermaid(source: "graph TD;"), theme: .default) == nil)
    }

    @Test("インライン数式のアタッチメントはベースラインを持ち上げる")
    func inlineAttachmentIsBaselineAdjusted() {
        guard let rendered = renderer.renderedImage(for: .inlineMath(latex: "x^2"), theme: .default) else {
            // 組版に失敗する環境（フォント未解決など）ではスキップする。
            return
        }
        // インラインは周囲テキストと揃えるため負のオフセットを持つ。
        #expect(rendered.baselineOffset < 0)
        #expect(rendered.size.width > 0)
        #expect(rendered.size.height > 0)
    }

    @Test("ディスプレイ数式のアタッチメントはベースラインを動かさない")
    func displayAttachmentKeepsBaseline() {
        guard let rendered = renderer.renderedImage(for: .displayMath(latex: "x^2"), theme: .default) else {
            return
        }
        #expect(rendered.baselineOffset == 0)
    }

    @Test("空の数式でもアタッチメント描画がクラッシュしない")
    func emptyMathAttachmentDoesNotCrash() {
        _ = renderer.renderedImage(for: .inlineMath(latex: ""), theme: .default)
        _ = renderer.renderedImage(for: .displayMath(latex: ""), theme: .default)
    }
}
#endif
