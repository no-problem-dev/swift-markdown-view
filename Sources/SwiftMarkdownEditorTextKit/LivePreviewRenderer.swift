import Foundation
import SwiftMarkdownEditorCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// `NSTextStorage` にライブプレビュースタイルを適用する。コンテンツにフォントトレイトを付与し、
/// デリミタマーカーを **クリアカラー＋極小フォント＋負カーニング** で非表示にする
/// （`nodes-app/swift-markdown-engine` の `MarkdownStyler` で検証済み）。
/// ソーステキストは変更せず、属性のみ変更する。
enum LivePreviewRenderer {

    /// 非表示マーカーのグリフをほぼゼロに縮小する極小フォントサイズ。
    /// 負カーニングが残留アドバンスを除去する。
    /// `swift-markdown-engine` の `hiddenMarkerFontSize` デフォルト（0.1）に合わせる。
    static let concealFontSize: CGFloat = 0.1

    /// ドキュメント全体のライブプレビュー属性を再適用する。
    static func apply(
        text: String,
        selection: Selection?,
        focused: Bool,
        to storage: NSTextStorage,
        theme: MarkdownEditorTheme
    ) {
        let full = NSRange(location: 0, length: storage.length)
        storage.setAttributes(MarkdownSyntaxHighlighter.baseAttributes(theme: theme), range: full)

        let runs = LivePreviewStyler.runs(text: text, selection: selection, focused: focused)
        guard !runs.isEmpty else { return }

        let ns = text as NSString
        let concealFont = MarkdownSyntaxHighlighter.font(size: concealFontSize)
        let codeColor = theme.style(for: .inlineCode).color ?? theme.textColor

        for run in runs {
            let r = run.range.nsRange
            guard r.location >= 0, NSMaxRange(r) <= storage.length else { continue }

            switch run.trait {
            case .bold:
                mergeTrait(.bold, in: r, storage: storage, baseSize: theme.baseFontSize)
            case .italic:
                mergeTrait(.italic, in: r, storage: storage, baseSize: theme.baseFontSize)
            case .monospace:
                storage.addAttribute(.font, value: MarkdownSyntaxHighlighter.font(size: theme.baseFontSize, monospace: true), range: r)
                storage.addAttribute(.foregroundColor, value: codeColor, range: r)
            case .strikethrough:
                storage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: r)
            case .heading(let level):
                let size = headingSize(level: level, base: theme.baseFontSize)
                storage.addAttribute(.font, value: MarkdownSyntaxHighlighter.font(size: size, bold: true), range: r)
                if let color = theme.style(for: .heading).color {
                    storage.addAttribute(.foregroundColor, value: color, range: r)
                }
            case .conceal:
                let markerText = ns.substring(with: r) as NSString
                let width = markerText.size(withAttributes: [.font: concealFont]).width
                storage.addAttributes([
                    .font: concealFont,
                    .foregroundColor: PlatformColor.clear,
                    .kern: -width,
                ], range: r)
            }
        }
    }

    // MARK: - Heading sizing

    /// ATX 見出し行のポイントサイズ。ベースフォントサイズからスケールする。
    static func headingSize(level: Int, base: CGFloat) -> CGFloat {
        switch level {
        case 1: return base * 1.7
        case 2: return base * 1.45
        case 3: return base * 1.28
        case 4: return base * 1.15
        case 5: return base * 1.07
        default: return base * 1.0
        }
    }

    // MARK: - Font trait merge

    /// `range` を覆うフォントにシンボリックトレイトを追加し、bold と italic を合成する
    /// （例：strong の中の emphasis は bold-italic になる）。
    private static func mergeTrait(_ trait: EditorFontTrait, in range: NSRange, storage: NSTextStorage, baseSize: CGFloat) {
        storage.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            let base = (value as? PlatformFont) ?? MarkdownSyntaxHighlighter.font(size: baseSize)
            if let merged = base.addingEditorTrait(trait) {
                storage.addAttribute(.font, value: merged, range: subRange)
            }
        }
    }
}

/// ライブプレビュースタイリング用の合成可能なフォントトレイト。
enum EditorFontTrait { case bold, italic }

private extension PlatformFont {
    func addingEditorTrait(_ trait: EditorFontTrait) -> PlatformFont? {
        #if canImport(UIKit)
        var traits = fontDescriptor.symbolicTraits
        switch trait {
        case .bold: traits.insert(.traitBold)
        case .italic: traits.insert(.traitItalic)
        }
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return nil }
        return UIFont(descriptor: descriptor, size: pointSize)
        #elseif canImport(AppKit)
        var traits = fontDescriptor.symbolicTraits
        switch trait {
        case .bold: traits.insert(.bold)
        case .italic: traits.insert(.italic)
        }
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize)
        #endif
    }
}
