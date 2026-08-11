import Foundation
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Builds and configures the read-only, selectable TextKit 2 text view backed by a single storage.
///
/// The whole document lives in one text storage, so selection runs continuously across blocks and the
/// system's copy returns the selected text.
///
/// This layer is UIKit and AppKit only, with no SwiftUI; `SwiftMarkdownView` wraps it in a representable.
/// Never touch `.layoutManager`: doing so silently downgrades the view to TextKit 1 and turns off the
/// custom fragment drawing.
public enum MarkdownTextViewFactory {}

#if canImport(UIKit)
/// A read-only, selectable TextKit 2 text view that draws code block backgrounds *below* the text.
///
/// On iOS the selection highlight belongs to `UITextView` (`selectedTextRange`) and is composited over
/// the text by the system, so it never reaches `NSTextLayoutFragment`. Drawing the code block background
/// from a fragment would hide the highlight; drawing it into a sublayer under the text lets the system's
/// highlight come through.
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

        // A `CAShapeLayer` fill is a `CGColor`, so the dynamic theme color has to be resolved to
        // one, and a resolved color does not follow the user into dark mode. `layoutSubviews` is
        // not called when only the appearance changes, so ask for the fill again whenever a trait
        // that decides how a color resolves moves.
        registerForTraitChanges(Self.traitsAffectingColor) { (view: MarkdownTextView, _) in
            view.updateCodeBackgrounds()
        }
    }

    private static let traitsAffectingColor: [any UITraitDefinition.Type] = [
        UITraitUserInterfaceStyle.self,
        UITraitUserInterfaceLevel.self,
        UITraitAccessibilityContrast.self,
        UITraitDisplayGamut.self
    ]

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
        // Resolve against this view's traits rather than whatever is ambient: this runs from
        // `layoutSubviews` and from the trait-change handler, and only the view's own trait
        // collection is right in both.
        codeBackgroundLayer.fillColor = palette.codeBackground.resolvedColor(with: traitCollection).cgColor
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

    /// A non-scrolling, read-only, selectable text view sized to its content.
    ///
    /// Meant to be embedded in a SwiftUI `ScrollView`; it reports its height as its intrinsic content size.
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

    /// Installs the decoration fragment provider as the layout manager's delegate.
    ///
    /// Call this before applying content, so that the fragments the first layout pass creates are the
    /// decorated ones. The delegate is held weakly, so the caller has to retain `provider`.
    @MainActor
    static func setFragmentProvider(_ provider: MarkdownLayoutFragmentProvider, on textView: UITextView) {
        textView.textLayoutManager?.delegate = provider
    }

    /// Sets the palette used to draw the code block background beneath the text.
    ///
    /// Does nothing when the view is not a ``MarkdownTextView``.
    @MainActor
    static func setDecorationPalette(_ palette: MarkdownDecorationPalette, on textView: UITextView) {
        (textView as? MarkdownTextView)?.decorationPalette = palette
    }
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
/// A read-only, selectable TextKit 2 text view that resizes to its content, with no enclosing scroll view.
///
/// Embed it in SwiftUI layout or a `ScrollView`; it reports its height through `intrinsicContentSize`. A
/// scroll view wrapper is deliberately avoided because it collapsed to zero height under SwiftUI.
///
/// On macOS the selection lives in `textLayoutManager.textSelections`, so the layout fragment draws both
/// the code block background and the selection cut-out — unlike iOS, there is no layer beneath the text.
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

    /// Installs the decoration fragment provider as the layout manager's delegate.
    ///
    /// Call this before applying content, so that the fragments the first layout pass creates are the
    /// decorated ones. The delegate is held weakly, so the caller has to retain `provider`.
    @MainActor
    static func setFragmentProvider(_ provider: MarkdownLayoutFragmentProvider, on textView: MarkdownTextView) {
        textView.textLayoutManager?.delegate = provider
    }

    /// The content height at the given width, for `sizeThatFits` in the SwiftUI representable.
    ///
    /// Resizes the view to that width as a side effect.
    @MainActor
    static func contentHeight(of textView: MarkdownTextView, fittingWidth width: CGFloat) -> CGFloat {
        textView.setFrameSize(NSSize(width: width, height: textView.frame.height))
        guard let layoutManager = textView.textLayoutManager else { return 0 }
        layoutManager.ensureLayout(for: layoutManager.documentRange)
        return ceil(layoutManager.usageBoundsForTextContainer.height)
    }
}
#endif
