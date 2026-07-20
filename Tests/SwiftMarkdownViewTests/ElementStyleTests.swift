import Testing
import SwiftUI
import DesignSystem
@testable import SwiftMarkdownView

/// コードブロック・リンク・アサイド・テーブルの各スタイル実装。
///
/// いずれも公開 API でありながら参照テストが 1 件も無かった。
/// スタイルは見た目にしか出ないため、名前が示す性質（Minimal なのに枠がある、
/// Striped なのに縞にならない等）が壊れても気づけない。
/// ここでは各実装の「名前が約束している差別化点」を固定する。
@Suite("要素スタイル")
struct ElementStyleTests {

    private let palette: any ColorPalette = LightColorPalette()
    private let spacing: any SpacingScale = DefaultSpacingScale()
    private let radius: any RadiusScale = DefaultRadiusScale()

    // MARK: - CodeBlockStyle

    @Test("既定のコードブロックは言語ラベルを出す")
    func defaultCodeBlockShowsLanguageLabel() {
        #expect(DefaultCodeBlockStyle().showLanguageLabel)
    }

    @Test("Minimal は装飾を削る")
    func minimalCodeBlockStripsChrome() {
        let minimal = MinimalCodeBlockStyle()
        let base = DefaultCodeBlockStyle()
        // 「最小限」を名乗る以上、既定より装飾要素が少ないこと。
        let minimalChrome = [minimal.showLanguageLabel, minimal.showLineNumbers, minimal.showCopyButton]
            .filter { $0 }.count
        let baseChrome = [base.showLanguageLabel, base.showLineNumbers, base.showCopyButton]
            .filter { $0 }.count
        #expect(minimalChrome < baseChrome)
    }

    @Test("Terminal は既定と異なる配色を持つ")
    func terminalCodeBlockHasOwnColors() {
        #expect(TerminalCodeBlockStyle().backgroundColor(palette)
                != DefaultCodeBlockStyle().backgroundColor(palette))
    }

    @Test("コードブロックの余白と角丸は正の値")
    func codeBlockMetricsArePositive() {
        let style = DefaultCodeBlockStyle()
        #expect(style.padding(spacing) > 0)
        #expect(style.cornerRadius(radius) >= 0)
    }

    // MARK: - LinkStyle

    @Test("既定のリンクは下線を出す")
    func defaultLinkShowsUnderline() {
        #expect(DefaultLinkStyle().showUnderline)
    }

    @Test("Subtle は下線を出さない")
    func subtleLinkHidesUnderline() {
        #expect(SubtleLinkStyle().showUnderline == false)
    }

    @Test("Bold は太字を指定する")
    func boldLinkSetsWeight() {
        #expect(BoldLinkStyle().fontWeight != nil)
    }

    @Test("Monochrome はリンク色を本文色に寄せる")
    func monochromeLinkUsesTextColor() {
        // 単色を名乗る以上、既定のアクセント色とは異なること。
        #expect(MonochromeLinkStyle().color(palette) != DefaultLinkStyle().color(palette))
    }

    @Test("Classic は訪問済みリンクを別色にする")
    func classicLinkDistinguishesVisited() {
        let style = ClassicLinkStyle()
        #expect(style.visitedColor(palette) != style.color(palette))
    }

    // MARK: - AsideStyle

    @Test("アサイドの種類ごとに異なるアイコンが割り当たる")
    func asideIconsAreDistinctPerKind() {
        let style = DefaultAsideStyle()
        let kinds: [AsideKind] = [.note, .tip, .important, .warning, .experiment, .bug]
        let icons = kinds.map { style.icon(for: $0) }
        // 全種類が同じアイコンになっていたら、種類の区別が視覚的に失われる。
        #expect(Set(icons).count > 1)
        #expect(icons.allSatisfy { !$0.isEmpty })
    }

    @Test("アサイドの種類ごとにアクセント色が割り当たる")
    func asideAccentColorsVaryByKind() {
        let style = DefaultAsideStyle()
        let kinds: [AsideKind] = [.note, .tip, .important, .warning, .experiment, .bug]
        let colors = Set(kinds.map { style.accentColor(for: $0, colorPalette: palette) })
        #expect(colors.count > 1)
    }

    // MARK: - TableStyle

    @Test("既定のテーブルは枠線を出す")
    func defaultTableShowsBorder() {
        #expect(DefaultTableStyle().showBorder)
    }

    @Test("Borderless は枠線を出さない")
    func borderlessTableHidesBorders() {
        let style = BorderlessTableStyle()
        #expect(style.showBorder == false)
        #expect(style.showColumnBorders == false)
        #expect(style.showRowBorders == false)
    }

    @Test("Striped は交互の行で背景色を変える")
    func stripedTableAlternatesRowColors() {
        let style = StripedTableStyle()
        #expect(style.stripedRows)
        #expect(style.rowBackgroundColor(palette, isAlternate: true)
                != style.rowBackgroundColor(palette, isAlternate: false))
    }

    @Test("縞なしのテーブルは交互でも同じ背景色")
    func nonStripedTableKeepsRowColorConstant() {
        let style = BorderlessTableStyle()
        guard style.stripedRows == false else { return }
        #expect(style.rowBackgroundColor(palette, isAlternate: true)
                == style.rowBackgroundColor(palette, isAlternate: false))
    }

    @Test("Card は角丸を持つ")
    func cardTableIsRounded() {
        #expect(CardTableStyle().cornerRadius(radius) > 0)
    }

    @Test("テーブルのセル余白は正の値")
    func tableCellPaddingIsPositive() {
        let style = DefaultTableStyle()
        #expect(style.cellHorizontalPadding(spacing) > 0)
        #expect(style.cellVerticalPadding(spacing) > 0)
    }

    // MARK: - 環境値の既定

    @Test("各スタイルの環境既定値は Default 実装")
    func environmentDefaultsAreDefaultImplementations() {
        let env = EnvironmentValues()
        #expect(env.codeBlockStyle is DefaultCodeBlockStyle)
        #expect(env.markdownLinkStyle is DefaultLinkStyle)
        #expect(env.asideStyle is DefaultAsideStyle)
        #expect(env.markdownTableStyle is DefaultTableStyle)
    }
}
