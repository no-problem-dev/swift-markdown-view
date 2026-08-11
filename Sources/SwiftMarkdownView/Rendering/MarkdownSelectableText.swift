#if os(iOS) || os(macOS)
import SwiftUI
import OSLog
import MarkdownModel
import MarkdownAttributedKit
import MarkdownTextKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A Markdown view that renders the whole document into a **single** TextKit 2 text view.
///
/// Selection runs continuously from one block to the next — heading into paragraph into list —
/// and the system copy command yields the readable text that was selected. Rendering block by
/// block into SwiftUI `Text` views cannot do this, as a matter of structure.
///
/// This is the rendering backend behind ``MarkdownView``, which delegates its whole body here.
/// Reach for it directly only when something has to be passed in that the environment values of
/// ``MarkdownView`` do not carry, such as an explicit theme.
public struct MarkdownSelectableText {
    public let content: MarkdownContent
    public var theme: MarkdownTextTheme
    var highlighter: (any MarkdownCodeHighlighting)?
    var attachmentRenderer: (any MarkdownAttachmentRendering)?
    var mermaidConfig: (script: MermaidScript, isDark: Bool)?

    @Environment(\.markdownImagePolicy) private var imagePolicy

    public init(_ content: MarkdownContent, theme: MarkdownTextTheme = .default) {
        self.content = content
        self.theme = theme
    }

    public init(_ source: String, theme: MarkdownTextTheme = .default) {
        self.init(MarkdownContent(parsing: source), theme: theme)
    }

    /// Applies an asynchronous syntax highlighter to code blocks once layout has happened.
    ///
    /// `MarkdownCodeHighlighting` is an internal protocol of the TextKit layer, so this stays
    /// inside the package. Clients inject the SwiftUI-level ``SyntaxHighlighter`` with
    /// ``SwiftUICore/View/markdownSyntaxHighlighter(_:)``, and ``SyntaxHighlighterAdapter``
    /// bridges the two.
    package func codeHighlighter(_ highlighter: (any MarkdownCodeHighlighting)?) -> MarkdownSelectableText {
        var copy = self
        copy.highlighter = highlighter
        return copy
    }

    /// Applies a synchronous renderer to image and math attachments, LaTeX among them.
    public func attachmentRenderer(_ renderer: (any MarkdownAttachmentRendering)?) -> MarkdownSelectableText {
        var copy = self
        copy.attachmentRenderer = renderer
        return copy
    }

    /// Renders Mermaid diagrams in a web view.
    func mermaid(script: MermaidScript, isDark: Bool) -> MarkdownSelectableText {
        var copy = self
        copy.mermaidConfig = (script, isDark)
        return copy
    }

    private func attributedString() -> NSAttributedString {
        MarkdownAttributedBuilder(theme: theme, attachmentRenderer: attachmentRenderer).build(content)
    }

    /// Everything the rendered output is built from.
    ///
    /// A layout pass that changes none of it skips restyling, which keeps it from throwing away
    /// the user's selection. A pass that changes any of it must restyle — the theme decides every
    /// color, font, and spacing in the attributed string as well as the decoration palette, so
    /// leaving it out of the comparison drops a theme change on the floor with no error anywhere:
    /// the caller swaps the theme and the text keeps its old colors.
    ///
    /// Light and dark are deliberately *not* in here. A dynamic color is one value in both
    /// appearances, so a theme built from system colors compares equal across a switch and this
    /// skips the pass — which is correct, because every color reaches the draw call still dynamic
    /// and resolves there. The one thing that cannot stay dynamic is a Mermaid diagram, which is
    /// drawn into a web view for one appearance, so its appearance is a key of its own.
    struct AppliedInputs: Equatable {
        var content: MarkdownContent
        var theme: MarkdownTextTheme
        /// Mermaid diagrams bake a background color for the appearance they were drawn in, and
        /// the appearance does not reach the theme.
        var mermaidIsDark: Bool?
    }

    public final class Coordinator {
        let provider = MarkdownLayoutFragmentProvider()
        /// The input last applied.
        var applied: AppliedInputs?
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        weak var textView: MarkdownTextView?
        #endif

        func isUnchanged(_ inputs: AppliedInputs) -> Bool {
            applied == inputs
        }

        func markApplied(_ inputs: AppliedInputs) {
            applied = inputs
        }

        var highlightTask: Task<Void, Never>?
        var imageTask: Task<Void, Never>?

        fileprivate static let logger = Logger(
            subsystem: "com.no-problem.swift-markdown-view",
            category: "SyntaxHighlight"
        )

        /// Swaps each Mermaid placeholder attachment for a live, scrollable web view attachment.
        ///
        /// Idempotent: attachments already installed are skipped.
        @MainActor
        func installMermaid(in storage: NSTextStorage, script: MermaidScript, isDark: Bool, displayHeight: CGFloat) {
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
                let attachment = MarkdownMermaidAttachment(source: source, script: script, isDark: isDark, displayHeight: displayHeight)
                storage.addAttribute(.attachment, value: attachment, range: range)
            }
            storage.endEditing()
        }

        /// Loads the source of every image attachment off the main actor.
        ///
        /// The image and its aspect-fit bounds are written to the storage as each one arrives.
        /// Any pass still in flight is cancelled first.
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
                        // An image that failed to load is simply not drawn. Report the reason
                        // rather than swallowing it — otherwise there is no way to find out why.
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

        /// Highlights every code region off the main actor and applies the colors to the storage.
        ///
        /// Any pass still in flight is cancelled first.
        @MainActor
        func startHighlighting(_ highlighter: (any MarkdownCodeHighlighting)?, in storage: NSTextStorage) {
            highlightTask?.cancel()
            guard let highlighter else { return }
            let regions = MarkdownSyntaxHighlighting.regions(in: storage)
            guard !regions.isEmpty else { return }
            highlightTask = Task { @MainActor in
                for region in regions {
                    if Task.isCancelled { return }
                    let highlighted: AttributedString?
                    do {
                        highlighted = try await highlighter.highlightedCode(region.code, language: region.language)
                    } catch {
                        // Highlighting is decoration, so a failure leaves the body drawn plain
                        // and rendering carries on. It is not dropped silently, though: swallow
                        // it and a bug in a client's highlighter shows up only as code that
                        // never gets colored. Same treatment as a failed image load — a Logger.
                        let language = region.language ?? "(none)"
                        Self.logger.warning(
                            "Could not highlight a code block [language=\(language, privacy: .public)]: \(error, privacy: .public)"
                        )
                        continue
                    }
                    guard let highlighted else { continue }
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
        let inputs = AppliedInputs(content: content, theme: theme, mermaidIsDark: mermaidConfig?.isDark)
        guard !context.coordinator.isUnchanged(inputs) else { return }
        let palette = MarkdownDecorationPalette(theme: theme)
        context.coordinator.provider.palette = palette
        MarkdownTextViewFactory.setDecorationPalette(palette, on: textView)
        MarkdownTextViewFactory.apply(attributedString(), to: textView)
        context.coordinator.markApplied(inputs)
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
            context.coordinator.installMermaid(in: textView.textStorage, script: mermaid.script, isDark: mermaid.isDark, displayHeight: 280)
        }
    }

    /// Returns the content height for the proposed width.
    ///
    /// This is what lets a non-scrolling text view size itself correctly inside a SwiftUI
    /// `ScrollView` or stack.
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
        let inputs = AppliedInputs(content: content, theme: theme, mermaidIsDark: mermaidConfig?.isDark)
        guard !context.coordinator.isUnchanged(inputs) else { return }
        context.coordinator.provider.palette = MarkdownDecorationPalette(theme: theme)
        MarkdownTextViewFactory.apply(attributedString(), to: textView)
        context.coordinator.markApplied(inputs)
        if let storage = textView.textContentStorage?.textStorage {
            context.coordinator.startHighlighting(highlighter, in: storage)
            context.coordinator.startImageLoading(
                in: storage,
                policy: imagePolicy,
                width: { [weak textView] in textView?.textContainer?.size.width ?? textView?.bounds.width ?? 0 },
                invalidate: { [weak textView] in textView?.invalidateIntrinsicContentSize() }
            )
            if let mermaid = mermaidConfig {
                context.coordinator.installMermaid(in: storage, script: mermaid.script, isDark: mermaid.isDark, displayHeight: 280)
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
