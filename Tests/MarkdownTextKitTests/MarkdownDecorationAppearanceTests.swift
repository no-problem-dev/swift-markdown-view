#if canImport(UIKit)
import Testing
import UIKit
@testable import MarkdownTextKit
import MarkdownAttributedKit

/// 装飾の色が、画面の明暗に本文と同じだけ追従するか。
///
/// `CGColor` は具体的な色で、動的な `UIColor` から取り出した瞬間にそのときの
/// `UITraitCollection.current` で解決されて固まる。パレットを組み立てるのは
/// `makeUIView` / `updateUIView` で、そこの current はテキストビューのものではない。
/// 固めてしまうと本文だけがダークに追従し、罫線・引用バー・コード背景はライトのまま残る。
///
/// 各ケースは装飾ひとつだけを描く（本文は透明にする）ので、残った画素は装飾そのもの。
/// 本文の色が明暗で変わることも併せて確かめる — こちらが変わらないなら描画の取り方が
/// 間違っているのであって、装飾が固まっている証拠にはならない。
@Suite("装飾の色が画面の明暗に追従する")
@MainActor
struct MarkdownDecorationAppearanceTests {

    // MARK: - 各スロット

    @Test("引用バーの色が明暗で変わる")
    func quoteBarFollowsAppearance() {
        expectInkDiffers(between: inkInBothAppearances(document: blockQuoteDocument()), named: "引用バー")
    }

    @Test("罫線の色が明暗で変わる")
    func thematicBreakFollowsAppearance() {
        expectInkDiffers(between: inkInBothAppearances(document: thematicBreakDocument()), named: "罫線")
    }

    @Test("コードブロック背景の色が明暗で変わる")
    func codeBackgroundFollowsAppearance() {
        expectInkDiffers(between: inkInBothAppearances(document: codeBlockDocument()), named: "コード背景")
    }

    /// 描画の取り方そのものが明暗を反映しているか。
    ///
    /// 本文の色は属性文字列に動的な `UIColor` として載り、TextKit が描画時に解決する。
    /// ここが変わらないなら、上の3つが変わらなくても「固まっている」ことの証明にならない。
    @Test("本文の色は明暗で変わる（描画の取り方の目盛り）")
    func bodyTextFollowsAppearance() {
        expectInkDiffers(between: inkInBothAppearances(document: bodyTextDocument()), named: "本文")
    }

    // MARK: - 切り替え後の塗り直し

    /// コード背景は `CAShapeLayer` の `fillColor`、つまり `CGColor` でしか持てない。
    /// `layoutSubviews` は見た目が変わっただけでは呼ばれないので、明暗が動いたら
    /// 塗り直す仕掛けが要る。無いと最初に置いた色のまま残る。
    @Test("見た目が変わればコード背景レイヤーが塗り直される")
    func codeBackgroundLayerIsRepaintedOnAppearanceChange() {
        let host = Host(style: .light, document: codeBlockDocument())
        let before = host.codeBackgroundFill

        host.textView.overrideUserInterfaceStyle = .dark
        host.textView.layoutIfNeeded()
        let after = host.codeBackgroundFill

        #expect(before != nil)
        #expect(before != after, "レイヤーの塗りが \(String(describing: before)) のまま変わっていない")
    }

    /// フラグメントが描く側（引用バー）の、切り替え後。
    ///
    /// 報告された壊れ方は「ダークにしたあとも前の色で描き続ける」だった。上の各スロットの
    /// テストは明暗それぞれで作り直しているので、作り直さずに切り替えたときは別に見る。
    @Test("見た目が変わった後の再描画で引用バーの色が変わる")
    func quoteBarIsRedrawnAfterAppearanceChange() {
        let host = Host(style: .light, document: blockQuoteDocument())
        let before = host.inkColor

        host.window.overrideUserInterfaceStyle = .dark
        host.textView.layoutIfNeeded()
        let after = host.inkColor

        expectInkDiffers(between: (before, after), named: "引用バー（切り替え後）")
    }

    // MARK: - 素材

    private func theme() -> MarkdownTextTheme { .default }

    private func decorated(
        _ text: String,
        kind: MarkdownBlockDecoration.Kind,
        foreground: UIColor
    ) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.headIndent = theme().indentStep
        paragraph.firstLineHeadIndent = theme().indentStep
        let out = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: theme().baseFont,
                .foregroundColor: foreground,
                .paragraphStyle: paragraph
            ]
        )
        out.addAttribute(
            .markdownBlockDecoration,
            value: MarkdownBlockDecoration(kind),
            range: NSRange(location: 0, length: out.length)
        )
        return out
    }

    /// 引用だけ。本文は透明なので、残る画素は引用バーだけになる。
    private func blockQuoteDocument() -> NSAttributedString {
        decorated("quoted line\nquoted line\n", kind: .blockQuote(level: 1), foreground: .clear)
    }

    private func thematicBreakDocument() -> NSAttributedString {
        decorated("\u{00A0}\n", kind: .thematicBreak, foreground: .clear)
    }

    private func codeBlockDocument() -> NSAttributedString {
        decorated("let x = 1\nlet y = 2\n", kind: .codeBlock(language: "swift"), foreground: .clear)
    }

    /// 装飾のない素の本文。テーマの文字色で描く。
    private func bodyTextDocument() -> NSAttributedString {
        NSAttributedString(
            string: "The quick brown fox\njumps over the lazy dog\n",
            attributes: [.font: theme().baseFont, .foregroundColor: theme().textColor]
        )
    }

    // MARK: - 描画して色を取り出す

    /// 明暗それぞれで描いて、描かれた色を返す。
    private func inkInBothAppearances(document: NSAttributedString) -> (Ink?, Ink?) {
        (Host(style: .light, document: document).inkColor,
         Host(style: .dark, document: document).inkColor)
    }

    /// 二つの色が「別の色」と言える程度に離れているか。
    ///
    /// 丸めと色空間の変換で 1〜2 はずれる。固まっていれば 0 に張り付くので、
    /// 8 を超えたかどうかで分ける。既定テーマで一番差が小さい罫線でも 60 → 84 ある。
    private func expectInkDiffers(between pair: (Ink?, Ink?), named name: String) {
        guard let light = pair.0, let dark = pair.1 else {
            Issue.record("\(name)が描かれていない（light \(String(describing: pair.0)) / dark \(String(describing: pair.1))）")
            return
        }
        #expect(light.distance(to: dark) > 8, "\(name)が light \(light) / dark \(dark) で同じ色のまま")
    }

    /// 描かれた色。アルファは被覆率と混ざるので持たない。
    struct Ink: CustomStringConvertible, Equatable {
        var red: Int
        var green: Int
        var blue: Int

        func distance(to other: Ink) -> Int {
            max(abs(red - other.red), abs(green - other.green), abs(blue - other.blue))
        }

        var description: String { "rgb(\(red),\(green),\(blue))" }
    }

    /// ウインドウに載せたテキストビュー一式。実際に画面へ出す経路で描かせるための足場。
    @MainActor
    private final class Host {
        let window: UIWindow
        let textView: MarkdownTextView
        private let provider = MarkdownLayoutFragmentProvider()

        init(style: UIUserInterfaceStyle, document: NSAttributedString) {
            let theme = MarkdownTextTheme.default
            let palette = MarkdownDecorationPalette(theme: theme)
            textView = MarkdownTextViewFactory.make()
            textView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
            // 罫線と引用バーはフラグメントが描くのでプロバイダー側、コード背景は
            // テキストビュー下のレイヤーが塗るのでビュー側。両方に要る。
            provider.palette = palette
            MarkdownTextViewFactory.setFragmentProvider(provider, on: textView)
            MarkdownTextViewFactory.setDecorationPalette(palette, on: textView)
            MarkdownTextViewFactory.apply(document, to: textView)

            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
            window.overrideUserInterfaceStyle = style
            window.addSubview(textView)
            window.makeKeyAndVisible()
            textView.layoutIfNeeded()
        }

        var codeBackgroundFill: UIColor? {
            guard let shape = textView.layer.sublayers?.compactMap({ $0 as? CAShapeLayer }).first,
                  let fill = shape.fillColor else { return nil }
            return UIColor(cgColor: fill)
        }

        /// 描かれた色。
        ///
        /// 透明な背景にひとつだけ描くので、残った画素は装飾（または本文）そのもの。
        ///
        /// 返すのは色だけで、被覆率は返さない。装飾の既定色は `Color.secondary.opacity(0.4)`
        /// のように半透明で、しかも罫線は 1pt の毛のような線なので、画素の一部だけ塗られる行が
        /// できる。合成済みの値をそのまま見ると、同じ色でも被覆率の違いで別の値になり、
        /// 「色が変わった」ことにしてしまう（実測: 罫線が固まったままの版で
        /// light rgba(6,6,7,0.10) / dark rgba(7,7,8,0.12) と出た。6/0.10 も 7/0.12 も
        /// 同じ色で、違うのは被覆率だけ）。
        ///
        /// 合成済みの画素は 色 × アルファ なので、両方をアルファで重みづけて足し、
        /// アルファの総和で割ると色そのものが戻る。閾値も丸めも要らない。
        var inkColor: Ink? {
            let scale: CGFloat = 2
            let width = Int(textView.bounds.width * scale)
            let height = Int(textView.bounds.height * scale)
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
            context.scaleBy(x: scale, y: scale)

            // レイヤーツリーを描かせる。ここで trait を自分で積んだりはしない。
            // UIKit がビューの trait を積んでフラグメントの draw(at:in:) まで降りる、
            // その経路そのものを見たいので、外から current を差し込むと確かめたい
            // ことが確かめられなくなる。
            textView.layer.render(in: context)

            var sum = [0, 0, 0]
            var alphaSum = 0
            for index in stride(from: 0, to: pixels.count, by: 4) {
                let alpha = Int(pixels[index + 3])
                guard alpha > 0 else { continue }
                for channel in 0..<3 { sum[channel] += Int(pixels[index + channel]) }
                alphaSum += alpha
            }
            // 何も描かれていないのか、薄いものが描かれたのかを取り違えないだけの量。
            guard alphaSum > 255 * 50 else { return nil }
            return Ink(
                red: min(255, sum[0] * 255 / alphaSum),
                green: min(255, sum[1] * 255 / alphaSum),
                blue: min(255, sum[2] * 255 / alphaSum)
            )
        }
    }
}
#endif
