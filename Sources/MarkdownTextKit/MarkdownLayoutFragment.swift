import Foundation
import CoreGraphics
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Colors and metrics the layout fragment needs to paint block decorations,
/// resolved from the theme as `CGColor` so drawing is platform-neutral.
public struct MarkdownDecorationPalette {
    var codeBackground: CGColor
    var rule: CGColor
    var quoteBar: CGColor
    var indentStep: CGFloat
    var quoteBarWidth: CGFloat
    var codeCornerRadius: CGFloat

    public init(theme: MarkdownTextTheme) {
        self.codeBackground = theme.codeBlockBackground.cgColor
        self.rule = theme.ruleColor.cgColor
        self.quoteBar = theme.quoteBarColor.cgColor
        self.indentStep = theme.indentStep
        self.quoteBarWidth = theme.quoteBarWidth
        self.codeCornerRadius = theme.codeBlockCornerRadius
    }
}

/// Draws code-block backgrounds, thematic rules, and blockquote bars for a
/// rendered Markdown document, identifying decorated ranges via the
/// ``MarkdownBlockDecoration`` attribute. All drawing uses the raw `CGContext`
/// so the same code runs on UIKit and AppKit.
///
/// Code-block fills are punched out where the active selection overlaps (an
/// even-odd cut-out) so the system selection highlight stays visible — TextKit 2
/// otherwise paints the fragment on top of it. Technique adapted from
/// `nodes-app/swift-markdown-engine`.
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

        let bgRect = CGRect(
            x: point.x - layoutFragmentFrame.origin.x,
            y: point.y,
            width: containerWidth,
            height: height
        )

        context.saveGState()
        defer { context.restoreGState() }
        context.setFillColor(palette.codeBackground)

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

    /// Active selection rectangles intersecting this fragment, expanded to the
    /// fill's vertical span so the even-odd cut-out is geometrically congruent.
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
        context.setFillColor(palette.rule)

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

    /// Draws a thin separator under each table row so the tab-stop columns read
    /// as a grid. Full cell text lives in the storage, so selection and copy
    /// already work per-cell; this only adds the horizontal rules.
    private func drawTableRowSeparators(at point: CGPoint, in context: CGContext) {
        guard let palette, let ts = textStorage, let range = fragmentRange,
              case .table = decoration(at: range.location)?.kind,
              let containerWidth = textLayoutManager?.textContainer?.size.width else { return }
        let fragLocation = range.location

        context.saveGState()
        defer { context.restoreGState() }
        context.setFillColor(palette.rule)

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
            let barColor = (ts.attribute(.markdownDecorationBar, at: docStart, effectiveRange: nil) as? PlatformColor)?.cgColor ?? palette.quoteBar
            context.setFillColor(barColor)
            let tb = line.typographicBounds
            let barY = point.y + tb.origin.y
            for i in 0..<max(1, level) {
                let barX = leftEdge + CGFloat(i) * palette.indentStep + palette.indentStep * 0.25
                context.fill(CGRect(x: barX, y: barY, width: palette.quoteBarWidth, height: tb.height))
            }
        }
    }
}

/// Vends ``MarkdownLayoutFragment``s, stamping each with the decoration palette.
/// Owned (retained) by the view layer and set as the
/// `NSTextLayoutManager.delegate`.
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
