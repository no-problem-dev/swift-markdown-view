import SwiftUI
import DesignSystem

// MARK: - Markdown Typography Mapping

// MARK: - Markdown Spacing

/// DesignSystem トークンを使用した Markdown レイアウトのスペーシング値。
enum MarkdownSpacing {

    /// コードブロック内のパディング。
    static func codeBlockPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.md
    }
}

// MARK: - Markdown Colors

/// DesignSystem ColorPalette を使用した Markdown 要素のカラーマッピング。
enum MarkdownColors {

    /// ボディコンテンツのテキストカラー。
    static func bodyText(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    /// 見出しのテキストカラー。
    static func headingText(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    /// リンクのカラー。
    static func link(_ palette: any ColorPalette) -> Color {
        palette.primary
    }

    /// コードブロックの背景色。
    static func codeBlockBackground(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant
    }

    /// コードのテキストカラー。
    static func codeText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    /// ブロッククォートのボーダーカラー。
    static func blockquoteBorder(_ palette: any ColorPalette) -> Color {
        palette.outlineVariant
    }

    /// ブロッククォートのテキストカラー。
    static func blockquoteText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    /// インラインコードの背景色。
    static func inlineCodeBackground(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant
    }

    /// インラインコードのテキストカラー。
    static func inlineCodeText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }
}

// MARK: - Markdown Radius

/// Markdown 要素のコーナー半径値。
enum MarkdownRadius {

    /// コードブロックのコーナー半径。
    static func codeBlock(_ scale: any RadiusScale) -> CGFloat {
        scale.md
    }
}
