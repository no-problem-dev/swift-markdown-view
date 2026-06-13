#if canImport(UIKit)
import UIKit

/// Cross-platform aliases so the attributed-string builder and the TextKit view
/// are written once. This layer is UIKit/AppKit-aware but **SwiftUI-free**.
public typealias PlatformFont = UIFont
public typealias PlatformColor = UIColor
public typealias PlatformImage = UIImage

#elseif canImport(AppKit)
import AppKit

public typealias PlatformFont = NSFont
public typealias PlatformColor = NSColor
public typealias PlatformImage = NSImage
#endif

#if canImport(UIKit) || canImport(AppKit)
public extension PlatformFont {

    /// Returns this font with bold/italic applied.
    ///
    /// Uses the dedicated system-font constructors rather than descriptor
    /// symbolic traits: the San Francisco system font carries a "UI usage"
    /// attribute that overrides an italic trait applied via the descriptor, so
    /// `withSymbolicTraits(.traitItalic)` silently produces upright text. The
    /// `italicSystemFont`/`boldSystemFont` constructors are reliable.
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

    /// A monospaced font at the given size and weight, for code spans/blocks.
    static func monospaced(size: CGFloat, weight: PlatformFont.Weight = .regular) -> PlatformFont {
        #if canImport(UIKit)
        return UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        #endif
    }

    /// A plain system font at the given size and weight.
    ///
    /// For the regular weight the un-weighted `systemFont(ofSize:)` is used on
    /// purpose: a system font created with an explicit weight does not reliably
    /// round-trip the italic symbolic trait, so `withTraits(italic:)` would
    /// silently fail to produce italics.
    static func system(size: CGFloat, weight: PlatformFont.Weight = .regular) -> PlatformFont {
        #if canImport(UIKit)
        return weight == .regular ? UIFont.systemFont(ofSize: size) : UIFont.systemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        return weight == .regular ? NSFont.systemFont(ofSize: size) : NSFont.systemFont(ofSize: size, weight: weight)
        #endif
    }
}
#endif
