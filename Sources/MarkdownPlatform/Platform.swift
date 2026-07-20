#if canImport(UIKit)
import UIKit

/// 属性文字列ビルダーと TextKit ビューを一度だけ書くためのクロスプラットフォームエイリアス。
/// UIKit/AppKit に依存するが **SwiftUI-free**。
///
/// このターゲットが唯一の定義場所。以前は `MarkdownAttributedKit` と
/// `SwiftMarkdownEditorTextKit` が同名の public typealias を別々に宣言しており、
/// 両方を import した利用者のスコープで `PlatformColor` / `PlatformFont` が曖昧になった。
public typealias PlatformFont = UIFont
public typealias PlatformColor = UIColor
public typealias PlatformImage = UIImage
public typealias PlatformView = UIView
public typealias PlatformTextView = UITextView

#elseif canImport(AppKit)
import AppKit

public typealias PlatformFont = NSFont
public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
public typealias PlatformView = NSView
public typealias PlatformTextView = NSTextView
#endif

#if canImport(UIKit) || canImport(AppKit)
public extension PlatformFont {

    /// 太字/斜体トレイトを適用したフォントを返す。
    ///
    /// シンボリックトレイトのディスクリプターではなく、専用のシステムフォントコンストラクターを使用する。San Francisco システムフォントは "UI usage" 属性を持ち、ディスクリプター経由で斜体トレイトを指定しても `withSymbolicTraits(.traitItalic)` が無効になる場合がある。`italicSystemFont`/`boldSystemFont` コンストラクターは確実に機能する。
    func withTraits(bold: Bool, italic: Bool) -> PlatformFont {
        guard bold || italic else { return self }
        let size = pointSize
        #if canImport(UIKit)
        let monospaced = fontDescriptor.symbolicTraits.contains(.traitMonoSpace)
        switch (bold, italic) {
        case (false, false):
            return self
        case (true, false):
            return monospaced ? .monospacedSystemFont(ofSize: size, weight: .bold) : .boldSystemFont(ofSize: size)
        case (false, true):
            return .italicSystemFont(ofSize: size)
        case (true, true):
            let italicFont = UIFont.italicSystemFont(ofSize: size)
            if let descriptor = italicFont.fontDescriptor.withSymbolicTraits([.traitItalic, .traitBold]) {
                return UIFont(descriptor: descriptor, size: size)
            }
            return italicFont
        }
        #elseif canImport(AppKit)
        let manager = NSFontManager.shared
        var font = self
        if bold { font = manager.convert(font, toHaveTrait: .boldFontMask) }
        if italic { font = manager.convert(font, toHaveTrait: .italicFontMask) }
        return font
        #endif
    }

    /// コードスパン/ブロック用の等幅フォント。
    static func monospaced(size: CGFloat, weight: PlatformFont.Weight = .regular) -> PlatformFont {
        #if canImport(UIKit)
        return UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        #endif
    }

    /// 指定サイズとウェイトのプレーンシステムフォント。
    ///
    /// ウェイトが `.regular` の場合はウェイト指定なしの `systemFont(ofSize:)` を意図的に使用する。明示ウェイトで生成したシステムフォントは斜体シンボリックトレイトのラウンドトリップが信頼できず、`withTraits(italic:)` が無音で失敗する可能性がある。
    static func system(size: CGFloat, weight: PlatformFont.Weight = .regular) -> PlatformFont {
        #if canImport(UIKit)
        return weight == .regular ? UIFont.systemFont(ofSize: size) : UIFont.systemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        return weight == .regular ? NSFont.systemFont(ofSize: size) : NSFont.systemFont(ofSize: size, weight: weight)
        #endif
    }
}
#endif
