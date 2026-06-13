import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// An image produced for a Markdown attachment, with the metrics needed to place
/// it as an `NSTextAttachment` (its bounds relative to the text baseline).
///
/// `@unchecked Sendable`: the image is created (often on the main actor by the
/// renderer) and never mutated afterwards, so it is safe to hand back across
/// isolation boundaries.
public struct MarkdownRenderedImage: @unchecked Sendable {
    public var image: PlatformImage
    public var size: CGSize
    /// Vertical offset of the image's bottom from the text baseline (negative
    /// drops it below the baseline). Used for inline math alignment.
    public var baselineOffset: CGFloat

    public init(image: PlatformImage, size: CGSize, baselineOffset: CGFloat = 0) {
        self.image = image
        self.size = size
        self.baselineOffset = baselineOffset
    }
}

/// Renders an image for an image/math attachment. Synchronous: math typesetting
/// (SwiftLaTeXView/SwiftMath) and locally available images resolve immediately at
/// build time. Remote image loading is layered on separately by the view.
///
/// UI-free abstraction (lives here); concrete renderers live in the satellite
/// targets (`SwiftMarkdownViewLaTeX` for math) and are injected.
public protocol MarkdownAttachmentRendering {
    /// Returns a rendered image for the attachment, or `nil` to fall back to
    /// readable text (`[alt]` / `$latex$`).
    func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage?
}
