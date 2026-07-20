#if os(iOS) || os(macOS)
import SwiftUI
import MarkdownModel
import MarkdownAttributedKit
import MarkdownTextKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// ドキュメント全体を**単一の** TextKit 2 テキストビューにレンダリングする Markdown ビュー。
///
/// テキスト選択がブロック間（見出し → 段落 → リスト…）を連続して行え、
/// システムのコピーで選択した可読テキストを取得できる —
/// SwiftUI のブロック単位 `Text` レンダリングでは構造上実現できない挙動。
///
/// `MarkdownView` の実レンダリングバックエンド。`MarkdownView.body` はこの型に全面委譲する。
/// 直接使うのは、テーマを注入したい場合など `MarkdownView` の環境値経由では届かないときだけでよい。
public struct MarkdownSelectableText {
    public let content: MarkdownContent
    public var theme: MarkdownTextTheme
    var highlighter: (any MarkdownCodeHighlighting)?
    var attachmentRenderer: (any MarkdownAttachmentRendering)?
    var mermaidConfig: (scriptURL: URL, isDark: Bool)?

    @Environment(\.markdownImagePolicy) private var imagePolicy

    public init(_ content: MarkdownContent, theme: MarkdownTextTheme = .default) {
        self.content = content
        self.theme = theme
    }

    public init(_ source: String, theme: MarkdownTextTheme = .default) {
        self.init(MarkdownContent(parsing: source), theme: theme)
    }

    /// レイアウト後にコードブロックへ非同期シンタックスハイライターを適用する。
    ///
    /// `MarkdownCodeHighlighting` は TextKit 層の内部プロトコルなのでパッケージ内に閉じる。
    /// 利用者は SwiftUI 層の ``SyntaxHighlighter`` を ``SwiftUICore/View/markdownSyntaxHighlighter(_:)``
    /// で注入する（``SyntaxHighlighterAdapter`` が橋渡しする）。
    package func codeHighlighter(_ highlighter: (any MarkdownCodeHighlighting)?) -> MarkdownSelectableText {
        var copy = self
        copy.highlighter = highlighter
        return copy
    }

    /// 画像/数式アタッチメント（例: LaTeX）に同期レンダラーを適用する。
    public func attachmentRenderer(_ renderer: (any MarkdownAttachmentRendering)?) -> MarkdownSelectableText {
        var copy = self
        copy.attachmentRenderer = renderer
        return copy
    }

    /// `scriptURL` から読み込む WebView で Mermaid ダイアグラムをレンダリングする。
    func mermaid(scriptURL: URL, isDark: Bool) -> MarkdownSelectableText {
        var copy = self
        copy.mermaidConfig = (scriptURL, isDark)
        return copy
    }

    private func attributedString() -> NSAttributedString {
        MarkdownAttributedBuilder(theme: theme, attachmentRenderer: attachmentRenderer).build(content)
    }

    public final class Coordinator {
        let provider = MarkdownLayoutFragmentProvider()
        /// 最後に適用した入力。コンテンツやフォントサイズが変わらないレイアウトパスは
        /// 再スタイリングをスキップし、ユーザーの選択をリセットしない。
        var appliedContent: MarkdownContent?
        var appliedFontSize: CGFloat?
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        weak var textView: MarkdownTextView?
        #endif

        func isUnchanged(content: MarkdownContent, fontSize: CGFloat) -> Bool {
            appliedContent == content && appliedFontSize == fontSize
        }

        func markApplied(content: MarkdownContent, fontSize: CGFloat) {
            appliedContent = content
            appliedFontSize = fontSize
        }

        var highlightTask: Task<Void, Never>?
        var imageTask: Task<Void, Never>?

        /// 各 Mermaid プレースホルダーアタッチメントをライブかつスクロール可能な
        /// WebView アタッチメントに交換する。冪等 — インストール済みのアタッチメントはスキップする。
        @MainActor
        func installMermaid(in storage: NSTextStorage, scriptURL: URL, isDark: Bool, displayHeight: CGFloat) {
            let full = NSRange(location: 0, length: storage.length)
            var swaps: [(NSRange, String)] = []
            storage.enumerateAttribute(.markdownAttachment, in: full) { value, range, _ in
                guard let markdownAttachment = value as? MarkdownAttachment,
                      case .mermaid(let source) = markdownAttachment.kind,
                      !(storage.attribute(.attachment, at: range.location, effectiveRange: nil) is MarkdownMermaidAttachment) else { return }
                swaps.append((range, source))
            }
            guard !swaps.isEmpty else { return }
            storage.beginEditing()
            for (range, source) in swaps {
                let attachment = MarkdownMermaidAttachment(source: source, scriptURL: scriptURL, isDark: isDark, displayHeight: displayHeight)
                storage.addAttribute(.attachment, value: attachment, range: range)
            }
            storage.endEditing()
        }

        /// 各画像アタッチメントのソースをメインアクター外でロードし、
        /// ストレージに画像とアスペクトフィットのバウンドを設定する。進行中のパスはキャンセルする。
        @MainActor
        func startImageLoading(
            in storage: NSTextStorage,
            policy: MarkdownImagePolicy,
            width: @escaping () -> CGFloat,
            invalidate: @escaping () -> Void
        ) {
            imageTask?.cancel()
            let requests = MarkdownImageAttachments.requests(in: storage)
            guard !requests.isEmpty else { return }
            imageTask = Task { @MainActor in
                for request in requests {
                    if Task.isCancelled { return }
                    let image: PlatformImage
                    switch await MarkdownImageLoader.load(request.source, policy: policy) {
                    case .success(let loaded):
                        image = loaded
                    case .failure(let failure):
                        // 読み込めなかった画像は描画されない。原因が分からないと
                        // 「なぜ出ないのか」を追えないので、握りつぶさず理由を出す。
                        MarkdownImageLoader.report(failure, source: request.source)
                        continue
                    }
                    if Task.isCancelled { return }
                    storage.beginEditing()
                    request.attachment.image = image
                    request.attachment.bounds = MarkdownImageAttachments.bounds(for: image, maxWidth: width())
                    storage.edited(.editedAttributes, range: request.range, changeInLength: 0)
                    storage.endEditing()
                    invalidate()
                }
            }
        }

        /// 各コード領域をメインアクター外でハイライトし、カラーをストレージに適用する。
        /// 最初に進行中のパスをキャンセルする。
        @MainActor
        func startHighlighting(_ highlighter: (any MarkdownCodeHighlighting)?, in storage: NSTextStorage) {
            highlightTask?.cancel()
            guard let highlighter else { return }
            let regions = MarkdownSyntaxHighlighting.regions(in: storage)
            guard !regions.isEmpty else { return }
            highlightTask = Task { @MainActor in
                for region in regions {
                    if Task.isCancelled { return }
                    guard let highlighted = await highlighter.highlightedCode(region.code, language: region.language) else { continue }
                    if Task.isCancelled { return }
                    storage.beginEditing()
                    MarkdownSyntaxHighlighting.applyForegroundColors(from: highlighted, to: storage, at: region.range)
                    storage.endEditing()
                }
            }
        }
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }
}

#if canImport(UIKit)
extension MarkdownSelectableText: UIViewRepresentable {
    public func makeUIView(context: Context) -> UITextView {
        let textView = MarkdownTextViewFactory.make()
        let palette = MarkdownDecorationPalette(theme: theme)
        context.coordinator.provider.palette = palette
        MarkdownTextViewFactory.setFragmentProvider(context.coordinator.provider, on: textView)
        MarkdownTextViewFactory.setDecorationPalette(palette, on: textView)
        return textView
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        guard !context.coordinator.isUnchanged(content: content, fontSize: theme.baseFontSize) else { return }
        let palette = MarkdownDecorationPalette(theme: theme)
        context.coordinator.provider.palette = palette
        MarkdownTextViewFactory.setDecorationPalette(palette, on: textView)
        MarkdownTextViewFactory.apply(attributedString(), to: textView)
        context.coordinator.markApplied(content: content, fontSize: theme.baseFontSize)
        context.coordinator.startHighlighting(highlighter, in: textView.textStorage)
        context.coordinator.startImageLoading(
            in: textView.textStorage,
            policy: imagePolicy,
            width: { [weak textView] in
                let width = textView?.textContainer.size.width ?? 0
                return width > 0 ? width : (textView?.bounds.width ?? 0)
            },
            invalidate: { [weak textView] in
                textView?.invalidateIntrinsicContentSize()
                textView?.setNeedsLayout()
            }
        )
        if let mermaid = mermaidConfig {
            context.coordinator.installMermaid(in: textView.textStorage, scriptURL: mermaid.scriptURL, isDark: mermaid.isDark, displayHeight: 280)
        }
    }

    /// SwiftUI `ScrollView` / スタック内でスクロールなしテキストビューが正しくサイズ調整できるよう、
    /// 提案幅に対するコンテンツ高さを返す。
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0, width != .infinity else { return nil }
        let fitting = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitting.height))
    }
}
#elseif canImport(AppKit)
extension MarkdownSelectableText: NSViewRepresentable {
    public func makeNSView(context: Context) -> MarkdownTextView {
        let textView = MarkdownTextViewFactory.make()
        context.coordinator.textView = textView
        context.coordinator.provider.palette = MarkdownDecorationPalette(theme: theme)
        MarkdownTextViewFactory.setFragmentProvider(context.coordinator.provider, on: textView)
        return textView
    }

    public func updateNSView(_ textView: MarkdownTextView, context: Context) {
        guard !context.coordinator.isUnchanged(content: content, fontSize: theme.baseFontSize) else { return }
        context.coordinator.provider.palette = MarkdownDecorationPalette(theme: theme)
        MarkdownTextViewFactory.apply(attributedString(), to: textView)
        context.coordinator.markApplied(content: content, fontSize: theme.baseFontSize)
        if let storage = textView.textContentStorage?.textStorage {
            context.coordinator.startHighlighting(highlighter, in: storage)
            context.coordinator.startImageLoading(
                in: storage,
                policy: imagePolicy,
                width: { [weak textView] in textView?.textContainer?.size.width ?? textView?.bounds.width ?? 0 },
                invalidate: { [weak textView] in textView?.invalidateIntrinsicContentSize() }
            )
            if let mermaid = mermaidConfig {
                context.coordinator.installMermaid(in: storage, scriptURL: mermaid.scriptURL, isDark: mermaid.isDark, displayHeight: 280)
            }
        }
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: MarkdownTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0, width != .infinity else { return nil }
        return CGSize(width: width, height: MarkdownTextViewFactory.contentHeight(of: nsView, fittingWidth: width))
    }
}
#endif
#endif
