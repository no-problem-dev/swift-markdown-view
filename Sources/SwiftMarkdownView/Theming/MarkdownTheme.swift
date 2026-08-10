import SwiftUI

// MARK: - MarkdownPalette

/// The colors a Markdown document is drawn with.
///
/// The requirements are named by the role they play, not after any one design system. If you
/// already use `swift-design-system`, add `SwiftMarkdownViewDesignSystem` and its `ColorPalette`
/// conforms as it stands.
public protocol MarkdownPalette: Sendable {

    /// The color of body text.
    ///
    /// It is also the color every inline run starts from, which is how quoting works: inside a
    /// block quote, the runs still carrying this color are the ones repainted in `secondaryText`.
    var text: Color { get }

    /// The color for text that should read as subordinate to the body.
    ///
    /// It paints quoted body text, list bullets and numbers, and the glyphs of inline code.
    var secondaryText: Color { get }

    /// The color of heading text, at every level.
    var heading: Color { get }

    /// The color of link text.
    var link: Color { get }

    /// The background behind code.
    ///
    /// It fills both the highlight drawn behind inline code and the rounded box behind a code
    /// block, so it has to stay legible under `secondaryText` glyphs.
    var codeBackground: Color { get }

    /// The color of the vertical bar beside a block quote and of thematic-break lines.
    ///
    /// An aside with an explicit kind — `Note`, `Warning`, and the like — overrides the bar with
    /// a color of its own, so this applies to plain quotes.
    var rule: Color { get }
}

/// The default palette, built from system semantic colors so it follows light and dark appearance.
public struct DefaultMarkdownPalette: MarkdownPalette {

    public init() {}

    public var text: Color { .primary }
    public var secondaryText: Color { .secondary }
    public var heading: Color { .primary }
    public var link: Color { .accentColor }
    public var codeBackground: Color { Color.secondary.opacity(0.12) }
    public var rule: Color { Color.secondary.opacity(0.4) }
}

// MARK: - MarkdownMetrics

/// The dimensions Markdown blocks are laid out with.
public protocol MarkdownMetrics: Sendable {

    /// The space left below a block.
    ///
    /// Blocks other than paragraphs scale it: a heading also takes half of it above itself, list
    /// items take about a third, and table rows a fifth. Setting it moves all of them together.
    var paragraphSpacing: CGFloat { get }

    /// The head indent added for each level of nesting.
    ///
    /// It indents block quotes, list content, code blocks, and tables alike, and it is the width
    /// the vertical quote bar is positioned within.
    var indentStep: CGFloat { get }
}

/// The default metrics: 16 points below a block, and a 32-point indent per level.
public struct DefaultMarkdownMetrics: MarkdownMetrics {

    public init() {}

    public var paragraphSpacing: CGFloat { 16 }
    public var indentStep: CGFloat { 32 }
}

// MARK: - MarkdownTypeScale

/// The font sizes Markdown text is set in.
public protocol MarkdownTypeScale: Sendable {

    /// The point size of body text.
    ///
    /// Code is set at 92% of it, so raising this raises the monospaced font along with the body.
    var bodySize: CGFloat { get }

    /// The point sizes for heading levels 1 through 6, in order.
    ///
    /// - Important: The heading level indexes this array directly. Supply all six values —
    ///   a shorter array traps when a heading of a missing level is rendered.
    var headingSizes: [CGFloat] { get }
}

/// The default type scale: 17-point body text, with headings from 32 points down to 17.
public struct DefaultMarkdownTypeScale: MarkdownTypeScale {

    public init() {}

    public var bodySize: CGFloat { 17 }
    public var headingSizes: [CGFloat] { [32, 28, 24, 22, 20, 17] }
}

// MARK: - Environment

private struct MarkdownPaletteKey: EnvironmentKey {
    static let defaultValue: any MarkdownPalette = DefaultMarkdownPalette()
}

private struct MarkdownMetricsKey: EnvironmentKey {
    static let defaultValue: any MarkdownMetrics = DefaultMarkdownMetrics()
}

private struct MarkdownTypeScaleKey: EnvironmentKey {
    static let defaultValue: any MarkdownTypeScale = DefaultMarkdownTypeScale()
}

extension EnvironmentValues {

    /// The colors Markdown is drawn with.
    public var markdownPalette: any MarkdownPalette {
        get { self[MarkdownPaletteKey.self] }
        set { self[MarkdownPaletteKey.self] = newValue }
    }

    /// The dimensions Markdown blocks are laid out with.
    public var markdownMetrics: any MarkdownMetrics {
        get { self[MarkdownMetricsKey.self] }
        set { self[MarkdownMetricsKey.self] = newValue }
    }

    /// The font sizes Markdown text is set in.
    public var markdownTypeScale: any MarkdownTypeScale {
        get { self[MarkdownTypeScaleKey.self] }
        set { self[MarkdownTypeScaleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets the colors Markdown is drawn with in this view hierarchy.
    public func markdownPalette(_ palette: some MarkdownPalette) -> some View {
        environment(\.markdownPalette, palette)
    }

    /// Sets the dimensions Markdown blocks are laid out with in this view hierarchy.
    public func markdownMetrics(_ metrics: some MarkdownMetrics) -> some View {
        environment(\.markdownMetrics, metrics)
    }

    /// Sets the font sizes Markdown text is set in for this view hierarchy.
    public func markdownTypeScale(_ scale: some MarkdownTypeScale) -> some View {
        environment(\.markdownTypeScale, scale)
    }
}
