import SwiftUI
import DesignSystem

/// A single-line text view that typesets embedded math inline.
///
/// Unlike ``MarkdownView``, no block structure is parsed: the source is
/// split into text and math segments only, so the result stays a
/// `Text` composition that inherits the caller's font. Use for headings,
/// labels, and other places where Markdown body layout is unwanted but
/// LLM output may still contain `$...$` / `$$...$$` delimiters:
///
/// ```swift
/// MathText("答え: $$-6$$", mathFontSize: 22)
///     .font(.title2)
/// ```
///
/// Display math (`$$...$$`, `\[...\]`) is typeset in inline mode, since a
/// single line offers no block layout. Math is rendered through the
/// environment's ``MathRenderer``; without an injected renderer the LaTeX
/// source is shown as monospaced text.
public struct MathText: View {

    private let source: String
    private let mathFontSize: CGFloat?

    @Environment(\.mathRenderer) private var renderer
    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.markdownRenderingOptions) private var options

    /// - Parameters:
    ///   - source: Text that may contain math delimiters.
    ///   - mathFontSize: Point size for math segments, typically the
    ///     surrounding font's size. `nil` uses the renderer's default.
    public init(_ source: String, mathFontSize: CGFloat? = nil) {
        self.source = source
        self.mathFontSize = mathFontSize
    }

    public var body: some View {
        composed
    }

    private var composed: Text {
        guard options.renderMath else { return Text(source) }
        var output = Text(verbatim: "")
        for part in MathScanner.parts(in: source) {
            switch part {
            case .text(let text):
                output = output + Text(text)
            case .math(let latex, _):
                if let mathFontSize {
                    output = output + renderer.inlineMath(latex, fontSize: mathFontSize, palette: colorPalette)
                } else {
                    output = output + renderer.inlineMath(latex, palette: colorPalette)
                }
            }
        }
        return output
    }
}
