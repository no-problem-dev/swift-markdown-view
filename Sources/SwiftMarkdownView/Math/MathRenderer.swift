import SwiftUI
import DesignSystem

// MARK: - MathRenderer Protocol

/// A renderer for math expressions found in Markdown content.
///
/// The core module ships ``PlainMathRenderer``, which shows LaTeX source
/// without typesetting. Add the `SwiftMarkdownViewLaTeX` module and inject
/// its `LaTeXMathRenderer` for real typesetting:
///
/// ```swift
/// MarkdownView(source)
///     .mathRenderer(LaTeXMathRenderer())
/// ```
///
/// This mirrors the ``SyntaxHighlighter`` pattern: the core stays
/// dependency-free and the implementation is injected via the environment.
public protocol MathRenderer: Sendable {

    /// Renders inline math as a `Text` segment.
    ///
    /// The result is concatenated with the surrounding paragraph text, so
    /// it must be a `Text` (images can participate via `Text(Image)`
    /// interpolation with a baseline offset).
    ///
    /// - Parameters:
    ///   - latex: The LaTeX source without delimiters.
    ///   - palette: The current color palette from the environment.
    @MainActor func inlineMath(_ latex: String, palette: any ColorPalette) -> Text

    /// Renders inline math at a specific font size.
    ///
    /// Used where math is embedded in non-body text (headings, labels —
    /// see ``MathText``) and must match the surrounding font. The default
    /// implementation ignores the size and falls back to
    /// ``inlineMath(_:palette:)``.
    @MainActor func inlineMath(_ latex: String, fontSize: CGFloat, palette: any ColorPalette) -> Text

    /// Renders display math as a block view.
    ///
    /// - Parameter latex: The LaTeX source without delimiters.
    @MainActor func displayMath(_ latex: String) -> AnyView
}

extension MathRenderer {

    @MainActor
    public func inlineMath(_ latex: String, fontSize: CGFloat, palette: any ColorPalette) -> Text {
        inlineMath(latex, palette: palette)
    }
}

// MARK: - PlainMathRenderer

/// The default math renderer: shows LaTeX source without typesetting.
///
/// Inline math appears as monospaced `$...$` text; display math appears
/// as a `math` code block. This keeps the core module dependency-free
/// while degrading gracefully.
public struct PlainMathRenderer: MathRenderer {

    public init() {}

    @MainActor
    public func inlineMath(_ latex: String, palette: any ColorPalette) -> Text {
        Text("$\(latex)$")
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(MarkdownColors.inlineCodeText(palette))
    }

    @MainActor
    public func displayMath(_ latex: String) -> AnyView {
        AnyView(CodeBlockView(language: "math", code: latex))
    }
}

// MARK: - Environment Key

private struct MathRendererKey: EnvironmentKey {
    static let defaultValue: any MathRenderer = PlainMathRenderer()
}

extension EnvironmentValues {

    /// The renderer used for math expressions.
    ///
    /// Use the ``SwiftUICore/View/mathRenderer(_:)`` modifier to set this value.
    public var mathRenderer: any MathRenderer {
        get { self[MathRendererKey.self] }
        set { self[MathRendererKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets a custom math renderer for this view hierarchy.
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("The identity $e^{i\\pi} + 1 = 0$ holds.")
    ///     .mathRenderer(LaTeXMathRenderer())
    /// ```
    ///
    /// - Parameter renderer: The math renderer to use.
    /// - Returns: A view with the math renderer applied.
    public func mathRenderer(_ renderer: some MathRenderer) -> some View {
        environment(\.mathRenderer, renderer)
    }
}

// MARK: - MathBlockView

/// Renders a display math block via the environment's math renderer.
struct MathBlockView: View {
    let latex: String

    @Environment(\.mathRenderer) private var renderer
    @Environment(\.markdownRenderingOptions) private var options

    var body: some View {
        if options.renderMath {
            renderer.displayMath(latex)
        } else {
            CodeBlockView(language: "math", code: latex)
        }
    }
}
