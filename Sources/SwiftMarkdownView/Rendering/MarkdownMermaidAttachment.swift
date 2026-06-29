#if os(iOS) || os(macOS)
import Foundation
import WebKit
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
typealias MermaidPlatformView = UIView
#elseif canImport(AppKit)
import AppKit
typealias MermaidPlatformView = NSView
#endif

/// Mermaid ダイアグラムをライブかつスクロール可能な `WKWebView` でレンダリングするテキストアタッチメント。
/// コンテナ幅で固定高のボックスを占有し、ダイアグラムが大きい場合はボックス内でスクロールする
///（大きなダイアグラムでもレイアウトを崩さず、小さいダイアグラムも適切なボックスに収まる）。
final class MarkdownMermaidAttachment: NSTextAttachment {

    let source: String
    let scriptURL: URL
    let isDark: Bool
    /// ダイアグラムボックスの固定表示高さ（ポイント）。
    let displayHeight: CGFloat

    init(source: String, scriptURL: URL, isDark: Bool, displayHeight: CGFloat) {
        self.source = source
        self.scriptURL = scriptURL
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
        let scheme = attachment.scriptURL.scheme ?? "https"
        let host = attachment.scriptURL.host ?? "cdn.jsdelivr.net"
        webView.loadHTMLString(
            MermaidHTML.make(source: attachment.source, scriptURL: attachment.scriptURL, isDark: attachment.isDark),
            baseURL: URL(string: "\(scheme)://\(host)/")
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
    static func make(source: String, scriptURL: URL, isDark: Bool) -> String {
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
        <script src="\(scriptURL.absoluteString)"></script>
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
}
#endif
