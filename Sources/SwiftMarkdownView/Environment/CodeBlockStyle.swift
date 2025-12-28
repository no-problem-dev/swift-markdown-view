import SwiftUI
import DesignSystem

// MARK: - CodeBlockStyle Protocol

/// A protocol that defines the visual styling for code blocks.
///
/// Implement this protocol to customize the appearance of fenced code blocks
/// in your Markdown content.
///
/// ## Example
///
/// ```swift
/// struct MyCodeBlockStyle: CodeBlockStyle {
///     var showLanguageLabel: Bool { true }
///     var showLineNumbers: Bool { true }
///     var showCopyButton: Bool { true }
///
///     func backgroundColor(_ palette: any ColorPalette) -> Color {
///         Color.black.opacity(0.9)
///     }
///
///     func textColor(_ palette: any ColorPalette) -> Color {
///         Color.white
///     }
/// }
///
/// MarkdownView(source)
///     .codeBlockStyle(MyCodeBlockStyle())
/// ```
public protocol CodeBlockStyle: Sendable {

    /// Whether to show the language label above the code block.
    ///
    /// When `true`, displays the language identifier (e.g., "swift", "python")
    /// above the code block.
    var showLanguageLabel: Bool { get }

    /// Whether to show line numbers alongside the code.
    ///
    /// When `true`, displays line numbers in the left margin.
    var showLineNumbers: Bool { get }

    /// Whether to show a copy button for the code.
    ///
    /// When `true`, displays a button to copy the code to clipboard.
    var showCopyButton: Bool { get }

    /// The corner radius for the code block container.
    ///
    /// - Parameter radius: The current radius scale from the environment.
    /// - Returns: The corner radius in points.
    func cornerRadius(_ radius: any RadiusScale) -> CGFloat

    /// The padding inside the code block.
    ///
    /// - Parameter spacing: The current spacing scale from the environment.
    /// - Returns: The padding in points.
    func padding(_ spacing: any SpacingScale) -> CGFloat

    /// The background color for the code block.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The background color.
    func backgroundColor(_ palette: any ColorPalette) -> Color

    /// The text color for the code.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The text color.
    func textColor(_ palette: any ColorPalette) -> Color

    /// The color for the language label text.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The label color.
    func languageLabelColor(_ palette: any ColorPalette) -> Color

    /// The color for line numbers.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The line number color.
    func lineNumberColor(_ palette: any ColorPalette) -> Color
}

// MARK: - Default Implementation

/// Provides default implementations for optional protocol methods.
extension CodeBlockStyle {

    public func cornerRadius(_ radius: any RadiusScale) -> CGFloat {
        radius.md
    }

    public func padding(_ spacing: any SpacingScale) -> CGFloat {
        spacing.md
    }

    public func languageLabelColor(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    public func lineNumberColor(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant.opacity(0.6)
    }
}

// MARK: - DefaultCodeBlockStyle

/// The default code block style with sensible defaults.
///
/// This style provides a clean, readable appearance that works well
/// with both light and dark color schemes.
public struct DefaultCodeBlockStyle: CodeBlockStyle, Sendable {

    public var showLanguageLabel: Bool
    public var showLineNumbers: Bool
    public var showCopyButton: Bool

    /// Creates a new default code block style.
    ///
    /// - Parameters:
    ///   - showLanguageLabel: Whether to show the language label. Defaults to `true`.
    ///   - showLineNumbers: Whether to show line numbers. Defaults to `false`.
    ///   - showCopyButton: Whether to show the copy button. Defaults to `false`.
    public init(
        showLanguageLabel: Bool = true,
        showLineNumbers: Bool = false,
        showCopyButton: Bool = false
    ) {
        self.showLanguageLabel = showLanguageLabel
        self.showLineNumbers = showLineNumbers
        self.showCopyButton = showCopyButton
    }

    public func backgroundColor(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant
    }

    public func textColor(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }
}

// MARK: - MinimalCodeBlockStyle

/// A minimal code block style without decorations.
///
/// This style hides the language label, line numbers, and copy button
/// for a cleaner appearance.
public struct MinimalCodeBlockStyle: CodeBlockStyle, Sendable {

    public var showLanguageLabel: Bool { false }
    public var showLineNumbers: Bool { false }
    public var showCopyButton: Bool { false }

    public init() {}

    public func backgroundColor(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant.opacity(0.5)
    }

    public func textColor(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }
}

// MARK: - TerminalCodeBlockStyle

/// A terminal-inspired code block style.
///
/// This style mimics a terminal appearance with a dark background
/// and light text.
public struct TerminalCodeBlockStyle: CodeBlockStyle, Sendable {

    public var showLanguageLabel: Bool { true }
    public var showLineNumbers: Bool { true }
    public var showCopyButton: Bool { true }

    public init() {}

    public func cornerRadius(_ radius: any RadiusScale) -> CGFloat {
        radius.lg
    }

    public func backgroundColor(_ palette: any ColorPalette) -> Color {
        Color(red: 0.1, green: 0.1, blue: 0.12)
    }

    public func textColor(_ palette: any ColorPalette) -> Color {
        Color(red: 0.9, green: 0.9, blue: 0.9)
    }

    public func languageLabelColor(_ palette: any ColorPalette) -> Color {
        Color(red: 0.6, green: 0.6, blue: 0.65)
    }

    public func lineNumberColor(_ palette: any ColorPalette) -> Color {
        Color(red: 0.4, green: 0.4, blue: 0.45)
    }
}

// MARK: - Environment Key

private struct CodeBlockStyleKey: EnvironmentKey {
    static let defaultValue: any CodeBlockStyle = DefaultCodeBlockStyle()
}

extension EnvironmentValues {

    /// The style used for rendering code blocks.
    ///
    /// Use the ``SwiftUICore/View/codeBlockStyle(_:)`` modifier to set this value.
    public var codeBlockStyle: any CodeBlockStyle {
        get { self[CodeBlockStyleKey.self] }
        set { self[CodeBlockStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets a custom code block style for this view hierarchy.
    ///
    /// Use this modifier to customize the appearance of fenced code blocks
    /// rendered by ``MarkdownView``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// ```swift
    /// let greeting = "Hello, World!"
    /// print(greeting)
    /// ```
    /// """)
    /// .codeBlockStyle(TerminalCodeBlockStyle())
    /// ```
    ///
    /// - Parameter style: The code block style to use.
    /// - Returns: A view with the code block style applied.
    public func codeBlockStyle(_ style: some CodeBlockStyle) -> some View {
        environment(\.codeBlockStyle, style)
    }
}
