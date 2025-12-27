import SwiftUI
import DesignSystem

// MARK: - Markdown Typography Mapping

/// Maps Markdown heading levels to DesignSystem Typography tokens.
public enum MarkdownTypographyMapping {

    /// Returns the appropriate Typography token for a heading level.
    public static func typography(for headingLevel: Int) -> Typography {
        switch headingLevel {
        case 1: return .displayMedium
        case 2: return .headlineLarge
        case 3: return .headlineMedium
        case 4: return .titleLarge
        case 5: return .titleMedium
        case 6: return .titleSmall
        default: return .bodyLarge
        }
    }

    /// Typography for body text (paragraphs).
    public static var body: Typography { .bodyLarge }

    /// Typography for inline code.
    public static var inlineCode: Typography { .bodyMedium }

    /// Typography for code blocks.
    public static var codeBlock: Typography { .bodySmall }

    /// Typography for blockquote text.
    public static var blockquote: Typography { .bodyLarge }
}

// MARK: - Markdown Spacing

/// Spacing values for Markdown layout using DesignSystem tokens.
public enum MarkdownSpacing {

    /// Spacing between block elements.
    public static func blockSpacing(_ scale: any SpacingScale) -> CGFloat {
        scale.md
    }

    /// Top padding for H1.
    public static func heading1TopPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.xl
    }

    /// Top padding for H2.
    public static func heading2TopPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.lg
    }

    /// Top padding for H3-H6.
    public static func headingTopPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.md
    }

    /// Padding inside code blocks.
    public static func codeBlockPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.md
    }

    /// Left padding for blockquotes.
    public static func blockquoteLeftPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.lg
    }

    /// Indent for list items.
    public static func listIndent(_ scale: any SpacingScale) -> CGFloat {
        scale.lg
    }
}

// MARK: - Markdown Colors

/// Color mappings for Markdown elements using DesignSystem ColorPalette.
public enum MarkdownColors {

    /// Text color for body content.
    public static func bodyText(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    /// Text color for headings.
    public static func headingText(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    /// Color for links.
    public static func link(_ palette: any ColorPalette) -> Color {
        palette.primary
    }

    /// Background color for code blocks.
    public static func codeBlockBackground(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant
    }

    /// Text color for code.
    public static func codeText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    /// Border color for blockquotes.
    public static func blockquoteBorder(_ palette: any ColorPalette) -> Color {
        palette.outlineVariant
    }

    /// Text color for blockquotes.
    public static func blockquoteText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    /// Color for list bullets.
    public static func listBullet(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    /// Background color for inline code.
    public static func inlineCodeBackground(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant
    }

    /// Text color for inline code.
    public static func inlineCodeText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }
}

// MARK: - Markdown Radius

/// Corner radius values for Markdown elements.
public enum MarkdownRadius {

    /// Corner radius for code blocks.
    public static func codeBlock(_ scale: any RadiusScale) -> CGFloat {
        scale.md
    }

    /// Corner radius for inline code.
    public static func inlineCode(_ scale: any RadiusScale) -> CGFloat {
        scale.xs
    }
}
