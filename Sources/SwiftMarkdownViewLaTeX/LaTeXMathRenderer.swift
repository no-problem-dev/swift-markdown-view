import SwiftUI
import DesignSystem
import SwiftMarkdownView
import SwiftLaTeXView

/// A ``MathRenderer`` that typesets math via SwiftLaTeXView.
///
/// Inject into the view hierarchy to upgrade Markdown math from plain
/// source display to real typesetting:
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

    /// The math style used for typesetting.
    ///
    /// The style is fixed at renderer construction (renderer methods run
    /// outside the view hierarchy, so the `mathStyle` environment value
    /// does not propagate here).
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
