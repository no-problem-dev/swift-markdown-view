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

// MARK: - TextKit attachment rendering

/// A fixed-color math style so the rasterized image matches the surrounding
/// Markdown text color (the attachment renders outside the view hierarchy, so
/// the palette-based color resolution doesn't apply).
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

    /// Rasterizes math to a crisp (device-scale) image for embedding as an
    /// `NSTextAttachment` in the TextKit renderer. SwiftMath typesets vector
    /// glyphs, so a high-DPI raster is sharp at normal sizes.
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
            // Inline math sits on the text baseline; drop it slightly so the
            // typeset descenders align with surrounding text.
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
