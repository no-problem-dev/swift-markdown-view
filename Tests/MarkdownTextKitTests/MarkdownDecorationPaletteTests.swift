import Testing
import CoreGraphics
@testable import MarkdownTextKit
@testable import MarkdownAttributedKit

/// テーマ → 描画パレットの変換。
///
/// レイアウトフラグメントは `CGColor` とメトリクスだけを見て描画するため、
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

        #expect(palette.codeBackground == theme.codeBlockBackground.cgColor)
        #expect(palette.rule == theme.ruleColor.cgColor)
        #expect(palette.quoteBar == theme.quoteBarColor.cgColor)
    }

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
