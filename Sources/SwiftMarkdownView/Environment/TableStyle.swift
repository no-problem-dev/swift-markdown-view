import SwiftUI
import DesignSystem

// MARK: - TableStyle Protocol

/// テーブルの外観スタイルを定義するプロトコル。
///
/// このプロトコルを実装することで、Markdownコンテンツ内の
/// テーブルの外観をカスタマイズできる。
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

    /// テーブル周囲にボーダーを表示するかどうか。
    var showBorder: Bool { get }

    /// 列間にボーダーを表示するかどうか。
    var showColumnBorders: Bool { get }

    /// 行間にボーダーを表示するかどうか。
    var showRowBorders: Bool { get }

    /// 交互に行カラーを使用する（縞模様行）かどうか。
    var stripedRows: Bool { get }

    /// テーブルコンテナのコーナー半径。
    ///
    /// - Parameter radius: 環境から取得した現在の半径スケール。
    /// - Returns: コーナー半径（ポイント）。
    func cornerRadius(_ radius: any RadiusScale) -> CGFloat

    /// ヘッダー行の背景色。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: ヘッダー背景色。
    func headerBackgroundColor(_ palette: any ColorPalette) -> Color

    /// ヘッダー行のテキストカラー。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: ヘッダーテキストカラー。
    func headerTextColor(_ palette: any ColorPalette) -> Color

    /// 通常行の背景色。
    ///
    /// - Parameters:
    ///   - palette: 環境から取得した現在のカラーパレット。
    ///   - isAlternate: 交互行（奇数行）かどうか。
    /// - Returns: 行の背景色。
    func rowBackgroundColor(_ palette: any ColorPalette, isAlternate: Bool) -> Color

    /// 通常行のテキストカラー。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: 行のテキストカラー。
    func rowTextColor(_ palette: any ColorPalette) -> Color

    /// テーブルのボーダーカラー。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: ボーダーカラー。
    func borderColor(_ palette: any ColorPalette) -> Color

    /// テーブルのボーダー幅。
    var borderWidth: CGFloat { get }

    /// セルの水平パディング。
    ///
    /// - Parameter spacing: 環境から取得した現在のスペーシングスケール。
    /// - Returns: 水平パディング（ポイント）。
    func cellHorizontalPadding(_ spacing: any SpacingScale) -> CGFloat

    /// セルの垂直パディング。
    ///
    /// - Parameter spacing: 環境から取得した現在のスペーシングスケール。
    /// - Returns: 垂直パディング（ポイント）。
    func cellVerticalPadding(_ spacing: any SpacingScale) -> CGFloat
}

// MARK: - Default Implementation

/// プロトコルのオプションメソッドにデフォルト実装を提供する。
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

/// ほのかなボーダーとヘッダーハイライトを持つデフォルトテーブルスタイル。
public struct DefaultTableStyle: TableStyle, Sendable {

    public var showBorder: Bool
    public var stripedRows: Bool

    /// デフォルトテーブルスタイルを生成する。
    ///
    /// - Parameters:
    ///   - showBorder: テーブル周囲にボーダーを表示するかどうか。デフォルトは `true`。
    ///   - stripedRows: 交互に行カラーを使用するかどうか。デフォルトは `false`。
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

/// 読みやすさのために交互の行カラーを使用するテーブルスタイル。
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

/// ボーダーなしのミニマルテーブルスタイル。
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

/// 角丸とシャドウを持つカード風テーブルスタイル。
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

    /// テーブルのレンダリングに使用するスタイル。
    ///
    /// この値を設定するには ``SwiftUICore/View/markdownTableStyle(_:)`` モディファイアを使用する。
    public var markdownTableStyle: any TableStyle {
        get { self[TableStyleKey.self] }
        set { self[TableStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層の Markdown テーブルにカスタムテーブルスタイルを設定する。
    ///
    /// ``MarkdownView`` がレンダリングするテーブルの外観をカスタマイズするには
    /// このモディファイアを使用する。
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
    /// - Parameter style: 使用するテーブルスタイル。
    /// - Returns: テーブルスタイルが適用されたビュー。
    public func markdownTableStyle(_ style: some TableStyle) -> some View {
        environment(\.markdownTableStyle, style)
    }
}
