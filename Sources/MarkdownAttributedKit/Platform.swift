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

    /// Returns this font with bold/italic symbolic traits applied, composing so a
    /// font that is already italic can additionally become bold (bold-italic).
    /// Falls back to `self` when the platform cannot synthesize the variant.
    func withTraits(bold: Bool, italic: Bool) -> PlatformFont {
        guard bold || italic else { return self }
        #if canImport(UIKit)
        var traits = fontDescriptor.symbolicTraits
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
        #elseif canImport(AppKit)
        var traits = fontDescriptor.symbolicTraits
        if bold { traits.insert(.bold) }
        if italic { traits.insert(.italic) }
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
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
    static func system(size: CGFloat, weight: PlatformFont.Weight = .regular) -> PlatformFont {
        #if canImport(UIKit)
        return UIFont.systemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        return NSFont.systemFont(ofSize: size, weight: weight)
        #endif
    }
}
#endif
