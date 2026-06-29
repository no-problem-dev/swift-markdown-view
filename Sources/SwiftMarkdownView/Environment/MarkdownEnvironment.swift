import SwiftUI
import DesignSystem

// MARK: - Markdown Typography Mapping

/// Markdown 見出しレベルを DesignSystem タイポグラフィトークンにマッピングするユーティリティ。
enum MarkdownTypographyMapping {

    /// 見出しレベルに対応する Typography トークンを返す。
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

    /// ボディテキスト（段落）のタイポグラフィ。
    public static var body: Typography { .bodyLarge }

    /// インラインコードのタイポグラフィ。
    public static var inlineCode: Typography { .bodyMedium }

    /// コードブロックのタイポグラフィ。
    public static var codeBlock: Typography { .bodySmall }

    /// ブロッククォートテキストのタイポグラフィ。
    public static var blockquote: Typography { .bodyLarge }
}

// MARK: - Markdown Spacing

/// DesignSystem トークンを使用した Markdown レイアウトのスペーシング値。
enum MarkdownSpacing {

    /// ブロック要素間のスペーシング。
    public static func blockSpacing(_ scale: any SpacingScale) -> CGFloat {
        scale.md
    }

    /// H1 の上部パディング。
    public static func heading1TopPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.xl
    }

    /// H2 の上部パディング。
    public static func heading2TopPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.lg
    }

    /// H3〜H6 の上部パディング。
    public static func headingTopPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.md
    }

    /// コードブロック内のパディング。
    public static func codeBlockPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.md
    }

    /// ブロッククォートの左パディング。
    public static func blockquoteLeftPadding(_ scale: any SpacingScale) -> CGFloat {
        scale.lg
    }

    /// リストアイテムのインデント。
    public static func listIndent(_ scale: any SpacingScale) -> CGFloat {
        scale.lg
    }
}

// MARK: - Markdown Colors

/// DesignSystem ColorPalette を使用した Markdown 要素のカラーマッピング。
enum MarkdownColors {

    /// ボディコンテンツのテキストカラー。
    public static func bodyText(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    /// 見出しのテキストカラー。
    public static func headingText(_ palette: any ColorPalette) -> Color {
        palette.onSurface
    }

    /// リンクのカラー。
    public static func link(_ palette: any ColorPalette) -> Color {
        palette.primary
    }

    /// コードブロックの背景色。
    public static func codeBlockBackground(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant
    }

    /// コードのテキストカラー。
    public static func codeText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    /// ブロッククォートのボーダーカラー。
    public static func blockquoteBorder(_ palette: any ColorPalette) -> Color {
        palette.outlineVariant
    }

    /// ブロッククォートのテキストカラー。
    public static func blockquoteText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    /// リストの箇条書きカラー。
    public static func listBullet(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }

    /// インラインコードの背景色。
    public static func inlineCodeBackground(_ palette: any ColorPalette) -> Color {
        palette.surfaceVariant
    }

    /// インラインコードのテキストカラー。
    public static func inlineCodeText(_ palette: any ColorPalette) -> Color {
        palette.onSurfaceVariant
    }
}

// MARK: - Markdown Radius

/// Markdown 要素のコーナー半径値。
enum MarkdownRadius {

    /// コードブロックのコーナー半径。
    public static func codeBlock(_ scale: any RadiusScale) -> CGFloat {
        scale.md
    }

    /// インラインコードのコーナー半径。
    public static func inlineCode(_ scale: any RadiusScale) -> CGFloat {
        scale.xs
    }
}
