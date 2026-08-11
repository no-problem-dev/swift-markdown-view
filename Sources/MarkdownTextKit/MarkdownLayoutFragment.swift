import Foundation
import CoreGraphics
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The colors and metrics a layout fragment needs in order to draw block decorations.
///
/// The colors stay `UIColor` / `NSColor` — dynamic — all the way to the drawing code, which turns
/// each one into a `CGColor` at the moment it fills. A `CGColor` is a concrete color: asking a
/// dynamic color for one resolves it against whatever appearance is current on the thread right
/// then and freezes the answer. This palette is built from a theme in `makeUIView` /
/// `updateUIView`, where the current appearance is not the text view's, so a palette of `CGColor`
/// came out light and stayed light — the body text followed the user into dark mode and the code
/// background, the rules, and the quote bars did not.
public struct MarkdownDecorationPalette {
    var codeBackground: PlatformColor
    var rule: PlatformColor
    var quoteBar: PlatformColor
    var indentStep: CGFloat
    var quoteBarWidth: CGFloat
    var codeCornerRadius: CGFloat
    var codeVerticalPadding: CGFloat

    public init(theme: MarkdownTextTheme) {
        self.codeBackground = theme.codeBlockBackground
        self.rule = theme.ruleColor
        self.quoteBar = theme.quoteBarColor
        self.indentStep = theme.indentStep
        self.quoteBarWidth = theme.quoteBarWidth
        self.codeCornerRadius = theme.codeBlockCornerRadius
        self.codeVerticalPadding = theme.codeBlockVerticalPadding
    }
}

/// Draws the block decorations of a Markdown document over its text.
///
/// Decoration ranges are located by the ``MarkdownBlockDecoration`` attribute, and everything is drawn
/// with a raw `CGContext` so UIKit and AppKit run the same code. Horizontal rules, block quote bars, and
/// table row separators are drawn on both platforms; the code block background is drawn here on macOS
/// only — see `draw(at:in:)`.
///
/// Every palette color becomes a `CGColor` inside `draw(at:in:)` and nowhere earlier. UIKit and AppKit
/// push the drawing view's appearance before calling into a fragment, so a dynamic color asked for its
/// `cgColor` here resolves to the appearance actually on screen. Ask outside a draw and the answer is
/// whatever appearance happened to be current, kept forever.
///
/// On macOS the code block fill is punched out with the even-odd rule wherever it overlaps the active
/// selection, so the system's selection highlight shows through: left alone, TextKit 2 draws the fragment
/// on top of the highlight. The technique is adapted from `nodes-app/swift-markdown-engine`.
final class MarkdownLayoutFragment: NSTextLayoutFragment {

    var palette: MarkdownDecorationPalette?

    // MARK: Rendering surface

    override var renderingSurfaceBounds: CGRect {
        var bounds = super.renderingSurfaceBounds
        if hasFullWidthDecoration, let containerWidth = textLayoutManager?.textContainer?.size.width {
            bounds.origin.x = -layoutFragmentFrame.origin.x
            bounds.size.width = containerWidth
        }
        return bounds
    }

    // MARK: Drawing

    override func draw(at point: CGPoint, in context: CGContext) {
        #if !canImport(UIKit)
        // macOS: fill the code background here and punch out the selection
        // (which lives in `textLayoutManager.textSelections`). On UIKit the
        // selection is owned by UITextView and never reaches the fragment, so the
        // code background is drawn in a layer beneath the text instead (see
        // `MarkdownTextView`); drawing it here would occlude the selection.
        drawCodeBackground(at: point, in: context)
        #endif
        super.draw(at: point, in: context)
        drawThematicBreaks(at: point, in: context)
        drawBlockquoteBars(at: point, in: context)
        drawTableRowSeparators(at: point, in: context)
    }

    // MARK: Storage access

    private var textStorage: NSTextStorage? {
        (textLayoutManager?.textContentManager as? NSTextContentStorage)?.textStorage
    }

    private var fragmentRange: NSRange? {
        guard let tcs = textLayoutManager?.textContentManager as? NSTextContentStorage else { return nil }
        let start = tcs.offset(from: tcs.documentRange.location, to: rangeInElement.location)
        let end = tcs.offset(from: tcs.documentRange.location, to: rangeInElement.endLocation)
        guard start != NSNotFound, end != NSNotFound, end > start else { return nil }
        return NSRange(location: start, length: end - start)
    }

    private func decoration(at index: Int) -> MarkdownBlockDecoration? {
        guard let ts = textStorage, index >= 0, index < ts.length else { return nil }
        return ts.attribute(.markdownBlockDecoration, at: index, effectiveRange: nil) as? MarkdownBlockDecoration
    }

    private var hasFullWidthDecoration: Bool {
        guard let range = fragmentRange else { return false }
        switch decoration(at: range.location)?.kind {
        case .codeBlock, .thematicBreak, .blockQuote: return true
        case .table, .none: return false
        }
    }

    // MARK: Code-block background

    private func drawCodeBackground(at point: CGPoint, in context: CGContext) {
        guard let palette, let range = fragmentRange,
              case .codeBlock = decoration(at: range.location)?.kind,
              let containerWidth = textLayoutManager?.textContainer?.size.width else { return }

        var height = layoutFragmentFrame.height
        if textLineFragments.count > 1, let last = textLineFragments.last, last.characterRange.length == 0 {
            height -= last.typographicBounds.height
        }

        // Expand each code line's band by the vertical padding; stacked bands
        // overlap (same color), giving the whole block top/bottom breathing room.
        let vPad = palette.codeVerticalPadding
        let bgRect = CGRect(
            x: point.x - layoutFragmentFrame.origin.x,
            y: point.y - vPad,
            width: containerWidth,
            height: height + vPad * 2
        )

        context.saveGState()
        defer { context.restoreGState() }
        context.setFillColor(palette.codeBackground.cgColor)

        let selection = selectionRects(point: point, fillRect: bgRect)
        if selection.isEmpty {
            context.fill(bgRect)
        } else {
            context.beginPath()
            context.addRect(bgRect)
            for r in selection { context.addRect(r.intersection(bgRect)) }
            context.fillPath(using: .evenOdd)
        }
    }

    /// The active selection rectangles that intersect this fragment.
    ///
    /// Each one is stretched to the fill's vertical span so the even-odd cut-out lines up with it exactly.
    private func selectionRects(point: CGPoint, fillRect: CGRect) -> [CGRect] {
        guard let tlm = textLayoutManager else { return [] }
        var rects: [CGRect] = []
        let dx = point.x - layoutFragmentFrame.origin.x
        let mine = rangeInElement

        for selection in tlm.textSelections {
            for textRange in selection.textRanges {
                let start = textRange.location.compare(mine.location) == .orderedAscending ? mine.location : textRange.location
                let end = textRange.endLocation.compare(mine.endLocation) == .orderedDescending ? mine.endLocation : textRange.endLocation
                guard start.compare(end) == .orderedAscending,
                      let intersection = NSTextRange(location: start, end: end) else { continue }
                tlm.enumerateTextSegments(in: intersection, type: .selection, options: []) { _, segFrame, _, _ in
                    rects.append(CGRect(x: segFrame.origin.x + dx, y: fillRect.minY, width: segFrame.width, height: fillRect.height))
                    return true
                }
            }
        }
        return rects
    }

    // MARK: Thematic break

    private func drawThematicBreaks(at point: CGPoint, in context: CGContext) {
        guard let palette, let ts = textStorage, let range = fragmentRange,
              let containerWidth = textLayoutManager?.textContainer?.size.width else { return }
        let fragLocation = range.location
        context.saveGState()
        defer { context.restoreGState() }
        context.setFillColor(palette.rule.cgColor)

        for line in textLineFragments {
            let docStart = fragLocation + line.characterRange.location
            guard docStart < ts.length,
                  decoration(at: docStart)?.kind == .thematicBreak else { continue }
            let tb = line.typographicBounds
            let centerY = point.y + tb.origin.y + tb.height / 2
            context.fill(CGRect(x: point.x - layoutFragmentFrame.origin.x, y: centerY - 0.5, width: containerWidth, height: 1))
        }
    }

    // MARK: Table row separators

    /// Draws a hairline under each table row so the tab-stop columns read as a grid.
    ///
    /// The cell text lives in the storage, so selection and copy already work cell by cell; this only
    /// adds the horizontal lines.
    private func drawTableRowSeparators(at point: CGPoint, in context: CGContext) {
        guard let palette, let ts = textStorage, let range = fragmentRange,
              case .table = decoration(at: range.location)?.kind,
              let containerWidth = textLayoutManager?.textContainer?.size.width else { return }
        let fragLocation = range.location

        context.saveGState()
        defer { context.restoreGState() }
        context.setFillColor(palette.rule.cgColor)

        for line in textLineFragments {
            let docStart = fragLocation + line.characterRange.location
            guard docStart < ts.length else { continue }
            let tb = line.typographicBounds
            let bottomY = point.y + tb.origin.y + tb.height
            context.fill(CGRect(x: point.x - layoutFragmentFrame.origin.x, y: bottomY - 0.5, width: containerWidth, height: 0.5))
        }
    }

    // MARK: Blockquote bars

    private func drawBlockquoteBars(at point: CGPoint, in context: CGContext) {
        guard let palette, let ts = textStorage, let range = fragmentRange else { return }
        let fragLocation = range.location
        let leftEdge = point.x - layoutFragmentFrame.origin.x

        context.saveGState()
        defer { context.restoreGState() }

        for line in textLineFragments {
            let docStart = fragLocation + line.characterRange.location
            guard docStart < ts.length,
                  case .blockQuote(let level) = decoration(at: docStart)?.kind else { continue }
            let barColor = (ts.attribute(.markdownDecorationBar, at: docStart, effectiveRange: nil) as? PlatformColor) ?? palette.quoteBar
            context.setFillColor(barColor.cgColor)
            let tb = line.typographicBounds
            let barY = point.y + tb.origin.y
            for i in 0..<max(1, level) {
                let barX = leftEdge + CGFloat(i) * palette.indentStep + palette.indentStep * 0.25
                context.fill(CGRect(x: barX, y: barY, width: palette.quoteBarWidth, height: tb.height))
            }
        }
    }
}

/// Creates the decorating layout fragments and stamps each one with the decoration palette.
///
/// The view layer owns — and must retain — the provider, and installs it as the
/// `NSTextLayoutManager.delegate`, which holds it weakly.
public final class MarkdownLayoutFragmentProvider: NSObject, NSTextLayoutManagerDelegate {

    public var palette: MarkdownDecorationPalette?

    public init(palette: MarkdownDecorationPalette? = nil) {
        self.palette = palette
    }

    public func textLayoutManager(
        _ textLayoutManager: NSTextLayoutManager,
        textLayoutFragmentFor location: any NSTextLocation,
        in textElement: NSTextElement
    ) -> NSTextLayoutFragment {
        let fragment = MarkdownLayoutFragment(textElement: textElement, range: textElement.elementRange)
        fragment.palette = palette
        return fragment
    }
}
