import SwiftUI

// MARK: - MarkdownRenderingOptions

/// Markdown レンダリング動作を制御するオプション。
///
/// ## Example
///
/// ```swift
/// MathText("答え: $$-6$$")
///     .markdownRenderingOptions(MarkdownRenderingOptions(renderMath: false))
/// ```
public struct MarkdownRenderingOptions: Sendable, Equatable {

    /// ``MathRenderer`` を経由して数式をレンダリングするかどうか。
    ///
    /// `false` の場合、数式はソーステキストのまま表示される。
    /// デフォルトは `true`。
    public var renderMath: Bool

    /// レンダリングオプションを生成する。
    ///
    /// - Parameter renderMath: 数式をレンダリングするかどうか。デフォルトは `true`。
    public init(renderMath: Bool = true) {
        self.renderMath = renderMath
    }

    /// すべての機能を有効にしたデフォルトのレンダリングオプション。
    public static let `default` = MarkdownRenderingOptions()
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
    /// - Parameter options: 使用するレンダリングオプション。
    /// - Returns: レンダリングオプションが適用されたビュー。
    public func markdownRenderingOptions(_ options: MarkdownRenderingOptions) -> some View {
        environment(\.markdownRenderingOptions, options)
    }
}
