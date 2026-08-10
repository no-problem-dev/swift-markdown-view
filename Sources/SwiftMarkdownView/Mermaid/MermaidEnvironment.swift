import SwiftUI

// MARK: - Environment Key

private struct MermaidScriptProviderKey: EnvironmentKey {
    static let defaultValue: any MermaidScriptProvider = CDNMermaidScriptProvider()
}

extension EnvironmentValues {
    /// The provider that supplies the Mermaid.js script used to draw diagrams.
    ///
    /// To change how Mermaid.js is loaded:
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
    /// Sets the Mermaid script provider for this view hierarchy.
    ///
    /// A diagram is drawn only when the provider's script can be resolved, so a provider that
    /// cannot supply one leaves Mermaid blocks undrawn rather than reaching for the CDN.
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownMermaidScriptProvider(CDNMermaidScriptProvider(version: "10"))
    /// ```
    ///
    /// - Parameter provider: The script provider to use.
    public func markdownMermaidScriptProvider(_ provider: some MermaidScriptProvider) -> some View {
        environment(\.mermaidScriptProvider, provider)
    }
}
