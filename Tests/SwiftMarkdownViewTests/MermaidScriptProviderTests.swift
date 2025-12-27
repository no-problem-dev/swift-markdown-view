import Testing
import Foundation
@testable import SwiftMarkdownView

/// Tests for MermaidScriptProvider protocol and implementations
struct MermaidScriptProviderTests {

    // MARK: - MermaidScriptSource Tests

    @Test("MermaidScriptSource.url creates correct URL source")
    func urlSourceCreatesCorrectly() {
        let url = URL(string: "https://example.com/mermaid.js")!
        let source = MermaidScriptSource.url(url)

        guard case .url(let resultURL) = source else {
            Issue.record("Expected URL source")
            return
        }

        #expect(resultURL == url)
    }

    @Test("MermaidScriptSource.inline creates correct inline source")
    func inlineSourceCreatesCorrectly() {
        let script = "console.log('test');"
        let source = MermaidScriptSource.inline(script)

        guard case .inline(let resultScript) = source else {
            Issue.record("Expected inline source")
            return
        }

        #expect(resultScript == script)
    }

    @Test("MermaidScriptSource.localFile creates correct local file source")
    func localFileSourceCreatesCorrectly() {
        let url = URL(fileURLWithPath: "/path/to/mermaid.js")
        let source = MermaidScriptSource.localFile(url)

        guard case .localFile(let resultURL) = source else {
            Issue.record("Expected localFile source")
            return
        }

        #expect(resultURL == url)
    }

    @Test("MermaidScriptSource is Equatable")
    func sourceIsEquatable() {
        let url = URL(string: "https://example.com/mermaid.js")!

        let source1 = MermaidScriptSource.url(url)
        let source2 = MermaidScriptSource.url(url)
        let source3 = MermaidScriptSource.inline("test")

        #expect(source1 == source2)
        #expect(source1 != source3)
    }

    // MARK: - CDNMermaidScriptProvider Tests

    @Test("CDNMermaidScriptProvider uses default version 11")
    func cdnProviderUsesDefaultVersion() {
        let provider = CDNMermaidScriptProvider()

        #expect(provider.version == "11")
    }

    @Test("CDNMermaidScriptProvider uses specified version")
    func cdnProviderUsesSpecifiedVersion() {
        let provider = CDNMermaidScriptProvider(version: "10.5.0")

        #expect(provider.version == "10.5.0")
    }

    @Test("CDNMermaidScriptProvider generates correct jsdelivr URL")
    func cdnProviderGeneratesCorrectURL() {
        let provider = CDNMermaidScriptProvider(version: "11")

        guard case .url(let url) = provider.scriptSource else {
            Issue.record("Expected URL source")
            return
        }

        #expect(url.absoluteString == "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js")
    }

    @Test("CDNMermaidScriptProvider generates URL with specific version")
    func cdnProviderGeneratesURLWithSpecificVersion() {
        let provider = CDNMermaidScriptProvider(version: "10.6.1")

        guard case .url(let url) = provider.scriptSource else {
            Issue.record("Expected URL source")
            return
        }

        #expect(url.absoluteString == "https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js")
    }

    @Test("CDNMermaidScriptProvider is Sendable")
    func cdnProviderIsSendable() {
        let provider = CDNMermaidScriptProvider()

        // This test verifies compile-time Sendable conformance
        Task {
            _ = provider.scriptSource
        }
    }

    // MARK: - BundledMermaidScriptProvider Tests

    @Test("BundledMermaidScriptProvider uses default bundle and filename")
    func bundledProviderUsesDefaults() {
        let provider = BundledMermaidScriptProvider()

        #expect(provider.bundle == Bundle.main)
        #expect(provider.filename == "mermaid.min")
    }

    @Test("BundledMermaidScriptProvider uses specified bundle and filename")
    func bundledProviderUsesSpecifiedValues() {
        let testBundle = Bundle(for: BundleToken.self)
        let provider = BundledMermaidScriptProvider(bundle: testBundle, filename: "custom-mermaid")

        #expect(provider.bundle == testBundle)
        #expect(provider.filename == "custom-mermaid")
    }

    @Test("BundledMermaidScriptProvider falls back to CDN when resource not found")
    func bundledProviderFallsBackToCDN() {
        // Use a bundle that definitely won't have mermaid.min.js
        let provider = BundledMermaidScriptProvider(bundle: .main, filename: "nonexistent-file")

        guard case .url(let url) = provider.scriptSource else {
            Issue.record("Expected fallback to CDN URL")
            return
        }

        // Should fall back to CDN URL
        #expect(url.absoluteString.contains("cdn.jsdelivr.net"))
    }

    @Test("BundledMermaidScriptProvider is Sendable")
    func bundledProviderIsSendable() {
        let provider = BundledMermaidScriptProvider()

        Task {
            _ = provider.scriptSource
        }
    }

    // MARK: - Default Provider Tests

    @Test("defaultMermaidScriptProvider is CDN-based")
    func defaultProviderIsCDNBased() {
        let source = defaultMermaidScriptProvider.scriptSource

        guard case .url(let url) = source else {
            Issue.record("Expected URL source from default provider")
            return
        }

        #expect(url.absoluteString.contains("cdn.jsdelivr.net"))
    }
}

// MARK: - Test Helpers

/// Token class to get the test bundle
private final class BundleToken {}
