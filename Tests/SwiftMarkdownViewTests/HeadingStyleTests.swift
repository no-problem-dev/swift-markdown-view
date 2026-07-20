import Testing
import SwiftUI
import DesignSystem
@testable import SwiftMarkdownView

/// 見出しスタイルの各実装。
///
/// 公開 API でありながら参照テストが 1 件も無かった。スタイルは見た目にしか出ないため、
/// レベルとトークンの対応がずれても壊れたことに気づけない。
/// ここでは「どのレベルが何にマップされるか」と「各スタイルの差別化点」を固定する。
@Suite("HeadingStyle")
struct HeadingStyleTests {

    private let palette: any ColorPalette = LightColorPalette()
    private let spacing: any SpacingScale = DefaultSpacingScale()

    // MARK: DefaultHeadingStyle

    @Test("見出しレベルがタイポグラフィに順序どおり対応する")
    func defaultTypographyMapsByLevel() {
        let style = DefaultHeadingStyle()
        #expect(style.typography(for: 1) == .displayMedium)
        #expect(style.typography(for: 2) == .headlineLarge)
        #expect(style.typography(for: 3) == .headlineMedium)
        #expect(style.typography(for: 4) == .titleLarge)
        #expect(style.typography(for: 5) == .titleMedium)
        #expect(style.typography(for: 6) == .titleSmall)
    }

    @Test("範囲外のレベルは本文相当にフォールバックする")
    func defaultTypographyFallsBackOutOfRange() {
        let style = DefaultHeadingStyle()
        #expect(style.typography(for: 0) == .bodyLarge)
        #expect(style.typography(for: 7) == .bodyLarge)
        #expect(style.typography(for: -1) == .bodyLarge)
    }

    @Test("上位見出しほど上の余白が大きい")
    func defaultTopPaddingDecreasesWithLevel() {
        let style = DefaultHeadingStyle()
        let h1 = style.topPadding(for: 1, spacing: spacing)
        let h2 = style.topPadding(for: 2, spacing: spacing)
        let h3 = style.topPadding(for: 3, spacing: spacing)
        #expect(h1 > h2)
        #expect(h2 > h3)
    }

    @Test("既定では全レベルが本文色")
    func defaultColorIsUniform() {
        let style = DefaultHeadingStyle()
        for level in 1...6 {
            #expect(style.color(for: level, palette: palette) == palette.onSurface)
        }
    }

    @Test("既定ではディバイダーを出さない")
    func defaultShowsNoDivider() {
        let style = DefaultHeadingStyle()
        for level in 1...6 {
            #expect(style.showDivider(for: level) == false)
        }
    }

    // MARK: CompactHeadingStyle

    @Test("コンパクトは既定より小さいタイポグラフィを使う")
    func compactUsesSmallerTypography() {
        // 同じレベルで既定と異なること（＝コンパクト化が効いていること）。
        #expect(CompactHeadingStyle().typography(for: 1) != DefaultHeadingStyle().typography(for: 1))
    }

    // MARK: ColoredHeadingStyle

    @Test("彩色スタイルは H1・H2 だけ色を変える")
    func coloredStyleTintsTopLevels() {
        let style = ColoredHeadingStyle()
        #expect(style.color(for: 1, palette: palette) == palette.primary)
        #expect(style.color(for: 2, palette: palette) == palette.secondary)
        for level in 3...6 {
            #expect(style.color(for: level, palette: palette) == palette.onSurface)
        }
    }

    @Test("彩色スタイルはタイポグラフィと余白を既定から変えない")
    func coloredStyleKeepsDefaultMetrics() {
        let colored = ColoredHeadingStyle()
        let base = DefaultHeadingStyle()
        for level in 1...6 {
            #expect(colored.typography(for: level) == base.typography(for: level))
            #expect(colored.topPadding(for: level, spacing: spacing)
                    == base.topPadding(for: level, spacing: spacing))
        }
    }

    // MARK: DividedHeadingStyle

    @Test("区切り線スタイルは H1・H2 にだけ線を引く")
    func dividedStyleShowsDividerOnTopLevels() {
        let style = DividedHeadingStyle()
        #expect(style.showDivider(for: 1))
        #expect(style.showDivider(for: 2))
        for level in 3...6 {
            #expect(style.showDivider(for: level) == false)
        }
    }

    @Test("区切り線がある見出しは下の余白が広い")
    func dividedStyleGivesMoreRoomUnderDividers() {
        let style = DividedHeadingStyle()
        let withDivider = style.bottomPadding(for: 1, spacing: spacing)
        let withoutDivider = style.bottomPadding(for: 3, spacing: spacing)
        #expect(withDivider > withoutDivider)
    }

    // MARK: 環境値

    @Test("環境の既定値は DefaultHeadingStyle")
    func environmentDefaultsToDefaultStyle() {
        let style = EnvironmentValues().headingStyle
        #expect(style is DefaultHeadingStyle)
    }
}
