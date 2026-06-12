import Foundation

/// A single styling contribution over a range. Contributions are *additive*:
/// the TextKit layer merges them onto the base attributes (so `bold` over a
/// range that already has `italic` yields bold-italic). `conceal` ranges are
/// disjoint from content ranges, so they never conflict.
public struct StyleRun: Equatable, Sendable {
    public enum Trait: Equatable, Sendable {
        case bold
        case italic
        case monospace
        case strikethrough
        /// An ATX heading's content — rendered larger and bold by level (1–6).
        case heading(level: Int)
        /// Hide the range visually while keeping it in the text (markers).
        case conceal
    }

    public var range: TextSpan
    public var trait: Trait

    public init(range: TextSpan, trait: Trait) {
        self.range = range
        self.trait = trait
    }
}

/// Computes live-preview styling: content is styled, and delimiter markers are
/// concealed — except on the line(s) the selection touches, where the raw
/// markers are revealed (the Obsidian/Typora "cursor line shows source" rule,
/// confirmed against CodeMirror 6 and swift-markdown-engine).
///
/// Pure and UI-independent: returns semantic ``StyleRun``s; the TextKit layer
/// maps `conceal` to the clear-color + tiny-font + negative-kern technique and
/// the traits to font symbolic traits.
public enum LivePreviewStyler {

    /// - Parameters:
    ///   - text: The document source.
    ///   - selection: The current selection, or `nil` when not editing.
    ///   - focused: Whether the editor is focused. When false, everything is
    ///     concealed (read-only rendered look).
    public static func runs(text: String, selection: Selection?, focused: Bool) -> [StyleRun] {
        let activeLine = (focused ? selection : nil).map { activeLineSpan(text: text, selection: $0) }

        var runs: [StyleRun] = []

        // Block-level headings first, so inline traits inside a heading merge
        // onto the enlarged font rather than overwriting it.
        appendHeadingRuns(text: text, activeLine: activeLine, into: &runs)

        let spans = InlineSpanParser.parse(text)
        for span in spans {
            // Content styling is always applied (revealed lines keep bold etc.).
            if let trait = contentTrait(for: span.kind), span.contentRange.length > 0 {
                runs.append(StyleRun(range: span.contentRange, trait: trait))
            }

            // Markers are concealed unless this span's line is active.
            let revealed = activeLine.map { $0.overlaps(spanLine(text: text, span: span)) } ?? false
            if !revealed {
                for marker in span.markerRanges {
                    runs.append(StyleRun(range: marker, trait: .conceal))
                }
            }
        }
        return runs
    }

    // MARK: - Block headings

    /// Emits a `.heading(level)` run over each ATX heading's content and conceals
    /// its `#…` marker (and the space after it), unless the heading's line is the
    /// active one — matching the marker-reveal rule used for inline spans.
    private static func appendHeadingRuns(text: String, activeLine: TextSpan?, into runs: inout [StyleRun]) {
        let tokens = MarkdownTokenizer.tokenize(text)
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

            let line = text.lineRange(containing: marker.lowerBound)
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

    /// The line range of a span (the line its opening marker sits on).
    private static func spanLine(text: String, span: InlineSpan) -> TextSpan {
        text.lineRange(containing: span.fullRange.lowerBound)
    }

    /// The union of lines touched by the selection (anchor line … head line).
    private static func activeLineSpan(text: String, selection: Selection) -> TextSpan {
        let lower = text.lineRange(containing: selection.range.lowerBound).lowerBound
        let upper = text.lineRange(containing: selection.range.upperBound).upperBound
        return TextSpan(lowerBound: lower, upperBound: upper)
    }
}
