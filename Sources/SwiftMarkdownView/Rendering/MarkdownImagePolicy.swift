#if os(iOS) || os(macOS)
import SwiftUI

/// How far the image sources in a Markdown document are to be trusted.
///
/// The `source` in `![alt](source)` is **a string the document chooses**, and it is often not one
/// the app wrote — LLM output, user submissions. So the file system is off limits by default:
/// allow it, and merely drawing `![x](file:///…/Documents/secrets.db)` sends the renderer after
/// the app's own files.
///
/// To place images the app itself ships, refer to them by bundle resource name, which works by
/// default — the app decides what is in its bundle, so the document has no say there.
public struct MarkdownImagePolicy: Sendable, Equatable {

    /// Whether http and https images are fetched.
    public var allowsRemoteImages: Bool

    /// Whether `file:` URLs and bare file paths are loaded as images.
    ///
    /// This opens whatever path the document names, so it is `false` by default. Turn it on only
    /// where you know the Markdown being drawn comes from a source you trust.
    public var allowsFileSystemAccess: Bool

    /// The largest a single remote image may be, in bytes.
    ///
    /// The transfer is cut off the moment it runs past this, rather than measured afterwards.
    public var maximumRemoteByteCount: Int

    /// The timeout for a remote fetch, in seconds.
    public var remoteTimeout: TimeInterval

    public init(
        allowsRemoteImages: Bool = true,
        allowsFileSystemAccess: Bool = false,
        maximumRemoteByteCount: Int = 10 * 1024 * 1024,
        remoteTimeout: TimeInterval = 15
    ) {
        self.allowsRemoteImages = allowsRemoteImages
        self.allowsFileSystemAccess = allowsFileSystemAccess
        self.maximumRemoteByteCount = maximumRemoteByteCount
        self.remoteTimeout = remoteTimeout
    }

    /// The default: remote images and bundle resources are allowed, the file system is not.
    public static let `default` = MarkdownImagePolicy()

    /// Bundle resources only — neither the network nor the file system is touched.
    public static let bundleOnly = MarkdownImagePolicy(
        allowsRemoteImages: false,
        allowsFileSystemAccess: false
    )

    /// Allows local files to be read. Use only where the document itself is trusted.
    public static let trustedDocument = MarkdownImagePolicy(
        allowsFileSystemAccess: true
    )
}

// MARK: - Environment

private struct MarkdownImagePolicyKey: EnvironmentKey {
    static let defaultValue: MarkdownImagePolicy = .default
}

public extension EnvironmentValues {
    /// The policy Markdown images are loaded under.
    var markdownImagePolicy: MarkdownImagePolicy {
        get { self[MarkdownImagePolicyKey.self] }
        set { self[MarkdownImagePolicyKey.self] = newValue }
    }
}

public extension View {
    /// Sets the policy Markdown images are loaded under.
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownImagePolicy(.bundleOnly)
    /// ```
    func markdownImagePolicy(_ policy: MarkdownImagePolicy) -> some View {
        environment(\.markdownImagePolicy, policy)
    }
}
#endif
