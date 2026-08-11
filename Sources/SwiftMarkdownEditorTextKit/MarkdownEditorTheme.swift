import Foundation
import CoreGraphics
import SwiftMarkdownEditorCore

/// The appearance of the source editor: a base font size, the editor colors, and a style per token kind.
///
/// The type deliberately depends on nothing beyond platform colors and a font size, so a SwiftUI
/// layer can build one from its own design system while the TextKit bridge and the unit tests use
/// the built-in ``light`` and ``dark`` presets.
public struct MarkdownEditorTheme {

    /// The color and font traits applied to one kind of syntax token.
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

    /// The point size of unstyled body text.
    ///
    /// Heading sizes are scaled from it. This is the one place the editor's body text size is
    /// set, whether the theme drives ``MarkdownSourceTextView`` directly or arrives at
    /// `MarkdownEditor` through the environment.
    public var baseFontSize: CGFloat

    /// The foreground color of the whole document, showing through wherever a token style defines no
    /// color of its own.
    public var textColor: PlatformColor

    /// The background color of the text view.
    public var backgroundColor: PlatformColor

    /// The color of the caret and the selection.
    public var tintColor: PlatformColor

    /// The style applied to each kind of syntax token. Kinds absent here render with no styling.
    ///
    /// Honored in full only while live preview is off. Live preview derives its font traits from the
    /// document structure instead and reads just two entries from here: the heading color and the
    /// inline code color.
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

    /// The style for a token kind, or an all-default style when the theme defines none.
    public func style(for kind: MarkdownToken.Kind) -> TokenStyle {
        styles[kind] ?? TokenStyle()
    }
}

public extension MarkdownEditorTheme {

    /// Builds a theme by deriving a style for every token kind from four color roles.
    ///
    /// - Parameters:
    ///   - baseFontSize: The point size of unstyled body text, which heading sizes scale from.
    ///   - textColor: The color of body text, and of heading text.
    ///   - backgroundColor: The background color of the text view.
    ///   - muted: The color of markers and delimiters: heading hashes, emphasis and strong runs,
    ///     strikethrough runs, code fences, quote markers, thematic breaks, and link URLs.
    ///   - accent: The color of list markers, task checkboxes, and link text. It also becomes the
    ///     caret and selection color.
    ///   - code: The color of inline code and of the contents of fenced code blocks.
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

    /// The default light preset, built from the system's semantic colors.
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

    /// The default dark preset.
    ///
    /// Identical to ``light``, because the system semantic colors both are built from already adapt
    /// to the interface style. It exists as a named hook for dark-only adjustments.
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
