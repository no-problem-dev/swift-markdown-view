import SwiftUI
import DesignSystem

// MARK: - HeadingStyle Protocol

/// 見出しの外観スタイルを定義するプロトコル。
///
/// このプロトコルを実装することで、Markdownコンテンツ内の
/// 見出し要素（H1〜H6）のタイポグラフィ・カラー・スペーシングをカスタマイズできる。
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
///     .markdownHeadingStyle(MyHeadingStyle())
/// ```
public protocol HeadingStyle: Sendable {

    /// 指定した見出しレベルに対応するタイポグラフィトークンを返す。
    ///
    /// - Parameter level: 見出しレベル（1〜6）。
    /// - Returns: 使用するタイポグラフィトークン。
    func typography(for level: Int) -> Typography

    /// 指定した見出しレベルに対応するテキストカラーを返す。
    ///
    /// - Parameters:
    ///   - level: 見出しレベル（1〜6）。
    ///   - palette: 環境から取得した現在のカラーパレット。
    /// - Returns: この見出しレベルのテキストカラー。
    func color(for level: Int, palette: any ColorPalette) -> Color

    /// 指定した見出しレベルに対応する上部パディングを返す。
    ///
    /// - Parameters:
    ///   - level: 見出しレベル（1〜6）。
    ///   - spacing: 環境から取得した現在のスペーシングスケール。
    /// - Returns: 上部パディング（ポイント）。
    func topPadding(for level: Int, spacing: any SpacingScale) -> CGFloat

    /// 指定した見出しレベルに対応する下部パディングを返す。
    ///
    /// - Parameters:
    ///   - level: 見出しレベル（1〜6）。
    ///   - spacing: 環境から取得した現在のスペーシングスケール。
    /// - Returns: 下部パディング（ポイント）。
    func bottomPadding(for level: Int, spacing: any SpacingScale) -> CGFloat

    /// 見出し下にディバイダーを表示するかどうか。
    ///
    /// - Parameter level: 見出しレベル（1〜6）。
    /// - Returns: ディバイダーを表示する場合は `true`。
    func showDivider(for level: Int) -> Bool

    /// 見出し下のディバイダーカラー。
    ///
    /// - Parameters:
    ///   - level: 見出しレベル（1〜6）。
    ///   - palette: 環境から取得した現在のカラーパレット。
    /// - Returns: ディバイダーカラー。
    func dividerColor(for level: Int, palette: any ColorPalette) -> Color
}

// MARK: - Default Implementation

/// プロトコルのオプションメソッドにデフォルト実装を提供する。
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

/// DesignSystem タイポグラフィトークンを使用するデフォルト見出しスタイル。
///
/// 見出しレベルを適切なタイポグラフィトークンにマッピングし、一貫したスペーシングを提供する。
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

/// タイポグラフィスケールを縮小したコンパクト見出しスタイル。
///
/// サイドバー・カードなど、小さい見出しが望ましい制約のある領域に適する。
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

/// 上位見出しに彩色を加えた見出しスタイル。
///
/// H1 はプライマリカラー、H2 はセカンダリカラーを使用し、その他のレベルはデフォルトの on-surface カラーを使用する。
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

/// H1・H2 の下にディバイダーを追加する見出しスタイル。
///
/// ドキュメントサイト風に上位見出しに視覚的な区切りを加える。
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

    /// 見出しのレンダリングに使用するスタイル。
    ///
    /// この値を設定するには ``SwiftUICore/View/headingStyle(_:)`` モディファイアを使用する。
    public var headingStyle: any HeadingStyle {
        get { self[HeadingStyleKey.self] }
        set { self[HeadingStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層に見出しのカスタムスタイルを設定する。
    ///
    /// ``MarkdownView`` がレンダリングする見出しの外観をカスタマイズするには
    /// このモディファイアを使用する。
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// # Main Title
    /// ## Section Header
    /// ### Subsection
    /// """)
    /// .markdownHeadingStyle(ColoredHeadingStyle())
    /// ```
    ///
    /// - Parameter style: 使用する見出しスタイル。
    /// - Returns: 見出しスタイルが適用されたビュー。
    public func markdownHeadingStyle(_ style: some HeadingStyle) -> some View {
        environment(\.headingStyle, style)
    }

    @available(*, deprecated, renamed: "markdownHeadingStyle(_:)")
    public func headingStyle(_ style: some HeadingStyle) -> some View {
        markdownHeadingStyle(style)
    }
}
