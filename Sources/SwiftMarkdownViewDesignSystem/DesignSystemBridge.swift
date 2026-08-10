import SwiftUI
import DesignSystem
import SwiftMarkdownView

// MARK: - Palette

/// Reads a `swift-design-system` color palette as Markdown colors.
public struct DesignSystemMarkdownPalette: MarkdownPalette {

    private let palette: any ColorPalette

    public init(_ palette: any ColorPalette) {
        self.palette = palette
    }

    public var text: Color { palette.onSurface }
    public var secondaryText: Color { palette.onSurfaceVariant }
    public var heading: Color { palette.onSurface }
    public var link: Color { palette.primary }
    public var codeBackground: Color { palette.surfaceVariant }
    public var rule: Color { palette.outlineVariant }
}

// MARK: - Metrics

/// Reads a `swift-design-system` spacing scale as Markdown metrics.
public struct DesignSystemMarkdownMetrics: MarkdownMetrics {

    private let spacing: any SpacingScale

    public init(_ spacing: any SpacingScale) {
        self.spacing = spacing
    }

    public var paragraphSpacing: CGFloat { spacing.md }
    public var indentStep: CGFloat { spacing.xl }
}

// MARK: - Type scale

/// Reads the `swift-design-system` `Typography` tokens as Markdown font sizes.
public struct DesignSystemMarkdownTypeScale: MarkdownTypeScale {

    public init() {}

    public var bodySize: CGFloat { Typography.bodyLarge.size }

    public var headingSizes: [CGFloat] {
        [
            Typography.headlineLarge.size,
            Typography.headlineMedium.size,
            Typography.headlineSmall.size,
            Typography.titleLarge.size,
            Typography.titleMedium.size,
            Typography.titleSmall.size,
        ]
    }
}

// MARK: - View Extension

extension View {

    /// Applies the design system theme to the Markdown views in this hierarchy.
    ///
    /// Markdown colors, metrics, and font sizes then follow the app's theme.
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownTheme(themeProvider)
    /// ```
    ///
    /// - Parameter provider: The theme provider whose tokens are published to the
    ///   environment and then mirrored into the Markdown environment values.
    public func markdownTheme(_ provider: ThemeProvider) -> some View {
        self.theme(provider)
            .markdownDesignSystemTokens()
    }

    /// Mirrors the design system tokens already in the environment into the Markdown environment values.
    ///
    /// Use this when you apply `.theme(_:)` yourself.
    public func markdownDesignSystemTokens() -> some View {
        modifier(DesignSystemTokenBridge())
    }
}

/// Reads the tokens a theme provider puts in the environment and mirrors them into the Markdown environment values.
private struct DesignSystemTokenBridge: ViewModifier {

    @Environment(\.colorPalette) private var palette
    @Environment(\.spacingScale) private var spacing

    func body(content: Content) -> some View {
        content
            .markdownPalette(DesignSystemMarkdownPalette(palette))
            .markdownMetrics(DesignSystemMarkdownMetrics(spacing))
            .markdownTypeScale(DesignSystemMarkdownTypeScale())
    }
}
