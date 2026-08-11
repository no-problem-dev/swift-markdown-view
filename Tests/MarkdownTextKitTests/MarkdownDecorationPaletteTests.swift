import Testing
import CoreGraphics
@testable import MarkdownTextKit
@testable import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// テーマ → 描画パレットの変換。
///
/// レイアウトフラグメントは色とメトリクスだけを見て描画するため、
/// ここの取り違え（引用バーの色に罫線の色を入れる等）は表示に直結するが
/// クラッシュもコンパイルエラーも起こさない。
@Suite("MarkdownDecorationPalette")
struct MarkdownDecorationPaletteTests {

    @Test("テーマのメトリクスがそのまま渡る")
    func metricsAreCarriedOver() {
        var theme = MarkdownTextTheme.default
        theme.indentStep = 21
        theme.quoteBarWidth = 7
        theme.codeBlockCornerRadius = 13
        theme.codeBlockVerticalPadding = 5

        let palette = MarkdownDecorationPalette(theme: theme)

        #expect(palette.indentStep == 21)
        #expect(palette.quoteBarWidth == 7)
        #expect(palette.codeCornerRadius == 13)
        #expect(palette.codeVerticalPadding == 5)
    }

    @Test("色が取り違えられていない")
    func colorsMapToTheirOwnSlots() {
        let theme = MarkdownTextTheme.default
        let palette = MarkdownDecorationPalette(theme: theme)

        #expect(palette.codeBackground == theme.codeBlockBackground)
        #expect(palette.rule == theme.ruleColor)
        #expect(palette.quoteBar == theme.quoteBarColor)
    }

    #if canImport(UIKit)
    /// パレットは「作った時の見た目」を焼き込んではいけない。
    ///
    /// `CGColor` は具体的な色なので、動的な `UIColor` から取り出した瞬間に
    /// そのときの `UITraitCollection.current` で解決されて固まる。パレットを作るのは
    /// `makeUIView` / `updateUIView` で、そこの current はテキストビューのものではない。
    /// 焼き込むと、本文だけがダークに追従して罫線・引用バー・コード背景がライトのまま残る
    /// （実測: `regularBlockquoteAsNote` の引用バーが light/dark とも rgb(208,208,210)）。
    @Test("パレットは作った時の見た目に依存しない")
    func paletteDoesNotBakeTheAmbientAppearance() {
        var light: MarkdownDecorationPalette?
        var dark: MarkdownDecorationPalette?
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            light = MarkdownDecorationPalette(theme: .default)
        }
        UITraitCollection(userInterfaceStyle: .dark).performAsCurrent {
            dark = MarkdownDecorationPalette(theme: .default)
        }

        #expect(light?.rule == dark?.rule)
        #expect(light?.quoteBar == dark?.quoteBar)
        #expect(light?.codeBackground == dark?.codeBackground)
    }

    /// 焼き込んでいないことの裏返し: 明暗を指定して解決すれば別の色になる。
    /// 両方が同じ色になるようなテーマを既定にしてしまうと、上のテストは通るのに
    /// 「追従している」ことを何も確かめていない状態になる。
    @Test("パレットの色は明暗で解決し分けられる")
    func paletteColorsStillResolvePerAppearance() {
        let palette = MarkdownDecorationPalette(theme: .default)
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)

        #expect(palette.rule.resolvedColor(with: light) != palette.rule.resolvedColor(with: dark))
        #expect(palette.quoteBar.resolvedColor(with: light) != palette.quoteBar.resolvedColor(with: dark))
        #expect(palette.codeBackground.resolvedColor(with: light) != palette.codeBackground.resolvedColor(with: dark))
    }
    #endif

    @Test("異なるテーマは異なるパレットになる")
    func distinctThemesProduceDistinctPalettes() {
        var dense = MarkdownTextTheme.default
        dense.indentStep = 4
        var loose = MarkdownTextTheme.default
        loose.indentStep = 40

        #expect(MarkdownDecorationPalette(theme: dense).indentStep
                != MarkdownDecorationPalette(theme: loose).indentStep)
    }
}
