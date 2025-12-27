import SwiftUI
import DesignSystem

/// Color mappings for syntax highlighting derived from DesignSystem's ColorPalette.
///
/// This struct bridges the gap between syntax token kinds and visual colors,
/// using the DesignSystem's semantic color system for consistency.
public struct SyntaxColors: Sendable {

    /// Color for language keywords (func, let, const, if, etc.).
    public let keyword: Color

    /// Color for string literals.
    public let string: Color

    /// Color for comments.
    public let comment: Color

    /// Color for numeric literals.
    public let number: Color

    /// Color for type names.
    public let type: Color

    /// Color for property access.
    public let property: Color

    /// Color for punctuation and operators.
    public let punctuation: Color

    /// Color for plain text.
    public let plain: Color

    /// Creates syntax colors from a DesignSystem ColorPalette.
    ///
    /// The mapping uses semantic colors from the palette to ensure
    /// consistency with the overall app theme.
    ///
    /// - Parameter palette: The color palette to derive colors from.
    public init(from palette: ColorPalette) {
        // Keywords use the primary color for emphasis
        self.keyword = palette.primary

        // Strings use tertiary for visual distinction
        self.string = palette.tertiary

        // Comments are de-emphasized with variant color
        self.comment = palette.onSurfaceVariant

        // Numbers use secondary color
        self.number = palette.secondary

        // Types use primary with slight transparency
        self.type = palette.primary.opacity(0.85)

        // Properties use secondary for consistency with numbers
        self.property = palette.secondary

        // Punctuation is subtle
        self.punctuation = palette.onSurface.opacity(0.6)

        // Plain text uses standard on-surface color
        self.plain = palette.onSurface
    }

    /// Creates syntax colors with explicit color values.
    ///
    /// Use this initializer for custom color schemes that don't
    /// derive from a ColorPalette.
    public init(
        keyword: Color,
        string: Color,
        comment: Color,
        number: Color,
        type: Color,
        property: Color,
        punctuation: Color,
        plain: Color
    ) {
        self.keyword = keyword
        self.string = string
        self.comment = comment
        self.number = number
        self.type = type
        self.property = property
        self.punctuation = punctuation
        self.plain = plain
    }

    /// Returns the color for a given token kind.
    ///
    /// - Parameter kind: The syntax token kind.
    /// - Returns: The color to use for rendering.
    public func color(for kind: SyntaxTokenKind) -> Color {
        switch kind {
        case .keyword: keyword
        case .string: string
        case .comment: comment
        case .number: number
        case .type: type
        case .property: property
        case .punctuation: punctuation
        case .plain: plain
        }
    }
}

// MARK: - Default Colors

extension SyntaxColors {

    /// Default syntax colors for light mode.
    ///
    /// These colors are designed to work well on light backgrounds.
    public static let light = SyntaxColors(
        keyword: Color(red: 0.61, green: 0.12, blue: 0.70),   // Purple
        string: Color(red: 0.76, green: 0.24, blue: 0.16),    // Red-orange
        comment: Color(red: 0.45, green: 0.45, blue: 0.45),   // Gray
        number: Color(red: 0.11, green: 0.44, blue: 0.69),    // Blue
        type: Color(red: 0.20, green: 0.50, blue: 0.60),      // Teal
        property: Color(red: 0.30, green: 0.45, blue: 0.55),  // Slate blue
        punctuation: Color(red: 0.30, green: 0.30, blue: 0.30), // Dark gray
        plain: Color(red: 0.13, green: 0.13, blue: 0.13)      // Near black
    )

    /// Default syntax colors for dark mode.
    ///
    /// These colors are designed to work well on dark backgrounds.
    public static let dark = SyntaxColors(
        keyword: Color(red: 0.78, green: 0.56, blue: 0.89),   // Light purple
        string: Color(red: 0.95, green: 0.55, blue: 0.46),    // Coral
        comment: Color(red: 0.55, green: 0.55, blue: 0.55),   // Gray
        number: Color(red: 0.55, green: 0.78, blue: 0.93),    // Light blue
        type: Color(red: 0.60, green: 0.80, blue: 0.75),      // Light teal
        property: Color(red: 0.65, green: 0.75, blue: 0.85),  // Light slate
        punctuation: Color(red: 0.70, green: 0.70, blue: 0.70), // Light gray
        plain: Color(red: 0.90, green: 0.90, blue: 0.90)      // Near white
    )
}
