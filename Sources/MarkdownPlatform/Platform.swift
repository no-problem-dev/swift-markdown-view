#if canImport(UIKit)
import UIKit

/// Cross-platform aliases that let attributed string builders and TextKit views be written once.
///
/// They depend on UIKit or AppKit, but never on SwiftUI.
///
/// This target is the one place these names are declared. `MarkdownAttributedKit` and
/// `SwiftMarkdownEditorTextKit` used to each declare their own public typealiases under the same
/// names, which made `PlatformColor` and `PlatformFont` ambiguous in the scope of anyone
/// importing both.
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

    /// Returns the font with bold and italic traits applied.
    ///
    /// On UIKit the italic and bold faces come from the dedicated system font constructors rather than from a symbolic trait descriptor. The San Francisco system font carries a "UI usage" attribute that can leave `withSymbolicTraits(.traitItalic)` with no effect when italic is requested through a descriptor, while `italicSystemFont` and `boldSystemFont` are reliable. On AppKit the traits are applied through `NSFontManager`.
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

    /// A monospaced font, for code spans and code blocks.
    static func monospaced(size: CGFloat, weight: PlatformFont.Weight = .regular) -> PlatformFont {
        #if canImport(UIKit)
        return UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        #endif
    }

    /// A plain system font at the given size and weight.
    ///
    /// A `.regular` weight deliberately goes through `systemFont(ofSize:)` with no weight argument. A system font created with an explicit weight does not round-trip the italic symbolic trait reliably, and `withTraits(bold:italic:)` can then fail silently.
    static func system(size: CGFloat, weight: PlatformFont.Weight = .regular) -> PlatformFont {
        #if canImport(UIKit)
        return weight == .regular ? UIFont.systemFont(ofSize: size) : UIFont.systemFont(ofSize: size, weight: weight)
        #elseif canImport(AppKit)
        return weight == .regular ? NSFont.systemFont(ofSize: size) : NSFont.systemFont(ofSize: size, weight: weight)
        #endif
    }
}
#endif
