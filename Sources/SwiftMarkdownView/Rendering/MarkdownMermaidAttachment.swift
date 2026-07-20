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

/// Mermaid ダイアグラムをライブかつスクロール可能な `WKWebView` でレンダリングするテキストアタッチメント。
/// コンテナ幅で固定高のボックスを占有し、ダイアグラムが大きい場合はボックス内でスクロールする
///（大きなダイアグラムでもレイアウトを崩さず、小さいダイアグラムも適切なボックスに収まる）。
/// WebView に流し込む Mermaid スクリプトの形。
///
/// `MermaidScriptSource` の 3 ケース（url / inline / localFile）はここで 2 つに畳まれる。
/// localFile は読み込んでインラインにする — file URL を `<script src>` に渡しても
/// `loadHTMLString(baseURL:)` の origin では読めないため。
enum MermaidScript: Equatable {
    /// リモート URL を `<script src>` で読み込む。
    case remote(URL)
    /// JavaScript を HTML に直接埋め込む。
    case inline(String)

    /// プロバイダーが宣言したソースを、そのまま WebView に渡す形へ写す。
    ///
    /// 以前は呼び出し側に「解釈できなければ CDN」という無条件フォールバックがあり、
    /// `.inline` を選んだ利用者のアプリから**気づかないまま外部通信が飛んでいた**。
    /// 宣言されたソース以外へは絶対に落ちない。読めなければ `nil` を返し、描画しない。
    static func resolve(from source: MermaidScriptSource) -> MermaidScript? {
        switch source {
        case .url(let url):
            return .remote(url)
        case .inline(let javaScript):
            return .inline(javaScript)
        case .localFile(let url):
            // file URL を `<script src>` に渡しても `loadHTMLString(baseURL:)` の
            // origin からは読めない。中身を読み込んで埋め込む。
            guard let javaScript = try? String(contentsOf: url, encoding: .utf8) else {
                logger.warning(
                    "Mermaid スクリプトを読み込めませんでした [\(url.path, privacy: .public)]。ダイアグラムは描画されません"
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

final class MarkdownMermaidAttachment: NSTextAttachment {

    let source: String
    let script: MermaidScript
    let isDark: Bool
    /// ダイアグラムボックスの固定表示高さ（ポイント）。
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
        // リモート読み込みのときだけ、スクリプトの origin を baseURL にする。
        // インライン埋め込みには外部 origin が要らない。
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
            // </script> が JS 文字列に含まれると HTML パーサがそこでタグを閉じてしまう。
            return "<script>\(javaScript.replacingOccurrences(of: "</script", with: "<\\/script"))</script>"
        }
    }
}
#endif
