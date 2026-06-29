import SwiftUI
import DesignSystem

// MARK: - LinkStyle Protocol

/// リンクの外観スタイルを定義するプロトコル。
///
/// このプロトコルを実装することで、Markdownコンテンツ内の
/// リンクの外観をカスタマイズできる。
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

    /// リンクに下線を表示するかどうか。
    var showUnderline: Bool { get }

    /// リンクの下線スタイル。
    ///
    /// `showUnderline` が `true` の場合のみ使用される。
    var underlineStyle: Text.LineStyle { get }

    /// リンクのテキストカラー。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: リンクカラー。
    func color(_ palette: any ColorPalette) -> Color

    /// 訪問済みリンクのテキストカラー（追跡が有効な場合）。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: 訪問済みリンクカラー。
    func visitedColor(_ palette: any ColorPalette) -> Color

    /// ホバー時のリンクテキストカラー。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: ホバーカラー。
    func hoverColor(_ palette: any ColorPalette) -> Color

    /// リンクのフォントウェイト。
    var fontWeight: Font.Weight? { get }
}

// MARK: - Default Implementation

/// プロトコルのオプションメソッドにデフォルト実装を提供する。
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

/// プライマリカラーと下線を使用するデフォルトリンクスタイル。
public struct DefaultLinkStyle: LinkStyle, Sendable {

    public var showUnderline: Bool

    /// デフォルトリンクスタイルを生成する。
    ///
    /// - Parameter showUnderline: 下線を表示するかどうか。デフォルトは `true`。
    public init(showUnderline: Bool = true) {
        self.showUnderline = showUnderline
    }

    public func color(_ palette: any ColorPalette) -> Color {
        palette.primary
    }
}

// MARK: - SubtleLinkStyle

/// 下線なしのサブトルなリンクスタイル。
///
/// リンクをカラーのみで区別し、クリーンな外観を提供する。
public struct SubtleLinkStyle: LinkStyle, Sendable {

    public var showUnderline: Bool { false }

    public init() {}

    public func color(_ palette: any ColorPalette) -> Color {
        palette.primary
    }
}

// MARK: - BoldLinkStyle

/// 強調を加えたボールドリンクスタイル。
///
/// セカンダリカラーでボールド表示する。
public struct BoldLinkStyle: LinkStyle, Sendable {

    public var showUnderline: Bool { false }

    public var fontWeight: Font.Weight? { .semibold }

    public init() {}

    public func color(_ palette: any ColorPalette) -> Color {
        palette.secondary
    }
}

// MARK: - ClassicLinkStyle

/// クラシックなウェブスタイルのリンク外観。
///
/// 従来のウェブリンクに似た青色と下線を使用する。
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

/// テキストに溶け込むモノクロームリンクスタイル。
///
/// 下線付きだが、通常テキストと同じカラーを使用する。
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

    /// リンクのレンダリングに使用するスタイル。
    ///
    /// この値を設定するには ``SwiftUICore/View/markdownLinkStyle(_:)`` モディファイアを使用する。
    public var markdownLinkStyle: any LinkStyle {
        get { self[LinkStyleKey.self] }
        set { self[LinkStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層の Markdown リンクにカスタムリンクスタイルを設定する。
    ///
    /// ``MarkdownView`` がレンダリングするリンクの外観をカスタマイズするには
    /// このモディファイアを使用する。
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// [SwiftUI](https://developer.apple.com/xcode/swiftui/) を参照。
    /// """)
    /// .markdownLinkStyle(ClassicLinkStyle())
    /// ```
    ///
    /// - Parameter style: 使用するリンクスタイル。
    /// - Returns: リンクスタイルが適用されたビュー。
    public func markdownLinkStyle(_ style: some LinkStyle) -> some View {
        environment(\.markdownLinkStyle, style)
    }
}
