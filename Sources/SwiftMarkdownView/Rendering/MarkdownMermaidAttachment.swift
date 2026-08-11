#if os(iOS) || os(macOS)
import Foundation
import OSLog
import WebKit
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
typealias MermaidPlatformView = UIView
#elseif canImport(AppKit)
import AppKit
typealias MermaidPlatformView = NSView
#endif

/// The form the Mermaid script takes when it is handed to the web view.
///
/// The three cases of `MermaidScriptSource` (url / inline / localFile) fold into two here. A
/// local file is read and inlined, because a file URL given to `<script src>` cannot be read
/// from the origin that `loadHTMLString(baseURL:)` establishes.
enum MermaidScript: Equatable {
    /// Load a remote URL through `<script src>`.
    case remote(URL)
    /// Embed the JavaScript in the HTML directly.
    case inline(String)

    /// Maps the source a provider declared onto the form the web view takes, and nothing else.
    ///
    /// The caller used to fall back to the CDN unconditionally whenever it could not make sense
    /// of the source, so apps that had chosen `.inline` **reached out to the network without
    /// their authors ever knowing**. Nothing here falls back to anything but what was declared:
    /// if the script cannot be read this returns `nil` and the diagram is not drawn.
    static func resolve(from source: MermaidScriptSource) -> MermaidScript? {
        switch source {
        case .url(let url):
            return .remote(url)
        case .inline(let javaScript):
            return .inline(javaScript)
        case .localFile(let url):
            // A file URL given to `<script src>` cannot be read from the origin that
            // `loadHTMLString(baseURL:)` establishes. Read the contents and embed them.
            guard let javaScript = try? String(contentsOf: url, encoding: .utf8) else {
                logger.warning(
                    "Could not read the Mermaid script [\(url.path, privacy: .public)]. The diagram will not be drawn"
                )
                return nil
            }
            return .inline(javaScript)
        }
    }

    private static let logger = Logger(
        subsystem: "com.no-problem.swift-markdown-view",
        category: "Mermaid"
    )
}

/// A text attachment that renders a Mermaid diagram in a live, scrollable web view.
///
/// The `WKWebView` takes a box of the container's width at a fixed height, and a diagram too
/// large for that box scrolls inside it — a big diagram never disturbs the surrounding layout,
/// and a small one still sits in a box of reasonable size.
final class MarkdownMermaidAttachment: NSTextAttachment {

    let source: String
    let script: MermaidScript
    let isDark: Bool
    /// The fixed display height of the diagram box, in points.
    let displayHeight: CGFloat

    init(source: String, script: MermaidScript, isDark: Bool, displayHeight: CGFloat) {
        self.source = source
        self.script = script
        self.isDark = isDark
        self.displayHeight = displayHeight
        super.init(data: nil, ofType: nil)
        bounds = CGRect(x: 0, y: 0, width: 300, height: displayHeight)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewProvider(
        for parentView: MermaidPlatformView?,
        location: any NSTextLocation,
        textContainer: NSTextContainer?
    ) -> NSTextAttachmentViewProvider? {
        MermaidAttachmentViewProvider(
            textAttachment: self,
            parentView: parentView,
            textLayoutManager: textContainer?.textLayoutManager,
            location: location
        )
    }
}

final class MermaidAttachmentViewProvider: NSTextAttachmentViewProvider {

    override func loadView() {
        guard let attachment = textAttachment as? MarkdownMermaidAttachment else {
            view = MermaidPlatformView()
            return
        }
        let width = max(80, textLayoutManager?.textContainer?.size.width ?? 300)
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: width, height: attachment.displayHeight), configuration: configuration)
        #if canImport(UIKit)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        #elseif canImport(AppKit)
        webView.autoresizingMask = [.width, .height]
        #endif
        // Use the script's origin as the baseURL only when it is loaded remotely.
        // An inline embed needs no external origin.
        let baseURL: URL?
        if case .remote(let url) = attachment.script,
           let scheme = url.scheme, let host = url.host {
            baseURL = URL(string: "\(scheme)://\(host)/")
        } else {
            baseURL = nil
        }
        webView.loadHTMLString(
            MermaidHTML.make(source: attachment.source, script: attachment.script, isDark: attachment.isDark),
            baseURL: baseURL
        )
        view = webView
    }

    override func attachmentBounds(
        for attributes: [NSAttributedString.Key: Any],
        location: any NSTextLocation,
        textContainer: NSTextContainer?,
        proposedLineFragment: CGRect,
        position: CGPoint
    ) -> CGRect {
        let height = (textAttachment as? MarkdownMermaidAttachment)?.displayHeight ?? 260
        let width = max(80, textContainer?.size.width ?? proposedLineFragment.width)
        return CGRect(x: 0, y: 0, width: width, height: height)
    }
}

enum MermaidHTML {
    static func make(source: String, script: MermaidScript, isDark: Bool) -> String {
        let theme = isDark ? "dark" : "default"
        let background = isDark ? "#1c1c1e" : "#ffffff"
        let diagram = source.trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; background: \(background); }
        body { padding: 12px; overflow: auto; font-family: -apple-system, sans-serif; }
        .mermaid { display: inline-block; }
        .mermaid svg { max-width: none !important; display: block; }
        </style>
        \(scriptTag(for: script))
        </head>
        <body>
        <div class="mermaid" id="d">\(diagram)</div>
        <script>
        try {
            mermaid.initialize({ startOnLoad: false, theme: '\(theme)', securityLevel: 'loose', flowchart: { useMaxWidth: false } });
            mermaid.run();
        } catch (e) {}
        </script>
        </body>
        </html>
        """
    }

    private static func scriptTag(for script: MermaidScript) -> String {
        switch script {
        case .remote(let url):
            return "<script src=\"\(url.absoluteString)\"></script>"
        case .inline(let javaScript):
            // A `</script>` inside the JavaScript would close the tag early for the HTML parser.
            return "<script>\(javaScript.replacingOccurrences(of: "</script", with: "<\\/script"))</script>"
        }
    }
}
#endif
