import SwiftUI
import DesignSystem

// MARK: - CodeBlockStyle Protocol

/// コードブロックの外観スタイルを定義するプロトコル。
///
/// このプロトコルを実装することで、Markdownコンテンツ内の
/// フェンスコードブロックの外観をカスタマイズできる。
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
///     .markdownCodeBlockStyle(MyCodeBlockStyle())
/// ```
public protocol CodeBlockStyle: Sendable {

    /// コードブロック上部に言語ラベルを表示するかどうか。
    ///
    /// `true` の場合、コードブロックの上に言語識別子（例: "swift"、"python"）を表示する。
    var showLanguageLabel: Bool { get }

    /// コードの横に行番号を表示するかどうか。
    ///
    /// `true` の場合、左マージンに行番号を表示する。
    var showLineNumbers: Bool { get }

    /// コードのコピーボタンを表示するかどうか。
    ///
    /// `true` の場合、クリップボードへコピーするボタンを表示する。
    var showCopyButton: Bool { get }

    /// コードブロックコンテナのコーナー半径。
    ///
    /// - Parameter radius: 環境から取得した現在の半径スケール。
    /// - Returns: コーナー半径（ポイント）。
    func cornerRadius(_ radius: any RadiusScale) -> CGFloat

    /// コードブロック内のパディング。
    ///
    /// - Parameter spacing: 環境から取得した現在のスペーシングスケール。
    /// - Returns: パディング（ポイント）。
    func padding(_ spacing: any SpacingScale) -> CGFloat

    /// コードブロックの背景色。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: 背景色。
    func backgroundColor(_ palette: any ColorPalette) -> Color

    /// コードのテキストカラー。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: テキストカラー。
    func textColor(_ palette: any ColorPalette) -> Color

    /// 言語ラベルテキストのカラー。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: ラベルカラー。
    func languageLabelColor(_ palette: any ColorPalette) -> Color

    /// 行番号のカラー。
    ///
    /// - Parameter palette: 環境から取得した現在のカラーパレット。
    /// - Returns: 行番号カラー。
    func lineNumberColor(_ palette: any ColorPalette) -> Color
}

// MARK: - Default Implementation

/// プロトコルのオプションメソッドにデフォルト実装を提供する。
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

/// ライト・ダーク両カラースキームに対応した、クリーンで読みやすいデフォルトコードブロックスタイル。
public struct DefaultCodeBlockStyle: CodeBlockStyle, Sendable {

    public var showLanguageLabel: Bool
    public var showLineNumbers: Bool
    public var showCopyButton: Bool

    /// デフォルトコードブロックスタイルを生成する。
    ///
    /// - Parameters:
    ///   - showLanguageLabel: 言語ラベルを表示するかどうか。デフォルトは `true`。
    ///   - showLineNumbers: 行番号を表示するかどうか。デフォルトは `false`。
    ///   - showCopyButton: コピーボタンを表示するかどうか。デフォルトは `false`。
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

/// 装飾なしのミニマルコードブロックスタイル。
///
/// 言語ラベル・行番号・コピーボタンをすべて非表示にし、クリーンな外観を提供する。
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

/// ターミナル風のコードブロックスタイル。
///
/// 暗い背景と明るいテキストでターミナルの外観を再現する。
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

    /// コードブロックのレンダリングに使用するスタイル。
    ///
    /// この値を設定するには ``SwiftUICore/View/codeBlockStyle(_:)`` モディファイアを使用する。
    public var codeBlockStyle: any CodeBlockStyle {
        get { self[CodeBlockStyleKey.self] }
        set { self[CodeBlockStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層にコードブロックのカスタムスタイルを設定する。
    ///
    /// ``MarkdownView`` がレンダリングするフェンスコードブロックの
    /// 外観をカスタマイズするにはこのモディファイアを使用する。
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
    /// .markdownCodeBlockStyle(TerminalCodeBlockStyle())
    /// ```
    ///
    /// - Parameter style: 使用するコードブロックスタイル。
    /// - Returns: コードブロックスタイルが適用されたビュー。
    public func markdownCodeBlockStyle(_ style: some CodeBlockStyle) -> some View {
        environment(\.codeBlockStyle, style)
    }

    @available(*, deprecated, renamed: "markdownCodeBlockStyle(_:)")
    public func codeBlockStyle(_ style: some CodeBlockStyle) -> some View {
        markdownCodeBlockStyle(style)
    }
}
