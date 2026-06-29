import SwiftUI
import DesignSystem
import SwiftMarkdownView
import SwiftLaTeXView

/// SwiftLaTeXView で数式を組版する ``MathRenderer`` 実装。
///
/// ビュー階層に注入することで、Markdown の数式をプレーンなソース表示から
/// 本格的な組版にアップグレードする:
///
/// ```swift
/// MarkdownView("""
/// For $ax^2 + bx + c = 0$:
///
/// $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$
/// """)
/// .mathRenderer(LaTeXMathRenderer())
/// ```
public struct LaTeXMathRenderer: MathRenderer {

    /// 組版に使用する数式スタイル。
    ///
    /// スタイルはレンダラー生成時に固定される（レンダラーメソッドはビュー階層外で実行されるため、
    /// `mathStyle` 環境値はここには伝播しない）。
    public let style: any MathStyle

    public init(style: any MathStyle = DefaultMathStyle()) {
        self.style = style
    }

    @MainActor
    public func inlineMath(_ latex: String, palette: any ColorPalette) -> Text {
        inlineMath(latex, fontSize: style.inlineFontSize, palette: palette)
    }

    @MainActor
    public func inlineMath(_ latex: String, fontSize: CGFloat, palette: any ColorPalette) -> Text {
        LaTeXView.inlineText(
            latex,
            fontFamily: style.fontFamily,
            fontSize: fontSize,
            color: style.textColor(palette)
        )
        ?? Text(latex)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(style.errorColor(palette))
    }

    @MainActor
    public func displayMath(_ latex: String) -> AnyView {
        AnyView(
            LaTeXView(latex, mode: .display)
                .mathStyle(style)
        )
    }
}

// MARK: - TextKit attachment rendering

/// ラスタライズ画像が周囲の Markdown テキストカラーと一致するよう固定カラーを使用する数式スタイル。
/// アタッチメントはビュー階層外でレンダリングされるため、パレットベースのカラー解決が適用されない。
private struct FixedColorMathStyle: MathStyle {
    var color: Color
    var inline: CGFloat
    var display: CGFloat
    var displayFontSize: CGFloat { display }
    var inlineFontSize: CGFloat { inline }
    func textColor(_ palette: any ColorPalette) -> Color { color }
    func errorColor(_ palette: any ColorPalette) -> Color { color }
}

extension LaTeXMathRenderer: MarkdownAttachmentRendering {

    /// 数式をデバイス解像度のシャープな画像にラスタライズし、TextKit レンダラーの
    /// `NSTextAttachment` として埋め込む。SwiftMath はベクターグリフを組版するため、
    /// 高 DPI ラスターは通常サイズでも鮮明に表示される。
    public func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage? {
        let latex: String
        let mode: MathMode
        switch kind {
        case .inlineMath(let value): latex = value; mode = .inline
        case .displayMath(let value): latex = value; mode = .display
        case .image, .mermaid: return nil
        }

        return MainActor.assumeIsolated {
            let mathStyle = FixedColorMathStyle(
                color: Color(theme.textColor),
                inline: theme.baseFontSize,
                display: theme.baseFontSize * 1.2
            )
            let renderer = ImageRenderer(
                content: LaTeXView(latex, mode: mode).mathStyle(mathStyle).fixedSize()
            )
            renderer.scale = Self.displayScale
            #if canImport(UIKit)
            guard let image = renderer.uiImage else { return nil }
            #elseif canImport(AppKit)
            guard let image = renderer.nsImage else { return nil }
            #endif
            let size = image.size
            // インライン数式はテキストベースラインに配置する。組版のディセンダーが
            // 周囲テキストと揃うよう、わずかに下に下げる。
            let baselineOffset: CGFloat = mode == .inline ? -(size.height * 0.18) : 0
            return MarkdownRenderedImage(image: image, size: size, baselineOffset: baselineOffset)
        }
    }

    @MainActor
    private static var displayScale: CGFloat {
        #if canImport(UIKit)
        return max(2, UITraitCollection.current.displayScale)
        #elseif canImport(AppKit)
        return NSScreen.main?.backingScaleFactor ?? 2
        #endif
    }
}
