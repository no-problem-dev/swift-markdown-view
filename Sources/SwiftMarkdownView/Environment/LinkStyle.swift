import SwiftUI
import DesignSystem

// MARK: - LinkStyle Protocol

/// A protocol that defines the visual styling for links.
///
/// Implement this protocol to customize the appearance of links
/// in your Markdown content.
///
/// ## Example
///
/// ```swift
/// struct MyLinkStyle: LinkStyle {
///     var showUnderline: Bool { true }
///
///     func color(_ palette: any ColorPalette) -> Color {
///         palette.tertiary
///     }
/// }
///
/// MarkdownView(source)
///     .linkStyle(MyLinkStyle())
/// ```
public protocol LinkStyle: Sendable {

    /// Whether to show an underline for links.
    var showUnderline: Bool { get }

    /// The underline style for links.
    ///
    /// Only used when `showUnderline` is `true`.
    var underlineStyle: Text.LineStyle { get }

    /// The text color for links.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The link color.
    func color(_ palette: any ColorPalette) -> Color

    /// The text color for visited links (if tracking is enabled).
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The visited link color.
    func visitedColor(_ palette: any ColorPalette) -> Color

    /// The text color for hovered links.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The hover color.
    func hoverColor(_ palette: any ColorPalette) -> Color

    /// The font weight for links.
    var fontWeight: Font.Weight? { get }
}

// MARK: - Default Implementation

/// Provides default implementations for optional protocol methods.
extension LinkStyle {

    public var underlineStyle: Text.LineStyle {
        .single
    }

    public func visitedColor(_ palette: any ColorPalette) -> Color {
        color(palette).opacity(0.7)
    }

    public func hoverColor(_ palette: any ColorPalette) -> Color {
        color(palette).opacity(0.8)
    }

    public var fontWeight: Font.Weight? {
        nil
    }
}

// MARK: - DefaultLinkStyle

/// The default link style using the primary color with underline.
public struct DefaultLinkStyle: LinkStyle, Sendable {

    public var showUnderline: Bool

    /// Creates a new default link style.
    ///
    /// - Parameter showUnderline: Whether to show an underline. Defaults to `true`.
    public init(showUnderline: Bool = true) {
        self.showUnderline = showUnderline
    }

    public func color(_ palette: any ColorPalette) -> Color {
        palette.primary
    }
}

// MARK: - SubtleLinkStyle

/// A subtle link style without underline.
///
/// Links are distinguished only by color, providing a cleaner appearance.
public struct SubtleLinkStyle: LinkStyle, Sendable {

    public var showUnderline: Bool { false }

    public init() {}

    public func color(_ palette: any ColorPalette) -> Color {
        palette.primary
    }
}

// MARK: - BoldLinkStyle

/// A bold link style with emphasis.
///
/// Links are displayed in bold with the secondary color.
public struct BoldLinkStyle: LinkStyle, Sendable {

    public var showUnderline: Bool { false }

    public var fontWeight: Font.Weight? { .semibold }

    public init() {}

    public func color(_ palette: any ColorPalette) -> Color {
        palette.secondary
    }
}

// MARK: - ClassicLinkStyle

/// A classic web-style link appearance.
///
/// Blue color with underline, similar to traditional web links.
public struct ClassicLinkStyle: LinkStyle, Sendable {

    public var showUnderline: Bool { true }

    public init() {}

    public func color(_ palette: any ColorPalette) -> Color {
        Color.blue
    }

    public func visitedColor(_ palette: any ColorPalette) -> Color {
        Color.purple
    }
}

// MARK: - MonochromeLinkStyle

/// A monochrome link style that blends with the text.
///
/// Links are underlined but use the same color as regular text.
public struct MonochromeLinkStyle: LinkStyle, Sendable {

    public var showUnderline: Bool { true }

    public init() {}

    public func color(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    public func visitedColor(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }
}

// MARK: - Environment Key

private struct LinkStyleKey: EnvironmentKey {
    static let defaultValue: any LinkStyle = DefaultLinkStyle()
}

extension EnvironmentValues {

    /// The style used for rendering links.
    ///
    /// Use the ``SwiftUICore/View/markdownLinkStyle(_:)`` modifier to set this value.
    public var markdownLinkStyle: any LinkStyle {
        get { self[LinkStyleKey.self] }
        set { self[LinkStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets a custom link style for Markdown links in this view hierarchy.
    ///
    /// Use this modifier to customize the appearance of links
    /// rendered by ``MarkdownView``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// Check out [SwiftUI](https://developer.apple.com/xcode/swiftui/)
    /// for more information.
    /// """)
    /// .markdownLinkStyle(ClassicLinkStyle())
    /// ```
    ///
    /// - Parameter style: The link style to use.
    /// - Returns: A view with the link style applied.
    public func markdownLinkStyle(_ style: some LinkStyle) -> some View {
        environment(\.markdownLinkStyle, style)
    }
}
