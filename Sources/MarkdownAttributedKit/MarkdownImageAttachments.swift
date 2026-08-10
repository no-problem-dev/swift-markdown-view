import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// An attachment whose image the view still has to load.
///
/// The builder emits an `NSTextAttachment` placeholder for every `![alt](source)` and tags it with
/// `.markdownAttachment`; the view finds it by that tag, loads `source` once layout is done, and fills in
/// `attachment.image`.
package struct MarkdownImageRequest {
    public let range: NSRange
    public let source: String
    public let attachment: NSTextAttachment
}

package enum MarkdownImageAttachments {

    /// Every image attachment with a non-empty source, in document order.
    ///
    /// Attachments whose image a synchronous renderer already supplied are included too — this does not
    /// check whether `attachment.image` is filled in.
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

    /// Bounds that fit the image inside the given maximum width, preserving aspect ratio and never scaling up.
    public static func bounds(for image: PlatformImage, maxWidth: CGFloat) -> CGRect {
        let size = image.size
        guard size.width > 0, size.height > 0, maxWidth > 0 else {
            return CGRect(origin: .zero, size: size)
        }
        let scale = min(1, maxWidth / size.width)
        return CGRect(x: 0, y: 0, width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    }
}
