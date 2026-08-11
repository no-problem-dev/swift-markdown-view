#if os(iOS) || os(macOS)
import Testing
import MarkdownModel
import MarkdownAttributedKit
@testable import SwiftMarkdownView

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 再適用するかどうかの判定。
///
/// `updateUIView` / `updateNSView` は「前回と同じなら何もしない」で始まる。選択範囲を捨てない
/// ための最適化だが、判定に使う鍵が描画結果を決める入力より狭いと、変えたはずのものが黙って
/// 無視される。テーマを差し替えても本文の色も背景も罫線も変わらない、という形で出る。
///
/// 鍵は「描画結果が依存するもの全部」でなければならない。
@Suite("再適用の判定は描画結果が依存するものを全部見る")
struct MarkdownSelectableTextStalenessTests {

    private let content = MarkdownContent(parsing: """
    # 見出し

    本文と `コード` と

    ```swift
    let x = 1
    ```

    > 引用

    ---
    """)

    private func theme(text: PlatformColor) -> MarkdownTextTheme {
        var theme = MarkdownTextTheme.default
        theme.textColor = text
        return theme
    }

    @Test("同じ入力なら再適用しない（選択が消えない）")
    func unchangedInputSkipsRestyle() {
        let coordinator = MarkdownSelectableText.Coordinator()
        let inputs = MarkdownSelectableText.AppliedInputs(content: content, theme: .default, mermaidIsDark: nil)
        coordinator.markApplied(inputs)

        #expect(coordinator.isUnchanged(inputs))
    }

    @Test("本文が変われば再適用する")
    func changedContentTriggersRestyle() {
        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(.init(content: content, theme: .default, mermaidIsDark: nil))

        let other = MarkdownContent(parsing: "まったく別の本文")
        #expect(!coordinator.isUnchanged(.init(content: other, theme: .default, mermaidIsDark: nil)))
    }

    @Test("文字色だけ変えても再適用する")
    func changedTextColorTriggersRestyle() {
        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(.init(content: content, theme: theme(text: .systemRed), mermaidIsDark: nil))

        #expect(!coordinator.isUnchanged(.init(content: content, theme: theme(text: .systemBlue), mermaidIsDark: nil)))
    }

    /// 色は `MarkdownDecorationPalette` に載って罫線・引用バー・コード背景を描く。
    /// ここが再適用されないと、テーマを差し替えたのに前のパレットで描き続ける。
    @Test("描画パレットに載る色を変えても再適用する", arguments: [
        "codeBlockBackground", "quoteBarColor", "ruleColor",
        "linkColor", "headingColor", "secondaryColor", "inlineCodeBackground", "inlineCodeForeground"
    ])
    func changedPaletteColorTriggersRestyle(slot: String) {
        var changed = MarkdownTextTheme.default
        switch slot {
        case "codeBlockBackground": changed.codeBlockBackground = .systemTeal
        case "quoteBarColor": changed.quoteBarColor = .systemTeal
        case "ruleColor": changed.ruleColor = .systemTeal
        case "linkColor": changed.linkColor = .systemTeal
        case "headingColor": changed.headingColor = .systemTeal
        case "secondaryColor": changed.secondaryColor = .systemTeal
        case "inlineCodeBackground": changed.inlineCodeBackground = .systemTeal
        default: changed.inlineCodeForeground = .systemTeal
        }

        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(.init(content: content, theme: .default, mermaidIsDark: nil))

        #expect(!coordinator.isUnchanged(.init(content: content, theme: changed, mermaidIsDark: nil)), "\(slot)")
    }

    /// 行間や字下げは属性文字列の段落スタイルに入る。作り直さないかぎり反映されない。
    @Test("寸法だけ変えても再適用する", arguments: [
        "paragraphSpacing", "lineHeightMultiple", "indentStep", "quoteBarWidth", "codeBlockPadding"
    ])
    func changedMetricTriggersRestyle(slot: String) {
        var changed = MarkdownTextTheme.default
        switch slot {
        case "paragraphSpacing": changed.paragraphSpacing += 7
        case "lineHeightMultiple": changed.lineHeightMultiple += 0.5
        case "indentStep": changed.indentStep += 9
        case "quoteBarWidth": changed.quoteBarWidth += 4
        default: changed.codeBlockPadding += 6
        }

        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(.init(content: content, theme: .default, mermaidIsDark: nil))

        #expect(!coordinator.isUnchanged(.init(content: content, theme: changed, mermaidIsDark: nil)), "\(slot)")
    }

    @Test("見出しの大きさ・太さを変えても再適用する")
    func changedHeadingStyleTriggersRestyle() {
        var changed = MarkdownTextTheme.default
        changed.headingWeight = .black
        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(.init(content: content, theme: .default, mermaidIsDark: nil))

        #expect(!coordinator.isUnchanged(.init(content: content, theme: changed, mermaidIsDark: nil)))

        var resized = MarkdownTextTheme.default
        resized.headingSizes = resized.headingSizes.map { $0 + 3 }
        #expect(!coordinator.isUnchanged(.init(content: content, theme: resized, mermaidIsDark: nil)))
    }

    /// Mermaid の図は明暗で背景色が変わる。図はレンダリング時に一度だけ差し込まれるので、
    /// 作り直さないかぎり明るいまま暗い画面に残る。
    @Test("Mermaid の明暗が変われば再適用する")
    func changedMermaidAppearanceTriggersRestyle() {
        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(.init(content: content, theme: .default, mermaidIsDark: false))

        #expect(!coordinator.isUnchanged(.init(content: content, theme: .default, mermaidIsDark: true)))
    }

    @Test("基準サイズが変われば従来どおり再適用する")
    func changedBaseFontSizeTriggersRestyle() {
        var changed = MarkdownTextTheme.default
        changed.baseFont = .systemFont(ofSize: MarkdownTextTheme.default.baseFontSize + 4)

        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(.init(content: content, theme: .default, mermaidIsDark: nil))

        #expect(!coordinator.isUnchanged(.init(content: content, theme: changed, mermaidIsDark: nil)))
    }

    // MARK: ラスタライズ済みの数式と明暗

    /// 数式はビットマップに焼かれる。テーマが渡す文字色は動的でも、ビットマップを描いた
    /// 瞬間に解決され、以後どんな明暗の変化もその中には届かない。明暗が鍵に入っていないと、
    /// 暗くしたのに数式だけ黒いまま暗い地に残る — 同じ行の他の文字は白くなっているのに。
    @MainActor
    @Test("数式のある文書は明暗が変われば再適用する")
    func appearanceChangeRestylesDocumentWithMath() {
        let withMath = MarkdownContent(parsing: "本文 $x^2$ と\n\n$$E = mc^2$$")
        let view = MarkdownSelectableText(withMath).attachmentRenderer(PlainMathRenderer())

        let light = view.appearance(isDark: false).appliedInputs()
        let dark = view.appearance(isDark: true).appliedInputs()

        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(light)
        #expect(!coordinator.isUnchanged(dark))
    }

    /// 逆側。数式が無い文書まで明暗で作り直すと、明暗を切り替えるたびに選択が消える。
    /// 動的な色は描画時に解決されるので、作り直す必要がそもそも無い。
    @MainActor
    @Test("数式の無い文書は明暗が変わっても再適用しない（選択が残る）")
    func appearanceChangeKeepsDocumentWithoutMath() {
        let view = MarkdownSelectableText(content).attachmentRenderer(PlainMathRenderer())

        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(view.appearance(isDark: false).appliedInputs())

        #expect(coordinator.isUnchanged(view.appearance(isDark: true).appliedInputs()))
    }

    /// レンダラーが無ければ数式はビットマップにならず、素のテキストとして落ちる。
    /// 焼かれたものが無いのだから明暗で作り直す理由も無い。
    @MainActor
    @Test("レンダラーが無ければ数式があっても明暗で再適用しない")
    func appearanceChangeKeepsDocumentWithoutRenderer() {
        let withMath = MarkdownContent(parsing: "本文 $x^2$ と\n\n$$E = mc^2$$")
        let view = MarkdownSelectableText(withMath)

        let coordinator = MarkdownSelectableText.Coordinator()
        coordinator.markApplied(view.appearance(isDark: false).appliedInputs())

        #expect(coordinator.isUnchanged(view.appearance(isDark: true).appliedInputs()))
    }

    /// 上の3つは `containsMath` の判定に乗っている。入れ子の中の数式を見落とすと
    /// 「数式があるのに再適用しない」に静かに戻る。
    @Test("数式の検出は入れ子の中まで届く", arguments: [
        "$x^2$",
        "$$E = mc^2$$",
        "```math\nE = mc^2\n```",
        "- 箇条書きの中の $x^2$",
        "> 引用の中の $x^2$",
        "**強調の中の $x^2$**",
        "[リンクの中の $x^2$](https://example.com)",
        "| 見出し |\n|---|\n| 表の中の $x^2$ |"
    ])
    func mathIsFoundAtAnyDepth(source: String) {
        #expect(MarkdownContent(parsing: source).containsMath, "\(source)")
    }

    @Test("数式の無い文書を数式ありと誤判定しない", arguments: [
        "ただの本文",
        "`$x^2$` はコードなので数式ではない",
        "```swift\nlet cost = 5\n```",
        "値段は $5 と $10 です"
    ])
    func mathIsNotInventedWhereThereIsNone(source: String) {
        #expect(!MarkdownContent(parsing: source).containsMath, "\(source)")
    }
}
#endif
