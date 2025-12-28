import SwiftUI
import DesignSystem

// MARK: - HeadingStyle Protocol

/// A protocol that defines the visual styling for headings.
///
/// Implement this protocol to customize the typography, colors, and spacing
/// of heading elements (H1-H6) in your Markdown content.
///
/// ## Example
///
/// ```swift
/// struct MyHeadingStyle: HeadingStyle {
///     func typography(for level: Int) -> Typography {
///         switch level {
///         case 1: return .displayLarge
///         case 2: return .displayMedium
///         default: return .headlineMedium
///         }
///     }
///
///     func color(for level: Int, palette: any ColorPalette) -> Color {
///         level == 1 ? palette.primary : palette.onSurface
///     }
/// }
///
/// MarkdownView(source)
///     .headingStyle(MyHeadingStyle())
/// ```
public protocol HeadingStyle: Sendable {

    /// Returns the typography token for the given heading level.
    ///
    /// - Parameter level: The heading level (1-6).
    /// - Returns: The typography token to use.
    func typography(for level: Int) -> Typography

    /// Returns the text color for the given heading level.
    ///
    /// - Parameters:
    ///   - level: The heading level (1-6).
    ///   - palette: The current color palette from the environment.
    /// - Returns: The text color for this heading level.
    func color(for level: Int, palette: any ColorPalette) -> Color

    /// Returns the top padding for the given heading level.
    ///
    /// - Parameters:
    ///   - level: The heading level (1-6).
    ///   - spacing: The current spacing scale from the environment.
    /// - Returns: The top padding in points.
    func topPadding(for level: Int, spacing: any SpacingScale) -> CGFloat

    /// Returns the bottom padding for the given heading level.
    ///
    /// - Parameters:
    ///   - level: The heading level (1-6).
    ///   - spacing: The current spacing scale from the environment.
    /// - Returns: The bottom padding in points.
    func bottomPadding(for level: Int, spacing: any SpacingScale) -> CGFloat

    /// Whether to show a divider below the heading.
    ///
    /// - Parameter level: The heading level (1-6).
    /// - Returns: `true` if a divider should be shown.
    func showDivider(for level: Int) -> Bool

    /// The color of the divider below the heading.
    ///
    /// - Parameters:
    ///   - level: The heading level (1-6).
    ///   - palette: The current color palette from the environment.
    /// - Returns: The divider color.
    func dividerColor(for level: Int, palette: any ColorPalette) -> Color
}

// MARK: - Default Implementation

/// Provides default implementations for optional protocol methods.
extension HeadingStyle {

    public func bottomPadding(for level: Int, spacing: any SpacingScale) -> CGFloat {
        spacing.xs
    }

    public func showDivider(for level: Int) -> Bool {
        false
    }

    public func dividerColor(for level: Int, palette: any ColorPalette) -> Color {
        palette.outlineVariant
    }
}

// MARK: - DefaultHeadingStyle

/// The default heading style using DesignSystem typography tokens.
///
/// This style maps heading levels to appropriate typography tokens
/// and provides consistent spacing.
public struct DefaultHeadingStyle: HeadingStyle, Sendable {

    public init() {}

    public func typography(for level: Int) -> Typography {
        switch level {
        case 1: return .displayMedium
        case 2: return .headlineLarge
        case 3: return .headlineMedium
        case 4: return .titleLarge
        case 5: return .titleMedium
        case 6: return .titleSmall
        default: return .bodyLarge
        }
    }

    public func color(for level: Int, palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    public func topPadding(for level: Int, spacing: any SpacingScale) -> CGFloat {
        switch level {
        case 1: return spacing.xl
        case 2: return spacing.lg
        default: return spacing.md
        }
    }
}

// MARK: - CompactHeadingStyle

/// A compact heading style with reduced typography scale.
///
/// This style is suitable for sidebars, cards, or other
/// constrained spaces where smaller headings are preferred.
public struct CompactHeadingStyle: HeadingStyle, Sendable {

    public init() {}

    public func typography(for level: Int) -> Typography {
        switch level {
        case 1: return .headlineMedium
        case 2: return .titleLarge
        case 3: return .titleMedium
        case 4: return .titleSmall
        case 5: return .labelLarge
        case 6: return .labelMedium
        default: return .bodyMedium
        }
    }

    public func color(for level: Int, palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    public func topPadding(for level: Int, spacing: any SpacingScale) -> CGFloat {
        switch level {
        case 1: return spacing.lg
        case 2: return spacing.md
        default: return spacing.sm
        }
    }
}

// MARK: - ColoredHeadingStyle

/// A heading style with colored primary headings.
///
/// H1 and H2 headings use the primary color,
/// while other levels use the default on-surface color.
public struct ColoredHeadingStyle: HeadingStyle, Sendable {

    public init() {}

    public func typography(for level: Int) -> Typography {
        DefaultHeadingStyle().typography(for: level)
    }

    public func color(for level: Int, palette: any ColorPalette) -> Color {
        switch level {
        case 1: return palette.primary
        case 2: return palette.secondary
        default: return palette.onSurface
        }
    }

    public func topPadding(for level: Int, spacing: any SpacingScale) -> CGFloat {
        DefaultHeadingStyle().topPadding(for: level, spacing: spacing)
    }
}

// MARK: - DividedHeadingStyle

/// A heading style with dividers below H1 and H2 headings.
///
/// This style adds visual separation for top-level headings,
/// similar to documentation sites.
public struct DividedHeadingStyle: HeadingStyle, Sendable {

    public init() {}

    public func typography(for level: Int) -> Typography {
        DefaultHeadingStyle().typography(for: level)
    }

    public func color(for level: Int, palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    public func topPadding(for level: Int, spacing: any SpacingScale) -> CGFloat {
        DefaultHeadingStyle().topPadding(for: level, spacing: spacing)
    }

    public func bottomPadding(for level: Int, spacing: any SpacingScale) -> CGFloat {
        showDivider(for: level) ? spacing.sm : spacing.xs
    }

    public func showDivider(for level: Int) -> Bool {
        level <= 2
    }
}

// MARK: - Environment Key

private struct HeadingStyleKey: EnvironmentKey {
    static let defaultValue: any HeadingStyle = DefaultHeadingStyle()
}

extension EnvironmentValues {

    /// The style used for rendering headings.
    ///
    /// Use the ``SwiftUICore/View/headingStyle(_:)`` modifier to set this value.
    public var headingStyle: any HeadingStyle {
        get { self[HeadingStyleKey.self] }
        set { self[HeadingStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets a custom heading style for this view hierarchy.
    ///
    /// Use this modifier to customize the appearance of headings
    /// rendered by ``MarkdownView``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// # Main Title
    /// ## Section Header
    /// ### Subsection
    /// """)
    /// .headingStyle(ColoredHeadingStyle())
    /// ```
    ///
    /// - Parameter style: The heading style to use.
    /// - Returns: A view with the heading style applied.
    public func headingStyle(_ style: some HeadingStyle) -> some View {
        environment(\.headingStyle, style)
    }
}
