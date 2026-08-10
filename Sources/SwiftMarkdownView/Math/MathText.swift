import SwiftUI

/// A single-line text view that typesets embedded math inline.
///
/// Unlike ``MarkdownView``, it does not parse block structure. The source is split into text and
/// math segments only, so what comes back is a `Text` composition that inherits the caller's font.
/// Use it for headings, labels, and anywhere else that needs no Markdown body layout but where the
/// text may still contain `$...$` or `$$...$$` delimiters:
///
/// ```swift
/// MathText("The answer: $$-6$$", mathFontSize: 22)
///     .font(.title2)
/// ```
///
/// Display math (`$$...$$` and `\[...\]`) is typeset in inline mode, because a single line has no
/// block layout to give it. Math goes through the ``MathRenderer`` in the environment; with no
/// renderer injected, the LaTeX source shows as monospaced text.
public struct MathText: View {

    private let source: String
    private let mathFontSize: CGFloat?

    @Environment(\.mathRenderer) private var renderer
    @Environment(\.markdownPalette) private var palette
    @Environment(\.markdownRenderingOptions) private var options

    /// Creates a text view that typesets the math delimiters found in the source.
    ///
    /// - Parameters:
    ///   - source: Text that may contain math delimiters.
    ///   - mathFontSize: The point size for math segments, usually the size of the surrounding
    ///     font. Pass `nil` to use the renderer's default.
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
            case .math(let latex, _, _):
                output = output + renderer.inlineMath(latex, fontSize: mathFontSize, textColor: palette.text)
            }
        }
        return output
    }
}
