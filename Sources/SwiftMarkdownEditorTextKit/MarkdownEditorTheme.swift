import Foundation
import CoreGraphics
import SwiftMarkdownEditorCore

/// ソースエディタの外観スタイル：ベースフォント・色と各 ``MarkdownToken/Kind`` の着色設定。
///
/// フレームワーク依存を意図的に最小化（プラットフォームカラー＋フォントサイズ）し、
/// SwiftUI 層がデザインシステムから構築でき、
/// TextKit ブリッジとユニットテストは組み込みの `.light` / `.dark` プリセットを使えるようにする。
public struct MarkdownEditorTheme {

    /// トークンごとのスタイル：色とフォントトレイトのトグル。
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

    /// トークン種別のスタイルを返す。未指定の場合は空のスタイル。
    public func style(for kind: MarkdownToken.Kind) -> TokenStyle {
        styles[kind] ?? TokenStyle()
    }
}

public extension MarkdownEditorTheme {

    /// ベーステキスト色・ミュート色・アクセント色・コード色の 4 役割からトークン着色を導出するテーマを構築する。
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

    /// システムセマンティックカラーから構築したデフォルトのライトプリセット。
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

    /// デフォルトのダークプリセット。システムセマンティックカラーが自動適応するため `.light` と同値。
    /// ダーク専用の調整を加えるための明示的なフックとして存在する。
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
