import SwiftUI
import DesignSystem

// MARK: - TableStyle Protocol

/// A protocol that defines the visual styling for tables.
///
/// Implement this protocol to customize the appearance of tables
/// in your Markdown content.
///
/// ## Example
///
/// ```swift
/// struct MyTableStyle: TableStyle {
///     var showBorder: Bool { true }
///     var stripedRows: Bool { true }
///
///     func headerBackgroundColor(_ palette: any ColorPalette) -> Color {
///         palette.primaryContainer
///     }
/// }
///
/// MarkdownView(source)
///     .tableStyle(MyTableStyle())
/// ```
public protocol TableStyle: Sendable {

    /// Whether to show a border around the table.
    var showBorder: Bool { get }

    /// Whether to show borders between columns.
    var showColumnBorders: Bool { get }

    /// Whether to show borders between rows.
    var showRowBorders: Bool { get }

    /// Whether to use alternating row colors (striped rows).
    var stripedRows: Bool { get }

    /// The corner radius for the table container.
    ///
    /// - Parameter radius: The current radius scale from the environment.
    /// - Returns: The corner radius in points.
    func cornerRadius(_ radius: any RadiusScale) -> CGFloat

    /// The background color for the header row.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The header background color.
    func headerBackgroundColor(_ palette: any ColorPalette) -> Color

    /// The text color for the header row.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The header text color.
    func headerTextColor(_ palette: any ColorPalette) -> Color

    /// The background color for regular rows.
    ///
    /// - Parameters:
    ///   - palette: The current color palette from the environment.
    ///   - isAlternate: Whether this is an alternate (odd-numbered) row.
    /// - Returns: The row background color.
    func rowBackgroundColor(_ palette: any ColorPalette, isAlternate: Bool) -> Color

    /// The text color for regular rows.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The row text color.
    func rowTextColor(_ palette: any ColorPalette) -> Color

    /// The border color for the table.
    ///
    /// - Parameter palette: The current color palette from the environment.
    /// - Returns: The border color.
    func borderColor(_ palette: any ColorPalette) -> Color

    /// The border width for the table.
    var borderWidth: CGFloat { get }

    /// The horizontal padding for cells.
    ///
    /// - Parameter spacing: The current spacing scale from the environment.
    /// - Returns: The horizontal padding in points.
    func cellHorizontalPadding(_ spacing: any SpacingScale) -> CGFloat

    /// The vertical padding for cells.
    ///
    /// - Parameter spacing: The current spacing scale from the environment.
    /// - Returns: The vertical padding in points.
    func cellVerticalPadding(_ spacing: any SpacingScale) -> CGFloat
}

// MARK: - Default Implementation

/// Provides default implementations for optional protocol methods.
extension TableStyle {

    public var showColumnBorders: Bool { true }
    public var showRowBorders: Bool { true }
    public var borderWidth: CGFloat { 1 }

    public func cornerRadius(_ radius: any RadiusScale) -> CGFloat {
        radius.sm
    }

    public func headerTextColor(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    public func rowTextColor(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    public func borderColor(_ palette: any ColorPalette) -> Color {
        palette.outlineVariant
    }

    public func cellHorizontalPadding(_ spacing: any SpacingScale) -> CGFloat {
        spacing.sm
    }

    public func cellVerticalPadding(_ spacing: any SpacingScale) -> CGFloat {
        spacing.xs
    }
}

// MARK: - DefaultTableStyle

/// The default table style with subtle borders and header highlighting.
public struct DefaultTableStyle: TableStyle, Sendable {

    public var showBorder: Bool
    public var stripedRows: Bool

    /// Creates a new default table style.
    ///
    /// - Parameters:
    ///   - showBorder: Whether to show a border around the table. Defaults to `true`.
    ///   - stripedRows: Whether to use alternating row colors. Defaults to `false`.
    public init(
        showBorder: Bool = true,
        stripedRows: Bool = false
    ) {
        self.showBorder = showBorder
        self.stripedRows = stripedRows
    }

    public func headerBackgroundColor(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant.opacity(0.5)
    }

    public func rowBackgroundColor(_ palette: any ColorPalette, isAlternate: Bool) -> Color {
        if stripedRows && isAlternate {
            return palette.surfaceVariant.opacity(0.2)
        }
        return .clear
    }
}

// MARK: - StripedTableStyle

/// A table style with alternating row colors for better readability.
public struct StripedTableStyle: TableStyle, Sendable {

    public var showBorder: Bool { true }
    public var stripedRows: Bool { true }

    public init() {}

    public func headerBackgroundColor(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant
    }

    public func rowBackgroundColor(_ palette: any ColorPalette, isAlternate: Bool) -> Color {
        isAlternate ? palette.surfaceVariant.opacity(0.3) : .clear
    }
}

// MARK: - BorderlessTableStyle

/// A minimal table style without borders.
public struct BorderlessTableStyle: TableStyle, Sendable {

    public var showBorder: Bool { false }
    public var showColumnBorders: Bool { false }
    public var showRowBorders: Bool { false }
    public var stripedRows: Bool { true }

    public init() {}

    public func cornerRadius(_ radius: any RadiusScale) -> CGFloat {
        0
    }

    public func headerBackgroundColor(_ palette: any ColorPalette) -> Color {
        .clear
    }

    public func headerTextColor(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    public func rowBackgroundColor(_ palette: any ColorPalette, isAlternate: Bool) -> Color {
        isAlternate ? palette.surfaceVariant.opacity(0.2) : .clear
    }
}

// MARK: - CardTableStyle

/// A table style that looks like a card with rounded corners and shadow.
public struct CardTableStyle: TableStyle, Sendable {

    public var showBorder: Bool { true }
    public var stripedRows: Bool { false }

    public init() {}

    public func cornerRadius(_ radius: any RadiusScale) -> CGFloat {
        radius.md
    }

    public func headerBackgroundColor(_ palette: any ColorPalette) -> Color {
        palette.primaryContainer.opacity(0.3)
    }

    public func headerTextColor(_ palette: any ColorPalette) -> Color {
        palette.onPrimaryContainer
    }

    public func rowBackgroundColor(_ palette: any ColorPalette, isAlternate: Bool) -> Color {
        palette.surface
    }

    public func borderColor(_ palette: any ColorPalette) -> Color {
        palette.outline.opacity(0.5)
    }
}

// MARK: - Environment Key

private struct TableStyleKey: EnvironmentKey {
    static let defaultValue: any TableStyle = DefaultTableStyle()
}

extension EnvironmentValues {

    /// The style used for rendering tables.
    ///
    /// Use the ``SwiftUICore/View/tableStyle(_:)-swift.method`` modifier to set this value.
    public var markdownTableStyle: any TableStyle {
        get { self[TableStyleKey.self] }
        set { self[TableStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// Sets a custom table style for Markdown tables in this view hierarchy.
    ///
    /// Use this modifier to customize the appearance of tables
    /// rendered by ``MarkdownView``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// | Name | Age |
    /// |------|-----|
    /// | Alice | 30 |
    /// | Bob | 25 |
    /// """)
    /// .markdownTableStyle(StripedTableStyle())
    /// ```
    ///
    /// - Parameter style: The table style to use.
    /// - Returns: A view with the table style applied.
    public func markdownTableStyle(_ style: some TableStyle) -> some View {
        environment(\.markdownTableStyle, style)
    }
}
