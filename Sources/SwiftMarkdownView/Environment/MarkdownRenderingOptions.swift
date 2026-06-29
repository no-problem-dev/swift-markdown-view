import SwiftUI

// MARK: - MarkdownRenderingOptions

/// Markdown レンダリング動作を制御するオプション。
///
/// Mermaid ダイアグラム・画像・テーブル・Aside など
/// 特定の Markdown 機能の有効/無効を制御するために使用する。
///
/// ## Example
///
/// ```swift
/// MarkdownView(source)
///     .markdownRenderingOptions(
///         MarkdownRenderingOptions(
///             renderMermaid: false,  // Mermaid ダイアグラムを無効化
///             maxImageHeight: 300    // 画像の高さを制限
///         )
///     )
/// ```
public struct MarkdownRenderingOptions: Sendable, Equatable {

    /// Mermaid ダイアグラムをレンダリングするかどうか。
    ///
    /// `false` の場合、Mermaid コードブロックは通常のコードブロックとしてレンダリングされる。
    /// デフォルトは `true`。
    public var renderMermaid: Bool

    /// 画像をレンダリングするかどうか。
    ///
    /// `false` の場合、画像は alt テキストのプレースホルダーに置き換えられる。
    /// デフォルトは `true`。
    public var renderImages: Bool

    /// テーブルをレンダリングするかどうか。
    ///
    /// `false` の場合、テーブルはプレーンテキストとしてレンダリングされる。
    /// デフォルトは `true`。
    public var renderTables: Bool

    /// Aside ブロック（コールアウト/警告）をレンダリングするかどうか。
    ///
    /// `false` の場合、Aside は通常のブロッククォートとしてレンダリングされる。
    /// デフォルトは `true`。
    public var renderAsides: Bool

    /// 画像の最大高さ（ポイント）。
    ///
    /// 設定した場合、この値を超える高さの画像は縮小される。
    /// 制限なしにするには `nil` を指定する。デフォルトは `nil`。
    public var maxImageHeight: CGFloat?

    /// 画像の最大幅（ポイント）。
    ///
    /// 設定した場合、この値を超える幅の画像は縮小される。
    /// 制限なしにするには `nil` を指定する。デフォルトは `nil`。
    public var maxImageWidth: CGFloat?

    /// コードブロックのシンタックスハイライトを有効にするかどうか。
    ///
    /// `false` の場合、コードブロックはハイライトなしでレンダリングされる。
    /// デフォルトは `true`。
    public var enableSyntaxHighlighting: Bool

    /// ``MathRenderer`` を経由して数式をレンダリングするかどうか。
    ///
    /// `false` の場合、ディスプレイ数式は `math` コードブロックとして、
    /// インライン数式は等幅のソーステキストとしてレンダリングされる。
    /// デフォルトは `true`。
    public var renderMath: Bool

    /// レンダリングオプションを生成する。
    ///
    /// - Parameters:
    ///   - renderMermaid: Mermaid ダイアグラムをレンダリングするかどうか。デフォルトは `true`。
    ///   - renderImages: 画像をレンダリングするかどうか。デフォルトは `true`。
    ///   - renderTables: テーブルをレンダリングするかどうか。デフォルトは `true`。
    ///   - renderAsides: Aside ブロックをレンダリングするかどうか。デフォルトは `true`。
    ///   - maxImageHeight: 画像の最大高さ（ポイント）。デフォルトは `nil`。
    ///   - maxImageWidth: 画像の最大幅（ポイント）。デフォルトは `nil`。
    ///   - enableSyntaxHighlighting: シンタックスハイライトを有効にするかどうか。デフォルトは `true`。
    ///   - renderMath: 数式をレンダリングするかどうか。デフォルトは `true`。
    public init(
        renderMermaid: Bool = true,
        renderImages: Bool = true,
        renderTables: Bool = true,
        renderAsides: Bool = true,
        maxImageHeight: CGFloat? = nil,
        maxImageWidth: CGFloat? = nil,
        enableSyntaxHighlighting: Bool = true,
        renderMath: Bool = true
    ) {
        self.renderMermaid = renderMermaid
        self.renderImages = renderImages
        self.renderTables = renderTables
        self.renderAsides = renderAsides
        self.maxImageHeight = maxImageHeight
        self.maxImageWidth = maxImageWidth
        self.enableSyntaxHighlighting = enableSyntaxHighlighting
        self.renderMath = renderMath
    }

    /// すべての機能を有効にしたデフォルトのレンダリングオプション。
    public static let `default` = MarkdownRenderingOptions()

    /// コンパクト表示に最適化されたレンダリングオプション。
    ///
    /// Mermaid ダイアグラムを無効化し、画像サイズを制限する。
    public static let compact = MarkdownRenderingOptions(
        renderMermaid: false,
        maxImageHeight: 200,
        maxImageWidth: 300
    )

    /// プレーンテキスト風表示向けのレンダリングオプション。
    ///
    /// Mermaid・画像・テーブルなど複雑な要素を無効化する。
    public static let plainText = MarkdownRenderingOptions(
        renderMermaid: false,
        renderImages: false,
        renderTables: false,
        enableSyntaxHighlighting: false,
        renderMath: false
    )
}

// MARK: - Environment Key

private struct MarkdownRenderingOptionsKey: EnvironmentKey {
    static let defaultValue: MarkdownRenderingOptions = .default
}

extension EnvironmentValues {

    /// Markdown コンテンツのレンダリングオプション。
    ///
    /// この値を設定するには ``SwiftUICore/View/markdownRenderingOptions(_:)`` モディファイアを使用する。
    public var markdownRenderingOptions: MarkdownRenderingOptions {
        get { self[MarkdownRenderingOptionsKey.self] }
        set { self[MarkdownRenderingOptionsKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層の Markdown コンテンツにレンダリングオプションを設定する。
    ///
    /// どの Markdown 機能をレンダリングするか、またその外観を制御するには
    /// このモディファイアを使用する。
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// # Hello World
    ///
    /// ```mermaid
    /// graph TD
    ///     A --> B
    /// ```
    /// """)
    /// .markdownRenderingOptions(.compact)
    /// ```
    ///
    /// - Parameter options: 使用するレンダリングオプション。
    /// - Returns: レンダリングオプションが適用されたビュー。
    public func markdownRenderingOptions(_ options: MarkdownRenderingOptions) -> some View {
        environment(\.markdownRenderingOptions, options)
    }
}
