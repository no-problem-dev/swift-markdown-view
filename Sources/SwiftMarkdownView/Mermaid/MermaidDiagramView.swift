import SwiftUI
import WebKit
import DesignSystem

/// A view that renders Mermaid diagrams using WebKit.
///
/// This view uses Mermaid.js to render diagrams from Mermaid syntax.
/// The script source can be customized via the environment.
///
/// ```swift
/// MermaidDiagramView("""
/// graph LR
///     A --> B --> C
/// """)
/// ```
///
/// - Note: Requires iOS 26+ for native SwiftUI WebView support.
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
public struct MermaidDiagramView: View {

    /// The Mermaid diagram code to render.
    public let code: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.mermaidScriptProvider) private var scriptProvider

    @State private var page = WebPage()

    /// Creates a Mermaid diagram view.
    ///
    /// - Parameter code: The Mermaid diagram syntax to render.
    public init(_ code: String) {
        self.code = code
    }

    public var body: some View {
        WebView(page)
            .frame(minHeight: 200)
            .onAppear {
                loadContent()
            }
            .onChange(of: code) { _, _ in
                loadContent()
            }
    }

    private func loadContent() {
        let html = generateHTML()
        page.load(html: html, baseURL: URL(string: "about:blank")!)
    }

    // MARK: - HTML Generation

    private func generateHTML() -> String {
        let scriptTag = generateScriptTag()
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=0.1, maximum-scale=5.0, user-scalable=yes">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                html {
                    width: 100%;
                    height: 100%;
                    overflow: scroll;
                    background: transparent;
                    scrollbar-width: none;
                    -ms-overflow-style: none;
                }
                html::-webkit-scrollbar {
                    display: none;
                }
                body {
                    display: inline-block;
                    min-width: 100%;
                    min-height: 100%;
                    padding: 16px;
                    background: transparent;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                }
                .mermaid-container {
                    display: inline-block;
                }
                .mermaid {
                    display: inline-block;
                }
                .mermaid svg {
                    max-width: none !important;
                    display: block;
                }
                .error {
                    color: #dc3545;
                    padding: 16px;
                    text-align: center;
                }
            </style>
            \(scriptTag)
        </head>
        <body>
            <div class="mermaid-container">
                <div class="mermaid" id="diagram">
                    \(trimmedCode)
                </div>
            </div>
            <script>
                mermaid.initialize({
                    startOnLoad: false,
                    theme: 'default',
                    securityLevel: 'loose',
                    flowchart: { useMaxWidth: false, htmlLabels: true },
                    sequence: { useMaxWidth: false },
                    gantt: { useMaxWidth: false },
                    journey: { useMaxWidth: false },
                    timeline: { useMaxWidth: false },
                    mindmap: { useMaxWidth: false }
                });

                mermaid.run().then(function() {
                    var scrollX = (document.documentElement.scrollWidth - window.innerWidth) / 2;
                    var scrollY = (document.documentElement.scrollHeight - window.innerHeight) / 2;
                    window.scrollTo(Math.max(0, scrollX), Math.max(0, scrollY));
                });
            </script>
        </body>
        </html>
        """
    }

    private func generateScriptTag() -> String {
        switch scriptProvider.scriptSource {
        case .url(let url):
            return "<script src=\"\(url.absoluteString)\"></script>"
        case .inline(let script):
            return "<script>\(script)</script>"
        case .localFile(let url):
            // For local files, we'd need to load the content
            // For now, fall back to CDN
            return "<script src=\"\(url.absoluteString)\"></script>"
        }
    }
}

// MARK: - Fallback View for older OS versions

/// A placeholder view for Mermaid diagrams on older OS versions.
///
/// This view displays the raw Mermaid code when the native WebView
/// is not available (iOS < 26).
public struct MermaidFallbackView: View {

    /// The Mermaid diagram code.
    public let code: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    public init(_ code: String) {
        self.code = code
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing.sm) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(colorPalette.primary)
                Text("Mermaid Diagram")
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.trimmingCharacters(in: .whitespacesAndNewlines))
                    .typography(.bodySmall)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(colorPalette.onSurface)
            }
            .padding(spacing.md)
            .background(colorPalette.surfaceVariant)
            .clipShape(RoundedRectangle(cornerRadius: radius.md))
        }
    }
}

// MARK: - Adaptive Mermaid View

/// An adaptive view that uses native WebView on iOS 26+ or falls back to code display.
public struct AdaptiveMermaidView: View {

    public let code: String

    public init(_ code: String) {
        self.code = code
    }

    public var body: some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
            MermaidDiagramView(code)
        } else {
            MermaidFallbackView(code)
        }
    }
}
