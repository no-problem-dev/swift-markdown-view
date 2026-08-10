import SwiftUI

// MARK: - MarkdownRenderingOptions

/// Rendering switches that a view reads from the environment.
///
/// Only ``MathText`` consults these. ``MarkdownView`` typesets math through its attachment
/// renderer and is unaffected by them.
///
/// ## Example
///
/// ```swift
/// MathText("The answer: $$-6$$")
///     .markdownRenderingOptions(MarkdownRenderingOptions(renderMath: false))
/// ```
public struct MarkdownRenderingOptions: Sendable, Equatable {

    /// Whether math is typeset, or left standing as source text.
    ///
    /// ``MathText`` reads this: when `false`, it shows its source as written, delimiters and all.
    /// Math inside a ``MarkdownView`` is unaffected — that goes through the attachment renderer,
    /// which is not given this value either way.
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
    /// ``MathText`` is the only view that reads this. A ``MarkdownView`` in the same hierarchy
    /// ignores it, so setting it does not change how a rendered document typesets math.
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
    /// What this reaches is ``MathText``. It does not reach a ``MarkdownView`` below it, whose
    /// math is typeset by the attachment renderer no matter what is set here.
    ///
    /// - Parameter options: The options to use.
    public func markdownRenderingOptions(_ options: MarkdownRenderingOptions) -> some View {
        environment(\.markdownRenderingOptions, options)
    }
}
