import SwiftUI
import MarkdownAttributedKit

// MARK: - MarkdownRenderingOptions

/// Rendering switches that a view reads from the environment.
///
/// Both ``MarkdownView`` and ``MathText`` consult these.
///
/// ## Example
///
/// ```swift
/// MarkdownView("The answer: $$-6$$")
///     .markdownRenderingOptions(MarkdownRenderingOptions(renderMath: false))
/// ```
public struct MarkdownRenderingOptions: Sendable, Equatable {

    /// Whether math is typeset, or left standing as source text.
    ///
    /// When `false`, ``MathText`` shows its source as written, delimiters and all, and a
    /// ``MarkdownView`` leaves every formula as its LaTeX source instead of handing it to the math
    /// renderer. Images and Mermaid diagrams are untouched either way — whether math is typeset is
    /// a separate question from whether the other attachments render.
    public var renderMath: Bool

    /// - Parameter renderMath: Whether to typeset math. Defaults to `true`.
    public init(renderMath: Bool = true) {
        self.renderMath = renderMath
    }

    /// Options with every switch enabled.
    public static let `default` = MarkdownRenderingOptions()
}

// MARK: - Environment Key

private struct MarkdownRenderingOptionsKey: EnvironmentKey {
    static let defaultValue: MarkdownRenderingOptions = .default
}

extension EnvironmentValues {

    /// The rendering options in effect for this view hierarchy.
    ///
    /// Both ``MarkdownView`` and ``MathText`` read this.
    ///
    /// Set it with the ``SwiftUICore/View/markdownRenderingOptions(_:)`` modifier.
    public var markdownRenderingOptions: MarkdownRenderingOptions {
        get { self[MarkdownRenderingOptionsKey.self] }
        set { self[MarkdownRenderingOptionsKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets the rendering options for this view hierarchy.
    ///
    /// - Parameter options: The options to use.
    public func markdownRenderingOptions(_ options: MarkdownRenderingOptions) -> some View {
        environment(\.markdownRenderingOptions, options)
    }
}

// MARK: - Applying the options

extension MarkdownRenderingOptions {

    /// The attachment renderer a document should be built with, given the math renderer in effect.
    ///
    /// With ``renderMath`` off, math is refused so that `MarkdownAttributedBuilder` writes the
    /// LaTeX source as text instead of an attachment. Images and Mermaid diagrams still reach
    /// `base`.
    func attachmentRenderer(wrapping base: any MarkdownAttachmentRendering) -> any MarkdownAttachmentRendering {
        renderMath ? base : MathSuppressingAttachmentRenderer(base: base)
    }
}

/// An attachment renderer that refuses math and passes every other attachment to the one it wraps.
struct MathSuppressingAttachmentRenderer: MarkdownAttachmentRendering {

    let base: any MarkdownAttachmentRendering

    func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage? {
        switch kind {
        case .inlineMath, .displayMath:
            return nil
        case .image, .mermaid:
            return base.renderedImage(for: kind, theme: theme)
        }
    }
}
