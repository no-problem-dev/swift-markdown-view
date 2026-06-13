import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// An image attachment awaiting its image: the `NSTextAttachment` placeholder
/// the builder emitted for `![alt](source)`, located by its `.markdownAttachment`
/// tag so the view can load `source` and fill `attachment.image` after layout.
public struct MarkdownImageRequest {
    public let range: NSRange
    public let source: String
    public let attachment: NSTextAttachment
}

public enum MarkdownImageAttachments {

    /// All unfilled image attachments in document order.
    public static func requests(in attributed: NSAttributedString) -> [MarkdownImageRequest] {
        var result: [MarkdownImageRequest] = []
        let full = NSRange(location: 0, length: attributed.length)
        attributed.enumerateAttribute(.markdownAttachment, in: full) { value, range, _ in
            guard let markdownAttachment = value as? MarkdownAttachment,
                  case .image(let source, _) = markdownAttachment.kind, !source.isEmpty,
                  let attachment = attributed.attribute(.attachment, at: range.location, effectiveRange: nil) as? NSTextAttachment else {
                return
            }
            result.append(MarkdownImageRequest(range: range, source: source, attachment: attachment))
        }
        return result
    }

    /// Aspect-fit bounds for `image` constrained to `maxWidth` (never upscaled).
    public static func bounds(for image: PlatformImage, maxWidth: CGFloat) -> CGRect {
        let size = image.size
        guard size.width > 0, size.height > 0, maxWidth > 0 else {
            return CGRect(origin: .zero, size: size)
        }
        let scale = min(1, maxWidth / size.width)
        return CGRect(x: 0, y: 0, width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    }
}
