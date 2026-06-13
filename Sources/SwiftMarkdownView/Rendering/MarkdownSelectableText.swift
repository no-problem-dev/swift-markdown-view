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

/// A Markdown view that renders the whole document into a **single** TextKit 2
/// text view, so text selection runs continuously across blocks (heading →
/// paragraph → list …) and the system Copy yields the selected readable text —
/// the behaviour SwiftUI's per-block `Text` rendering structurally cannot provide.
///
/// This is the new rendering backend. `MarkdownView` will delegate to it once it
/// reaches feature parity (math, images, tables); until then it is offered as an
/// explicit, opt-in selectable view.
public struct MarkdownSelectableText {
    public let content: MarkdownContent
    public var theme: MarkdownTextTheme
    var highlighter: (any MarkdownCodeHighlighting)?
    var attachmentRenderer: (any MarkdownAttachmentRendering)?

    public init(_ content: MarkdownContent, theme: MarkdownTextTheme = .default) {
        self.content = content
        self.theme = theme
    }

    public init(_ source: String, theme: MarkdownTextTheme = .default) {
        self.init(MarkdownContent(parsing: source), theme: theme)
    }

    /// Applies an async syntax highlighter to code blocks after layout.
    public func codeHighlighter(_ highlighter: (any MarkdownCodeHighlighting)?) -> MarkdownSelectableText {
        var copy = self
        copy.highlighter = highlighter
        return copy
    }

    /// Applies a synchronous renderer for image/math attachments (e.g. LaTeX).
    public func attachmentRenderer(_ renderer: (any MarkdownAttachmentRendering)?) -> MarkdownSelectableText {
        var copy = self
        copy.attachmentRenderer = renderer
        return copy
    }

    private func attributedString() -> NSAttributedString {
        MarkdownAttributedBuilder(theme: theme, attachmentRenderer: attachmentRenderer).build(content)
    }

    public final class Coordinator {
        let provider = MarkdownLayoutFragmentProvider()
        /// Last applied inputs, so layout passes that didn't change content or
        /// font size skip re-styling (which would reset the user's selection).
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

        /// Loads each image attachment's source off the main actor, then sets the
        /// image and aspect-fit bounds on the storage. Cancels any in-flight pass.
        @MainActor
        func startImageLoading(in storage: NSTextStorage, width: @escaping () -> CGFloat, invalidate: @escaping () -> Void) {
            imageTask?.cancel()
            let requests = MarkdownImageAttachments.requests(in: storage)
            guard !requests.isEmpty else { return }
            imageTask = Task { @MainActor in
                for request in requests {
                    if Task.isCancelled { return }
                    guard let image = await MarkdownImageLoader.load(request.source) else { continue }
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

        /// Highlights each code region off the main actor, then transplants the
        /// colors onto the storage. Cancels any in-flight pass first.
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
            width: { [weak textView] in
                let width = textView?.textContainer.size.width ?? 0
                return width > 0 ? width : (textView?.bounds.width ?? 0)
            },
            invalidate: { [weak textView] in
                textView?.invalidateIntrinsicContentSize()
                textView?.setNeedsLayout()
            }
        )
    }

    /// Reports the content height for the proposed width so the non-scrolling
    /// text view sizes correctly inside a SwiftUI `ScrollView`/stack.
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
                width: { [weak textView] in textView?.textContainer?.size.width ?? textView?.bounds.width ?? 0 },
                invalidate: { [weak textView] in textView?.invalidateIntrinsicContentSize() }
            )
        }
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: MarkdownTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0, width != .infinity else { return nil }
        return CGSize(width: width, height: MarkdownTextViewFactory.contentHeight(of: nsView, fittingWidth: width))
    }
}
#endif
#endif
