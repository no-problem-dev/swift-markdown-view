import Foundation
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 単一ストレージを持つ読み取り専用・選択可能な TextKit 2 テキストビューを構築・設定する。ドキュメント全体が1つのテキストストレージに収まるため、選択がブロックをまたいで連続し、システムのコピーが選択テキストを返す。
///
/// このレイヤーは UIKit/AppKit のみ（SwiftUI-free）。`SwiftMarkdownView` が Representable でラップする。`.layoutManager` には触れず、TextKit 1 へのサイレントダウングレードとカスタムフラグメント描画の無効化を防ぐ。
public enum MarkdownTextViewFactory {}

#if canImport(UIKit)
/// コードブロック背景をテキスト**下**のレイヤーに描画する、読み取り専用・選択可能な TextKit 2 テキストビュー。iOS では選択ハイライトが `UITextView`（`selectedTextRange`）に所有され、システムがテキストの上に合成するため `NSTextLayoutFragment` には届かない。コードブロック背景をフラグメントで描くとハイライトが隠れる。テキスト下のサブレイヤーに描くことでシステムの選択ハイライトが正常に表示される。
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

    /// コンテンツサイズに合わせた非スクロール・読み取り専用・選択可能なテキストビュー。SwiftUI の `ScrollView` に埋め込み、固有コンテンツサイズで高さを報告する。
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

    /// デコレーションフラグメントプロバイダーをレイアウトマネージャーのデリゲートとして設定する。デコレーション済みフラグメントが初回レイアウト時に生成されるよう、コンテンツ適用前に呼ぶ。呼び出し側が `provider` を保持すること（デリゲートは弱参照）。
    @MainActor
    static func setFragmentProvider(_ provider: MarkdownLayoutFragmentProvider, on textView: UITextView) {
        textView.textLayoutManager?.delegate = provider
    }

    /// テキスト下のコードブロック背景を描くパレットを設定する。
    @MainActor
    static func setDecorationPalette(_ palette: MarkdownDecorationPalette, on textView: UITextView) {
        (textView as? MarkdownTextView)?.decorationPalette = palette
    }
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
/// コンテンツサイズに合わせてリサイズする、読み取り専用・選択可能な TextKit 2 `NSTextView`（スクロールビューラッパーなし）。SwiftUI のレイアウト/`ScrollView` に埋め込んで `intrinsicContentSize` で高さを報告する。スクロールビューラッパーは SwiftUI 下でゼロ高さになる問題があった。
///
/// macOS では選択が `textLayoutManager.textSelections` にあるため、コードブロック背景と選択くり抜きはレイアウトフラグメントが描画する（iOS とは異なりテキスト下のレイヤーは使わない）。
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

    /// デコレーションフラグメントプロバイダーをレイアウトマネージャーのデリゲートとして設定する。デコレーション済みフラグメントが初回レイアウト時に生成されるよう、コンテンツ適用前に呼ぶ。呼び出し側が `provider` を保持すること（デリゲートは弱参照）。
    @MainActor
    static func setFragmentProvider(_ provider: MarkdownLayoutFragmentProvider, on textView: MarkdownTextView) {
        textView.textLayoutManager?.delegate = provider
    }

    /// SwiftUI の Representable で `sizeThatFits` に使用する、指定幅に収まるコンテンツ高さ。
    @MainActor
    static func contentHeight(of textView: MarkdownTextView, fittingWidth width: CGFloat) -> CGFloat {
        textView.setFrameSize(NSSize(width: width, height: textView.frame.height))
        guard let layoutManager = textView.textLayoutManager else { return 0 }
        layoutManager.ensureLayout(for: layoutManager.documentRange)
        return ceil(layoutManager.usageBoundsForTextContainer.height)
    }
}
#endif
