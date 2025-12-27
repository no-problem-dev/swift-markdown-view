import SwiftUI

// MARK: - Environment Key

/// Environment key for the Mermaid script provider.
private struct MermaidScriptProviderKey: EnvironmentKey {
    static let defaultValue: any MermaidScriptProvider = CDNMermaidScriptProvider()
}

extension EnvironmentValues {
    /// The Mermaid script provider used for rendering diagrams.
    ///
    /// Use this to customize how Mermaid.js is loaded:
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .mermaidScriptProvider(BundledMermaidScriptProvider())
    /// ```
    public var mermaidScriptProvider: any MermaidScriptProvider {
        get { self[MermaidScriptProviderKey.self] }
        set { self[MermaidScriptProviderKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Sets the Mermaid script provider for this view hierarchy.
    ///
    /// - Parameter provider: The script provider to use.
    /// - Returns: A view with the script provider applied.
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .mermaidScriptProvider(CDNMermaidScriptProvider(version: "10"))
    /// ```
    public func mermaidScriptProvider(_ provider: any MermaidScriptProvider) -> some View {
        environment(\.mermaidScriptProvider, provider)
    }
}
