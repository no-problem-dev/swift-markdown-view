import Foundation
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Builds and configures the single-storage, read-only, **selectable** TextKit 2
/// text view that hosts a whole rendered Markdown document. Because the entire
/// document lives in one text storage, selection runs continuously across blocks
/// and the system Copy yields the selected readable text.
///
/// This layer is UIKit/AppKit-only (SwiftUI-free); `SwiftMarkdownView` wraps the
/// view in a Representable. The code never touches `.layoutManager`, which would
/// silently drop the view to TextKit 1 and disable later custom fragment drawing.
public enum MarkdownTextViewFactory {}

#if canImport(UIKit)
/// A read-only selectable TextKit 2 text view that paints code-block backgrounds
/// in a layer **beneath the text**. On iOS the selection highlight is owned by
/// `UITextView` (in `selectedTextRange`) and composited above the text by the
/// system — it never reaches an `NSTextLayoutFragment` — so filling the code
/// background in a fragment would hide it. Drawing the fill in a sublayer below
/// the text lets the system's selection highlight show through normally.
public final class MarkdownTextView: UITextView {

    public var decorationPalette: MarkdownDecorationPalette? {
        didSet { setNeedsLayout() }
    }

    private let codeBackgroundLayer = CAShapeLayer()

    public init() {
        let contentStorage = NSTextContentStorage()
        let layoutManager = NSTextLayoutManager()
        contentStorage.addTextLayoutManager(layoutManager)
        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        container.lineFragmentPadding = 0
        layoutManager.textContainer = container
        super.init(frame: .zero, textContainer: container)
        assert(textLayoutManager != nil, "Expected TextKit 2 to be active")

        isEditable = false
        isSelectable = true
        isScrollEnabled = false
        backgroundColor = .clear
        textContainerInset = .zero
        adjustsFontForContentSizeCategory = true

        codeBackgroundLayer.actions = ["path": NSNull(), "fillColor": NSNull(), "bounds": NSNull(), "position": NSNull()]
        layer.insertSublayer(codeBackgroundLayer, at: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateCodeBackgrounds()
    }

    private func updateCodeBackgrounds() {
        guard let palette = decorationPalette,
              let tlm = textLayoutManager,
              let contentStorage = tlm.textContentManager as? NSTextContentStorage,
              let storage = contentStorage.textStorage,
              bounds.width > 0 else {
            codeBackgroundLayer.path = nil
            return
        }

        let width = bounds.width
        let radius = palette.codeCornerRadius
        let vPad = palette.codeVerticalPadding
        let path = CGMutablePath()
        var current: CGRect?

        func flush() {
            if let rect = current {
                // Expand the block's box vertically for breathing room around the
                // code text (the rounded box hugs the union of its line frames).
                path.addRoundedRect(in: rect.insetBy(dx: 0, dy: -vPad), cornerWidth: radius, cornerHeight: radius)
                current = nil
            }
        }

        _ = tlm.enumerateTextLayoutFragments(from: nil, options: [.ensuresLayout]) { fragment in
            if Self.isCodeFragment(fragment, contentStorage: contentStorage, storage: storage) {
                let frame = fragment.layoutFragmentFrame
                let rect = CGRect(x: 0, y: frame.minY, width: width, height: frame.height)
                current = current?.union(rect) ?? rect
            } else {
                flush()
            }
            return true
        }
        flush()

        codeBackgroundLayer.frame = bounds
        codeBackgroundLayer.fillColor = palette.codeBackground
        codeBackgroundLayer.path = path.isEmpty ? nil : path
    }

    private static func isCodeFragment(_ fragment: NSTextLayoutFragment, contentStorage: NSTextContentStorage, storage: NSTextStorage) -> Bool {
        let start = contentStorage.offset(from: contentStorage.documentRange.location, to: fragment.rangeInElement.location)
        guard start != NSNotFound, start >= 0, start < storage.length,
              let decoration = storage.attribute(.markdownBlockDecoration, at: start, effectiveRange: nil) as? MarkdownBlockDecoration else {
            return false
        }
        if case .codeBlock = decoration.kind { return true }
        return false
    }
}

public extension MarkdownTextViewFactory {

    /// A content-sized (non-scrolling) read-only selectable text view. Embed it
    /// in a SwiftUI `ScrollView`; it reports its height via intrinsic content size.
    @MainActor
    static func make() -> MarkdownTextView {
        MarkdownTextView()
    }

    @MainActor
    static func apply(_ attributed: NSAttributedString, to textView: UITextView) {
        textView.textStorage.setAttributedString(attributed)
        textView.invalidateIntrinsicContentSize()
        textView.setNeedsLayout()
    }

    /// Installs the decoration fragment provider as the layout manager delegate.
    /// Call before applying content so decorated fragments are vended on first
    /// layout. The caller must retain `provider` (the delegate is weak).
    @MainActor
    static func setFragmentProvider(_ provider: MarkdownLayoutFragmentProvider, on textView: UITextView) {
        textView.textLayoutManager?.delegate = provider
    }

    /// Sets the palette used to paint code-block backgrounds beneath the text.
    @MainActor
    static func setDecorationPalette(_ palette: MarkdownDecorationPalette, on textView: UITextView) {
        (textView as? MarkdownTextView)?.decorationPalette = palette
    }
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
/// A read-only selectable TextKit 2 `NSTextView` that sizes to its content (no
/// enclosing scroll view), so it embeds in a SwiftUI layout/`ScrollView` and
/// reports its height via `intrinsicContentSize` — mirroring the iOS view. The
/// previous scroll-view wrapper collapsed to zero height under SwiftUI.
///
/// On macOS the selection lives in `textLayoutManager.textSelections`, so the
/// code-block background and its selection cut-out are drawn by the layout
/// fragment (unlike iOS, which paints it in a layer beneath the text).
public final class MarkdownTextView: NSTextView {

    public convenience init() {
        let contentStorage = NSTextContentStorage()
        let layoutManager = NSTextLayoutManager()
        contentStorage.addTextLayoutManager(layoutManager)
        let container = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        container.lineFragmentPadding = 0
        layoutManager.textContainer = container

        self.init(frame: .zero, textContainer: container)
        assert(textLayoutManager != nil, "Expected TextKit 2 to be active")
        isEditable = false
        isSelectable = true
        isRichText = true
        drawsBackground = false
        textContainerInset = .zero
        isVerticallyResizable = true
        isHorizontallyResizable = false
        minSize = .zero
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        autoresizingMask = [.width]
    }

    public override var intrinsicContentSize: NSSize {
        guard let layoutManager = textLayoutManager else { return super.intrinsicContentSize }
        layoutManager.ensureLayout(for: layoutManager.documentRange)
        return NSSize(width: NSView.noIntrinsicMetric, height: ceil(layoutManager.usageBoundsForTextContainer.height))
    }
}

public extension MarkdownTextViewFactory {

    @MainActor
    static func make() -> MarkdownTextView { MarkdownTextView() }

    @MainActor
    static func apply(_ attributed: NSAttributedString, to textView: MarkdownTextView) {
        textView.textContentStorage?.performEditingTransaction {
            textView.textContentStorage?.textStorage?.setAttributedString(attributed)
        }
        textView.invalidateIntrinsicContentSize()
    }

    /// Installs the decoration fragment provider as the layout manager delegate.
    /// Call before applying content so decorated fragments are vended on first
    /// layout. The caller must retain `provider` (the delegate is weak).
    @MainActor
    static func setFragmentProvider(_ provider: MarkdownLayoutFragmentProvider, on textView: MarkdownTextView) {
        textView.textLayoutManager?.delegate = provider
    }

    /// Content height for the given width, for the SwiftUI representable's
    /// `sizeThatFits`.
    @MainActor
    static func contentHeight(of textView: MarkdownTextView, fittingWidth width: CGFloat) -> CGFloat {
        textView.setFrameSize(NSSize(width: width, height: textView.frame.height))
        guard let layoutManager = textView.textLayoutManager else { return 0 }
        layoutManager.ensureLayout(for: layoutManager.documentRange)
        return ceil(layoutManager.usageBoundsForTextContainer.height)
    }
}
#endif
