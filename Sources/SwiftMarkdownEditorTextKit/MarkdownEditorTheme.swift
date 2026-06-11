import Foundation
import CoreGraphics
import SwiftMarkdownEditorCore

/// Visual styling for the source editor: the base font/colors plus how each
/// ``MarkdownToken/Kind`` is tinted.
///
/// This is intentionally framework-light (platform colors + a font size) so the
/// SwiftUI layer can build one from the design system, while the TextKit bridge
/// and unit tests can use the built-in `.light` / `.dark` presets.
public struct MarkdownEditorTheme {

    /// Per-token styling: a color plus font-trait toggles.
    public struct TokenStyle {
        public var color: PlatformColor?
        public var bold: Bool
        public var italic: Bool
        public var monospace: Bool
        public var strikethrough: Bool

        public init(
            color: PlatformColor? = nil,
            bold: Bool = false,
            italic: Bool = false,
            monospace: Bool = false,
            strikethrough: Bool = false
        ) {
            self.color = color
            self.bold = bold
            self.italic = italic
            self.monospace = monospace
            self.strikethrough = strikethrough
        }
    }

    public var baseFontSize: CGFloat
    public var textColor: PlatformColor
    public var backgroundColor: PlatformColor
    public var tintColor: PlatformColor
    public var styles: [MarkdownToken.Kind: TokenStyle]

    public init(
        baseFontSize: CGFloat,
        textColor: PlatformColor,
        backgroundColor: PlatformColor,
        tintColor: PlatformColor,
        styles: [MarkdownToken.Kind: TokenStyle]
    ) {
        self.baseFontSize = baseFontSize
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.tintColor = tintColor
        self.styles = styles
    }

    /// The style for a token kind, or an empty style if unspecified.
    public func style(for kind: MarkdownToken.Kind) -> TokenStyle {
        styles[kind] ?? TokenStyle()
    }
}

public extension MarkdownEditorTheme {

    /// A theme whose token tints derive from a base text color, a muted color,
    /// an accent color, and a code color — the four roles every preset needs.
    static func make(
        baseFontSize: CGFloat,
        textColor: PlatformColor,
        backgroundColor: PlatformColor,
        muted: PlatformColor,
        accent: PlatformColor,
        code: PlatformColor
    ) -> MarkdownEditorTheme {
        let styles: [MarkdownToken.Kind: TokenStyle] = [
            .headingMarker: TokenStyle(color: muted, bold: true),
            .heading: TokenStyle(color: textColor, bold: true),
            .emphasis: TokenStyle(color: muted, italic: true),
            .strong: TokenStyle(color: muted, bold: true),
            .strikethrough: TokenStyle(color: muted, strikethrough: true),
            .inlineCode: TokenStyle(color: code, monospace: true),
            .codeFence: TokenStyle(color: muted, monospace: true),
            .codeBlock: TokenStyle(color: code, monospace: true),
            .listMarker: TokenStyle(color: accent, bold: true),
            .taskMarker: TokenStyle(color: accent),
            .blockquote: TokenStyle(color: muted),
            .thematicBreak: TokenStyle(color: muted),
            .linkText: TokenStyle(color: accent),
            .linkURL: TokenStyle(color: muted)
        ]
        return MarkdownEditorTheme(
            baseFontSize: baseFontSize,
            textColor: textColor,
            backgroundColor: backgroundColor,
            tintColor: accent,
            styles: styles
        )
    }

    /// The default light preset, built from system semantic colors.
    static var light: MarkdownEditorTheme {
        make(
            baseFontSize: 16,
            textColor: .editorLabel,
            backgroundColor: .editorBackground,
            muted: .editorSecondary,
            accent: .editorAccent,
            code: .editorCode
        )
    }

    /// The default dark preset. System semantic colors already adapt, so this
    /// mirrors `.light`; it exists as an explicit hook for dark-only tweaks.
    static var dark: MarkdownEditorTheme { light }
}

extension PlatformColor {
    static var editorLabel: PlatformColor {
        #if canImport(UIKit)
        return .label
        #else
        return .labelColor
        #endif
    }

    static var editorSecondary: PlatformColor {
        #if canImport(UIKit)
        return .secondaryLabel
        #else
        return .secondaryLabelColor
        #endif
    }

    static var editorBackground: PlatformColor {
        #if canImport(UIKit)
        return .systemBackground
        #else
        return .textBackgroundColor
        #endif
    }

    static var editorAccent: PlatformColor { .systemBlue }

    static var editorCode: PlatformColor {
        #if canImport(UIKit)
        return .systemPink
        #else
        return .systemPink
        #endif
    }
}
