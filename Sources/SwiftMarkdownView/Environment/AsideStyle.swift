import SwiftUI
import DesignSystem

// MARK: - AsideStyle Protocol

/// A protocol that defines the visual styling for aside blocks.
///
/// Implement this protocol to customize the icon, colors, and appearance
/// of aside (callout/admonition) blocks in your Markdown content.
///
/// ## Example
///
/// ```swift
/// struct MyAsideStyle: AsideStyle {
///     func icon(for kind: AsideKind) -> String {
///         switch kind {
///         case .warning: return "flame.fill"
///         default: return DefaultAsideStyle().icon(for: kind)
///         }
///     }
///
///     func accentColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
///         switch kind {
///         case .tip: return .mint
///         default: return DefaultAsideStyle().accentColor(for: kind, colorPalette: colorPalette)
///         }
///     }
///
///     func backgroundColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
///         accentColor(for: kind, colorPalette: colorPalette).opacity(0.15)
///     }
///
///     func titleColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
///         accentColor(for: kind, colorPalette: colorPalette)
///     }
/// }
///
/// // Usage
/// MarkdownView(source)
///     .asideStyle(MyAsideStyle())
/// ```
public protocol AsideStyle: Sendable {

    /// Returns the SF Symbol name for the given aside kind.
    ///
    /// - Parameter kind: The kind of aside.
    /// - Returns: An SF Symbol name to display as the aside icon.
    func icon(for kind: AsideKind) -> String

    /// Returns the accent color for the given aside kind.
    ///
    /// The accent color is used for the left border and icon.
    ///
    /// - Parameters:
    ///   - kind: The kind of aside.
    ///   - colorPalette: The current color palette from the environment.
    /// - Returns: The accent color for this aside kind.
    func accentColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color

    /// Returns the background color for the given aside kind.
    ///
    /// - Parameters:
    ///   - kind: The kind of aside.
    ///   - colorPalette: The current color palette from the environment.
    /// - Returns: The background color for this aside kind.
    func backgroundColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color

    /// Returns the title text color for the given aside kind.
    ///
    /// - Parameters:
    ///   - kind: The kind of aside.
    ///   - colorPalette: The current color palette from the environment.
    /// - Returns: The title color for this aside kind.
    func titleColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color
}

// MARK: - DefaultAsideStyle

/// The default aside style with semantic colors for common aside kinds.
///
/// This style provides sensible defaults that work well with both
/// light and dark color schemes.
public struct DefaultAsideStyle: AsideStyle, Sendable {

    public init() {}

    public func icon(for kind: AsideKind) -> String {
        switch kind {
        case .note:
            return "info.circle.fill"
        case .tip:
            return "lightbulb.fill"
        case .important:
            return "exclamationmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .experiment:
            return "flask.fill"
        case .attention:
            return "bell.fill"
        case .author, .authors:
            return "person.fill"
        case .bug:
            return "ladybug.fill"
        case .complexity:
            return "chart.bar.fill"
        case .copyright:
            return "c.circle.fill"
        case .date:
            return "calendar"
        case .invariant:
            return "lock.fill"
        case .mutatingVariant, .nonMutatingVariant:
            return "arrow.triangle.swap"
        case .postcondition, .precondition:
            return "checkmark.seal.fill"
        case .remark:
            return "quote.bubble.fill"
        case .requires:
            return "list.bullet.rectangle.fill"
        case .since:
            return "clock.fill"
        case .todo:
            return "checklist"
        case .version:
            return "tag.fill"
        case .throws:
            return "xmark.octagon.fill"
        case .seeAlso:
            return "link"
        case .custom:
            return "text.bubble.fill"
        }
    }

    public func accentColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        switch kind {
        case .note, .remark:
            return colorPalette.primary
        case .tip, .experiment:
            return Color.green
        case .important, .attention:
            return Color.orange
        case .warning, .bug, .throws:
            return Color.red
        case .todo:
            return Color.purple
        case .seeAlso:
            return colorPalette.secondary
        default:
            return colorPalette.onSurfaceVariant
        }
    }

    public func backgroundColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        accentColor(for: kind, colorPalette: colorPalette).opacity(0.1)
    }

    public func titleColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        accentColor(for: kind, colorPalette: colorPalette)
    }
}

// MARK: - Environment Key

private struct AsideStyleKey: EnvironmentKey {
    static let defaultValue: any AsideStyle = DefaultAsideStyle()
}

extension EnvironmentValues {

    /// The style used for rendering aside blocks.
    ///
    /// Use the ``SwiftUICore/View/asideStyle(_:)`` modifier to set this value.
    public var asideStyle: any AsideStyle {
        get { self[AsideStyleKey.self] }
        set { self[AsideStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets a custom aside style for this view hierarchy.
    ///
    /// Use this modifier to customize the appearance of aside blocks
    /// (callouts/admonitions) rendered by ``MarkdownView``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// > Note: This is a note.
    /// > Warning: This is a warning.
    /// """)
    /// .asideStyle(MyCustomAsideStyle())
    /// ```
    ///
    /// - Parameter style: The aside style to use.
    /// - Returns: A view with the aside style applied.
    public func asideStyle(_ style: some AsideStyle) -> some View {
        environment(\.asideStyle, style)
    }
}
