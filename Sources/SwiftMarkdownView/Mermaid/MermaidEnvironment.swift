import SwiftUI

// MARK: - Environment Key

/// Mermaid スクリプトプロバイダーの環境キー。
private struct MermaidScriptProviderKey: EnvironmentKey {
    static let defaultValue: any MermaidScriptProvider = CDNMermaidScriptProvider()
}

extension EnvironmentValues {
    /// ダイアグラムのレンダリングに使用する Mermaid スクリプトプロバイダー。
    ///
    /// Mermaid.js の読み込み方法をカスタマイズするには以下を使用する:
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownMermaidScriptProvider(.cdn)
    /// ```
    public var mermaidScriptProvider: any MermaidScriptProvider {
        get { self[MermaidScriptProviderKey.self] }
        set { self[MermaidScriptProviderKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// このビュー階層に Mermaid スクリプトプロバイダーを設定する。
    ///
    /// - Parameter provider: 使用するスクリプトプロバイダー。
    /// - Returns: スクリプトプロバイダーが適用されたビュー。
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownMermaidScriptProvider(CDNMermaidScriptProvider(version: "10"))
    /// ```
    public func markdownMermaidScriptProvider(_ provider: some MermaidScriptProvider) -> some View {
        environment(\.mermaidScriptProvider, provider)
    }
}
