import SwiftUI

// MARK: - MarkdownRenderingOptions

/// Options for controlling Markdown rendering behavior.
///
/// Use this struct to enable or disable specific Markdown features,
/// such as Mermaid diagrams, images, tables, and asides.
///
/// ## Example
///
/// ```swift
/// MarkdownView(source)
///     .markdownRenderingOptions(
///         MarkdownRenderingOptions(
///             renderMermaid: false,  // Disable Mermaid diagrams
///             maxImageHeight: 300    // Limit image height
///         )
///     )
/// ```
public struct MarkdownRenderingOptions: Sendable, Equatable {

    /// Whether to render Mermaid diagrams.
    ///
    /// When `false`, Mermaid code blocks are rendered as regular code blocks.
    /// Defaults to `true`.
    public var renderMermaid: Bool

    /// Whether to render images.
    ///
    /// When `false`, images are replaced with alt text placeholders.
    /// Defaults to `true`.
    public var renderImages: Bool

    /// Whether to render tables.
    ///
    /// When `false`, tables are rendered as plain text.
    /// Defaults to `true`.
    public var renderTables: Bool

    /// Whether to render aside blocks (callouts/admonitions).
    ///
    /// When `false`, asides are rendered as regular blockquotes.
    /// Defaults to `true`.
    public var renderAsides: Bool

    /// Maximum height for images in points.
    ///
    /// When set, images taller than this value are scaled down.
    /// Set to `nil` for no limit. Defaults to `nil`.
    public var maxImageHeight: CGFloat?

    /// Maximum width for images in points.
    ///
    /// When set, images wider than this value are scaled down.
    /// Set to `nil` for no limit. Defaults to `nil`.
    public var maxImageWidth: CGFloat?

    /// Whether to enable syntax highlighting for code blocks.
    ///
    /// When `false`, code blocks are rendered without highlighting.
    /// Defaults to `true`.
    public var enableSyntaxHighlighting: Bool

    /// Creates a new rendering options configuration.
    ///
    /// - Parameters:
    ///   - renderMermaid: Whether to render Mermaid diagrams. Defaults to `true`.
    ///   - renderImages: Whether to render images. Defaults to `true`.
    ///   - renderTables: Whether to render tables. Defaults to `true`.
    ///   - renderAsides: Whether to render aside blocks. Defaults to `true`.
    ///   - maxImageHeight: Maximum image height in points. Defaults to `nil`.
    ///   - maxImageWidth: Maximum image width in points. Defaults to `nil`.
    ///   - enableSyntaxHighlighting: Whether to enable syntax highlighting. Defaults to `true`.
    public init(
        renderMermaid: Bool = true,
        renderImages: Bool = true,
        renderTables: Bool = true,
        renderAsides: Bool = true,
        maxImageHeight: CGFloat? = nil,
        maxImageWidth: CGFloat? = nil,
        enableSyntaxHighlighting: Bool = true
    ) {
        self.renderMermaid = renderMermaid
        self.renderImages = renderImages
        self.renderTables = renderTables
        self.renderAsides = renderAsides
        self.maxImageHeight = maxImageHeight
        self.maxImageWidth = maxImageWidth
        self.enableSyntaxHighlighting = enableSyntaxHighlighting
    }

    /// The default rendering options with all features enabled.
    public static let `default` = MarkdownRenderingOptions()

    /// Rendering options optimized for compact display.
    ///
    /// Disables Mermaid diagrams and limits image size.
    public static let compact = MarkdownRenderingOptions(
        renderMermaid: false,
        maxImageHeight: 200,
        maxImageWidth: 300
    )

    /// Rendering options for plain text-like display.
    ///
    /// Disables complex elements like Mermaid, images, and tables.
    public static let plainText = MarkdownRenderingOptions(
        renderMermaid: false,
        renderImages: false,
        renderTables: false,
        enableSyntaxHighlighting: false
    )
}

// MARK: - Environment Key

private struct MarkdownRenderingOptionsKey: EnvironmentKey {
    static let defaultValue: MarkdownRenderingOptions = .default
}

extension EnvironmentValues {

    /// The rendering options for Markdown content.
    ///
    /// Use the ``SwiftUICore/View/markdownRenderingOptions(_:)`` modifier to set this value.
    public var markdownRenderingOptions: MarkdownRenderingOptions {
        get { self[MarkdownRenderingOptionsKey.self] }
        set { self[MarkdownRenderingOptionsKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets the rendering options for Markdown content in this view hierarchy.
    ///
    /// Use this modifier to control which Markdown features are rendered
    /// and how they appear.
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// # Hello World
    ///
    /// ```mermaid
    /// graph TD
    ///     A --> B
    /// ```
    /// """)
    /// .markdownRenderingOptions(.compact)
    /// ```
    ///
    /// - Parameter options: The rendering options to use.
    /// - Returns: A view with the rendering options applied.
    public func markdownRenderingOptions(_ options: MarkdownRenderingOptions) -> some View {
        environment(\.markdownRenderingOptions, options)
    }
}
