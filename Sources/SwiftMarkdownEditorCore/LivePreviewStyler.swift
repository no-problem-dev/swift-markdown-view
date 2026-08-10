import Foundation

/// One style contribution to one range.
///
/// Contributions are *additive*: the TextKit layer merges each one into the base attributes, so
/// applying `bold` to an already italic range yields bold-italic. Conceal ranges never overlap
/// content ranges, so the two cannot collide.
package struct StyleRun: Equatable, Sendable {
    package enum Trait: Equatable, Sendable {
        case bold
        case italic
        case monospace
        case strikethrough
        /// The content of an ATX heading, rendered large and bold according to its level (1–6).
        case heading(level: Int)
        /// Hides the range visually while keeping its text, used for delimiter markers.
        case conceal
    }

    package var range: TextSpan
    package var trait: Trait

    package init(range: TextSpan, trait: Trait) {
        self.range = range
        self.trait = trait
    }
}

/// Computes live preview styling: content gets its styles, delimiter markers are hidden.
///
/// Markers stay visible on the lines the selection touches — the "show the source on the cursor
/// line" rule from Obsidian and Typora, also confirmed in CodeMirror 6 and swift-markdown-engine.
///
/// Pure and UI-independent. It returns semantic ``StyleRun`` values; the TextKit layer implements
/// `conceal` with a clear color, a near-zero font size and negative kerning, and maps every other
/// trait onto the font's symbolic traits.
package enum LivePreviewStyler {

    /// The style runs for a document, given where the caret is.
    ///
    /// - Parameters:
    ///   - text: The document's source text.
    ///   - selection: The current selection, or `nil` when nothing is being edited.
    ///   - focused: Whether the editor has focus. When `false`, every marker is concealed, which is
    ///     the read-only rendered state.
    package static func runs(text: String, selection: Selection?, focused: Bool) -> [StyleRun] {
        // Resolve line boundaries once. Scanning the whole text per span is quadratic in document
        // length, and this runs on every keystroke and caret move, so the editor becomes unusable.
        let lines = LineIndex(text)
        let activeLine = (focused ? selection : nil).map { activeLineSpan(lines: lines, selection: $0) }

        var runs: [StyleRun] = []

        // Only the tokenizer knows the block structure, since it tracks fences opening and closing
        // as state. The inline span parser works line by line and has no block context, so the
        // fenced ranges are handed over here and excluded. Without that, the `**` inside
        // ```` ```let a = **b** ``` ```` gets concealed and the symbols vanish from the user's code.
        let tokens = MarkdownTokenizer.tokenize(text)
        appendHeadingRuns(lines: lines, tokens: tokens, activeLine: activeLine, into: &runs)

        let verbatim = MarkdownTokenizer.fencedCodeRanges(tokens)
        for span in InlineSpanParser.parse(text) {
            guard !isInsideVerbatim(span.fullRange, verbatim) else { continue }

            // Content styling is always applied (revealed lines keep bold etc.).
            if let trait = contentTrait(for: span.kind), span.contentRange.length > 0 {
                runs.append(StyleRun(range: span.contentRange, trait: trait))
            }

            // Markers are concealed unless this span's line is active.
            let revealed = activeLine.map { $0.overlaps(lines.lineRange(containing: span.fullRange.lowerBound)) } ?? false
            if !revealed {
                for marker in span.markerRanges {
                    runs.append(StyleRun(range: marker, trait: .conceal))
                }
            }
        }
        return runs
    }

    // MARK: - Verbatim (fenced code) regions

    /// Binary search over ascending, non-overlapping ranges.
    ///
    /// A linear scan per span would be quadratic in document length, so the cost is paid here
    /// instead.
    private static func isInsideVerbatim(_ span: TextSpan, _ ranges: [TextSpan]) -> Bool {
        var low = 0
        var high = ranges.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let range = ranges[mid]
            if span.lowerBound >= range.upperBound {
                low = mid + 1
            } else if span.upperBound <= range.lowerBound {
                high = mid - 1
            } else {
                return true
            }
        }
        return false
    }

    // MARK: - Block headings

    /// Emits a heading run for every ATX heading and conceals its `#…` marker.
    ///
    /// The concealed range covers the marker and the space that follows it. As with inline span
    /// markers, the marker stays visible while the heading's line is the active one.
    private static func appendHeadingRuns(
        lines: LineIndex,
        tokens: [MarkdownToken],
        activeLine: TextSpan?,
        into runs: inout [StyleRun]
    ) {
        var i = 0
        while i < tokens.count {
            guard tokens[i].kind == .headingMarker else { i += 1; continue }
            let marker = tokens[i].range
            let level = max(1, min(6, marker.length))
            var concealUpper = marker.upperBound

            // Pair with the following `.heading` content token when present.
            if i + 1 < tokens.count, tokens[i + 1].kind == .heading {
                let content = tokens[i + 1].range
                runs.append(StyleRun(range: content, trait: .heading(level: level)))
                concealUpper = content.lowerBound   // conceal the marker + trailing space
                i += 1
            }

            let line = lines.lineRange(containing: marker.lowerBound)
            let revealed = activeLine.map { $0.overlaps(line) } ?? false
            if !revealed, concealUpper > marker.lowerBound {
                runs.append(StyleRun(
                    range: TextSpan(lowerBound: marker.lowerBound, upperBound: concealUpper),
                    trait: .conceal
                ))
            }
            i += 1
        }
    }

    // MARK: - Helpers

    private static func contentTrait(for kind: InlineSpan.Kind) -> StyleRun.Trait? {
        switch kind {
        case .strong: return .bold
        case .emphasis: return .italic
        case .strikethrough: return .strikethrough
        case .code: return .monospace
        }
    }

    /// The combined range of the lines the selection touches, from the anchor's line to the head's.
    private static func activeLineSpan(lines: LineIndex, selection: Selection) -> TextSpan {
        let lower = lines.lineRange(containing: selection.range.lowerBound).lowerBound
        let upper = lines.lineRange(containing: selection.range.upperBound).upperBound
        return TextSpan(lowerBound: lower, upperBound: upper)
    }
}
