import SwiftUI
import MarkdownAttributedKit

// MARK: - MathRenderer Protocol

/// A type that renders the math in Markdown content.
///
/// The core module ships ``PlainMathRenderer``, which shows LaTeX source without typesetting it.
/// For real typesetting, add the `SwiftMarkdownViewLaTeX` module and inject `LaTeXMathRenderer`:
///
/// ```swift
/// MarkdownView(source)
///     .markdownMathRenderer(LaTeXMathRenderer())
/// ```
///
/// The design follows ``SyntaxHighlighter``: the core stays free of dependencies and the
/// implementation arrives through the environment.
///
/// The same implementation also draws TextKit attachments, which is how display math becomes an
/// image, so this protocol inherits `MarkdownAttachmentRendering`. The two used to be unrelated
/// protocols joined by a runtime `as?`, and **a custom renderer that did not conform to both was
/// silently ignored, leaving math on screen as `$latex$`**. With inheritance, a missing conformance
/// is a compile error instead.
///
/// A renderer that does not typeset can return `nil` from
/// `renderedImage(for:theme:)`, as ``PlainMathRenderer`` does, and
/// the content falls back to readable text.
public protocol MathRenderer: MarkdownAttachmentRendering, Sendable {

    /// Renders one formula as a text segment.
    ///
    /// The result is concatenated with the surrounding paragraph, which is why it must be a `Text`
    /// (an image can join in through `Text(Image)` interpolation with a baseline offset).
    ///
    /// - Parameters:
    ///   - latex: The LaTeX source, without delimiters.
    ///   - fontSize: The point size of the surrounding text, or `nil` to use the renderer's own
    ///     default.
    ///   - textColor: The color of the surrounding text.
    @MainActor func inlineMath(_ latex: String, fontSize: CGFloat?, textColor: Color) -> Text
}

// MARK: - PlainMathRenderer

/// The default math renderer, which shows LaTeX source rather than typesetting it.
///
/// Formulas appear as monospaced `$...$` text. It degrades gracefully while keeping the core
/// module free of dependencies.
public struct PlainMathRenderer: MathRenderer {

    public init() {}

    @MainActor
    public func inlineMath(_ latex: String, fontSize: CGFloat?, textColor: Color) -> Text {
        Text("$\(latex)$")
            .font(.system(size: fontSize ?? 17, design: .monospaced))
            .foregroundStyle(textColor)
    }

    /// Always returns `nil`, since nothing is typeset, so the caller falls back to `$latex$` text.
    public func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage? {
        nil
    }
}

// MARK: - Environment Key

private struct MathRendererKey: EnvironmentKey {
    static let defaultValue: any MathRenderer = PlainMathRenderer()
}

extension EnvironmentValues {

    /// The renderer used for math.
    ///
    /// Set it with the ``SwiftUICore/View/markdownMathRenderer(_:)`` modifier.
    public var mathRenderer: any MathRenderer {
        get { self[MathRendererKey.self] }
        set { self[MathRendererKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets the math renderer for this view hierarchy.
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("The identity $e^{i\\pi} + 1 = 0$ holds.")
    ///     .markdownMathRenderer(LaTeXMathRenderer())
    /// ```
    ///
    /// - Parameter renderer: The math renderer to use.
    public func markdownMathRenderer(_ renderer: some MathRenderer) -> some View {
        environment(\.mathRenderer, renderer)
    }
}
