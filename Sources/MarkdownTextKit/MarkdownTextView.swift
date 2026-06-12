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
public extension MarkdownTextViewFactory {

    /// A content-sized (non-scrolling) read-only selectable text view. Embed it
    /// in a SwiftUI `ScrollView`; it reports its height via intrinsic content size.
    @MainActor
    static func make() -> UITextView {
        let textView = UITextView(usingTextLayoutManager: true)
        assert(textView.textLayoutManager != nil, "Expected TextKit 2 to be active")
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        return textView
    }

    @MainActor
    static func apply(_ attributed: NSAttributedString, to textView: UITextView) {
        textView.textStorage.setAttributedString(attributed)
        textView.invalidateIntrinsicContentSize()
    }

    /// Installs the decoration fragment provider as the layout manager delegate.
    /// Call before applying content so decorated fragments are vended on first
    /// layout. The caller must retain `provider` (the delegate is weak).
    @MainActor
    static func setFragmentProvider(_ provider: MarkdownLayoutFragmentProvider, on textView: UITextView) {
        textView.textLayoutManager?.delegate = provider
    }
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
public extension MarkdownTextViewFactory {

    /// A read-only selectable TextKit 2 `NSTextView` plus the scroll view that
    /// hosts it. `SwiftMarkdownView` decides whether to let it scroll or size to
    /// content.
    @MainActor
    static func make() -> (scrollView: NSScrollView, textView: NSTextView) {
        let contentStorage = NSTextContentStorage()
        let layoutManager = NSTextLayoutManager()
        contentStorage.addTextLayoutManager(layoutManager)

        let container = NSTextContainer(size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        container.lineFragmentPadding = 0
        layoutManager.textContainer = container

        let textView = NSTextView(frame: .zero, textContainer: container)
        assert(textView.textLayoutManager != nil, "Expected TextKit 2 to be active")
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize.zero
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [NSView.AutoresizingMask.width]

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        return (scrollView, textView)
    }

    @MainActor
    static func apply(_ attributed: NSAttributedString, to textView: NSTextView) {
        textView.textContentStorage?.performEditingTransaction {
            textView.textContentStorage?.textStorage?.setAttributedString(attributed)
        }
    }

    /// Installs the decoration fragment provider as the layout manager delegate.
    /// Call before applying content so decorated fragments are vended on first
    /// layout. The caller must retain `provider` (the delegate is weak).
    @MainActor
    static func setFragmentProvider(_ provider: MarkdownLayoutFragmentProvider, on textView: NSTextView) {
        textView.textLayoutManager?.delegate = provider
    }
}
#endif
