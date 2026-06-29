import SwiftUI
import WebKit
import DesignSystem

/// WebKit を使用して Mermaid ダイアグラムをレンダリングするビュー。
///
/// Mermaid.js を使用して Mermaid 構文からダイアグラムをレンダリングする。
/// スクリプトソースは環境でカスタマイズできる。
///
/// ```swift
/// MermaidDiagramView("""
/// graph LR
///     A --> B --> C
/// """)
/// ```
///
/// - Note: ネイティブ SwiftUI WebView サポートには iOS 26 以降が必要。
@available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
public struct MermaidDiagramView: View {

    /// レンダリングする Mermaid ダイアグラムコード。
    public let code: String

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.mermaidScriptProvider) private var scriptProvider

    @State private var page = WebPage()

    /// Mermaid ダイアグラムビューを生成する。
    ///
    /// - Parameter code: レンダリングする Mermaid ダイアグラム構文。
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
            .onChange(of: colorScheme) { _, _ in
                loadContent()
            }
    }

    private func loadContent() {
        let html = generateHTML()
        page.load(html: html, baseURL: URL(string: "about:blank")!)
    }

    // MARK: - HTML Generation

    /// 現在のカラースキームに基づく Mermaid テーマ。
    private var mermaidTheme: String {
        colorScheme == .dark ? "dark" : "default"
    }

    /// 現在のカラースキームに基づく背景色。
    private var backgroundColor: String {
        colorScheme == .dark ? "#1c1c1e" : "#ffffff"
    }

    /// 現在のカラースキームに基づくエラーテキストカラー。
    private var errorColor: String {
        // 両テーマで機能するセマンティックなエラーカラーを使用
        colorScheme == .dark ? "#ff6b6b" : "#dc3545"
    }

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
                    background: \(backgroundColor);
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
                    background: \(backgroundColor);
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
                    color: \(errorColor);
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
                    theme: '\(mermaidTheme)',
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

/// 旧 OS バージョン向けの Mermaid ダイアグラムプレースホルダービュー。
///
/// ネイティブ WebView が利用できない（iOS 26 未満）場合に、Mermaid コードをそのまま表示する。
public struct MermaidFallbackView: View {

    /// Mermaid ダイアグラムコード。
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

/// iOS 26 以降でネイティブ WebView を使用し、それ以前はコード表示にフォールバックするアダプティブビュー。
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
