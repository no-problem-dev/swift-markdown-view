import SwiftUI
import DesignSystem
import SwiftMarkdownView
import SwiftLaTeXView

/// A math renderer that typesets formulas with SwiftLaTeXView.
///
/// Inject it into the view hierarchy to upgrade Markdown math from bare source to real
/// typesetting:
///
/// ```swift
/// MarkdownView("""
/// For $ax^2 + bx + c = 0$:
///
/// $$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$
/// """)
/// .markdownMathRenderer(LaTeXMathRenderer())
/// ```
public struct LaTeXMathRenderer: MathRenderer {

    /// The style used when typesetting math inline with the surrounding paragraph.
    ///
    /// It is fixed when the renderer is created: renderer methods run outside the view hierarchy,
    /// so the `mathStyle` environment value never reaches them. The TextKit attachment path
    /// ignores this value and derives its own style from the text theme, so that rasterized math
    /// matches the text around it.
    public let style: any MathStyle

    public init(style: any MathStyle = DefaultMathStyle()) {
        self.style = style
    }

    @MainActor
    public func inlineMath(_ latex: String, fontSize: CGFloat?, textColor: Color) -> Text {
        let size = fontSize ?? style.inlineFontSize
        do {
            return try LaTeXView.inlineText(
                latex,
                fontFamily: style.fontFamily,
                fontSize: size,
                color: textColor
            )
        } catch {
            // swift-latex-view 0.4.0 replaced a bare `nil` with a reason and the string the
            // engine was actually handed. Inline math sits inside a paragraph, so there is
            // nowhere to surface that reason — the fallback stays the source text. But it is
            // now `failure.source`, the normalized string that was rejected, rather than the
            // caller's original: for double-escaped model output those differ, and showing the
            // original meant showing text the engine never saw.
            return Text(error.source)
                .font(.system(size: size, design: .monospaced))
                .foregroundStyle(textColor)
        }
    }
}

// MARK: - TextKit attachment rendering

/// A style with a fixed color, so the rasterized image matches the Markdown text around it.
///
/// Attachments render outside the view hierarchy, where palette-based color resolution does not
/// apply.
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

    /// Rasterizes a formula at device resolution and embeds it as a TextKit attachment.
    ///
    /// SwiftMath typesets vector glyphs, so the high-DPI raster stays crisp at ordinary sizes.
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
            // Inline math sits on the text baseline. Nudge it down so the typeset descenders
            // line up with the surrounding text.
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
