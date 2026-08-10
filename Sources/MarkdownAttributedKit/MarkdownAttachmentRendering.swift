import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// An image rendered for a Markdown attachment, with the metrics that place it against the text baseline.
///
/// The renderer — usually on the main actor — produces the image and never mutates it afterwards, which is
/// what makes the `@unchecked Sendable` conformance safe: a value can cross isolation boundaries on its way
/// into an `NSTextAttachment`.
public struct MarkdownRenderedImage: @unchecked Sendable {
    public var image: PlatformImage
    public var size: CGSize
    /// Vertical offset of the image's bottom edge from the text baseline; a negative value sinks it below.
    ///
    /// Inline math uses this to sit on the same baseline as the surrounding text.
    public var baselineOffset: CGFloat

    public init(image: PlatformImage, size: CGSize, baselineOffset: CGFloat = 0) {
        self.image = image
        self.size = size
        self.baselineOffset = baselineOffset
    }
}

/// Renders the images that back image and math attachments.
///
/// Rendering is synchronous: math typesetting (SwiftLaTeXView/SwiftMath) and local images resolve on the
/// spot while the string is being built. Loading remote images is the view layer's job instead.
///
/// This is the UI-independent abstraction, which is why it lives in this target; concrete renderers live in
/// satellite targets — `SwiftMarkdownViewLaTeX` for math — and are injected. The `Sendable` requirement
/// gives the producing side a concurrency contract to match the `@unchecked Sendable` of the returned
/// ``MarkdownRenderedImage``: the layout pass reaches a renderer across isolation boundaries.
public protocol MarkdownAttachmentRendering: Sendable {
    /// Returns the rendered image for an attachment.
    ///
    /// Returning `nil` falls back to readable text — `[alt]` for an image, `$latex$` for math.
    func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage?
}
