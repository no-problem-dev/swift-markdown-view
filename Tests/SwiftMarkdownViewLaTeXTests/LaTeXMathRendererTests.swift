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

    // MARK: 実際にインクが乗っているか

    /// ディスプレイ数式は、正しい大きさの**完全に透明な**ビットマップを返していた。
    ///
    /// `LaTeXView` のディスプレイ側の body は横スクロールの `ScrollView` で包まれている。
    /// `ImageRenderer` は SwiftUI 自身が描くものしか描かず、`ScrollView` はプラットフォーム
    /// ビューに支えられているので、レイアウトだけされて中身が空のまま返る。
    /// 行は高さを確保し、何も描かない。
    ///
    /// 寸法とベースラインだけを見るテストはこれを全部通す。だから**不透明画素を数える**。
    @Test("数式のビットマップにインクが乗っている", arguments: [
        MarkdownAttachment.Kind.inlineMath(latex: "x^2"),
        .inlineMath(latex: "a \\neq 0"),
        .displayMath(latex: "x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}"),
        .displayMath(latex: "\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}"),
        .displayMath(latex: "E = mc^2")
    ])
    func rasterizedMathHasInk(kind: MarkdownAttachment.Kind) throws {
        let rendered = try #require(
            renderer.renderedImage(for: kind, theme: .default),
            "組版そのものが返らなかった"
        )
        let coverage = try #require(Self.inkCoverage(of: rendered.image), "ビットマップを読めない")

        // 数式のインクは面積のごく一部なので閾値は低く取る。見たいのは 0 でないこと。
        #expect(coverage > 0.005, "不透明画素 \(coverage * 100)% — 透明なビットマップ")
    }

    /// ディスプレイはディスプレイ組版で出す（総和記号の上下に limits、分数は原寸）。
    ///
    /// `ScrollView` を避けるために inline の body を通しているので、組版様式まで
    /// inline に落ちていないことを確かめる。ディスプレイ様式のほうが必ず背が高い。
    @Test("ディスプレイ数式はディスプレイ組版のままである")
    func displayMathKeepsDisplayStyleTypesetting() throws {
        let latex = "\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}"
        let display = try #require(renderer.renderedImage(for: .displayMath(latex: latex), theme: .default))
        let inline = try #require(renderer.renderedImage(for: .inlineMath(latex: latex), theme: .default))

        #expect(display.size.height > inline.size.height * 1.3,
                "display=\(display.size.height) inline=\(inline.size.height)")
    }

    /// 組版に失敗したときは `LaTeXView` が渡された文字列そのものを描く。
    /// ディスプレイ様式を頼むための `\displaystyle` を先に足していると、それが読者の
    /// 目に見えるテキストとして出てしまう。壊れた入力には足さない。
    @Test("組版できない入力に \\displaystyle を混ぜない")
    func malformedDisplayMathIsNotPrefixed() {
        #expect(LaTeXMathRenderer.source("\\frac{", mode: .display) == "\\frac{")
        #expect(LaTeXMathRenderer.source("E = mc^2", mode: .display) == "\\displaystyle E = mc^2")
        #expect(LaTeXMathRenderer.source("E = mc^2", mode: .inline) == "E = mc^2")
    }

    /// 不透明画素の割合。`nil` はビットマップを読めなかったとき。
    private static func inkCoverage(of image: PlatformImage) -> Double? {
        #if canImport(UIKit)
        guard let cgImage = image.cgImage else { return nil }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        #endif
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var opaque = 0
        for index in stride(from: 0, to: pixels.count, by: 4) where pixels[index + 3] > 8 {
            opaque += 1
        }
        return Double(opaque) / Double(width * height)
    }
}
#endif
