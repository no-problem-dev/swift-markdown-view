import Foundation

/// A supplier of the Mermaid.js script used to draw diagrams.
///
/// Implement it to control how Mermaid.js is loaded. Two implementations are built in:
/// - ``CDNMermaidScriptProvider`` loads from a CDN. It is the default and needs a network
///   connection.
/// - ``BundledMermaidScriptProvider`` loads from the app bundle. It works offline at the cost of
///   app size.
///
/// ## A custom provider
/// ```swift
/// struct MyMermaidProvider: MermaidScriptProvider {
///     var scriptSource: MermaidScriptSource {
///         .url(URL(string: "https://my-cdn.com/mermaid.min.js")!)
///     }
/// }
/// ```
public protocol MermaidScriptProvider: Sendable {
    var scriptSource: MermaidScriptSource { get }
}

/// Where the Mermaid.js script comes from.
///
/// A local file is read and embedded inline at render time, because the diagram web view loads
/// from an origin that cannot read a file URL out of a `<script src>` attribute. If the file
/// cannot be read, no diagram is drawn.
public enum MermaidScriptSource: Sendable, Equatable {
    /// Load the script from a URL, such as a CDN or your own server.
    case url(URL)

    /// Embed the given JavaScript directly.
    case inline(String)

    /// Load the script from a file URL on disk.
    case localFile(URL)
}

// MARK: - CDN Provider

/// A provider that loads Mermaid.js from the jsDelivr CDN.
///
/// This is the default provider. It needs a network connection but keeps the app bundle small.
///
/// ```swift
/// MarkdownView(source)
///     .markdownMermaidScriptProvider(CDNMermaidScriptProvider())
/// ```
public struct CDNMermaidScriptProvider: MermaidScriptProvider {

    /// The version written into the CDN path, either a full version or a major-version prefix.
    public let version: String

    /// Creates a CDN provider pinned to the given version.
    ///
    /// - Parameter version: The Mermaid.js version, such as `"11"` or `"10.6.1"`. It defaults to
    ///   `"11"`, which follows the latest release of that major version.
    public init(version: String = "11") {
        self.version = version
    }

    public var scriptSource: MermaidScriptSource {
        let urlString = "https://cdn.jsdelivr.net/npm/mermaid@\(version)/dist/mermaid.min.js"
        guard let url = URL(string: urlString) else {
            // The version made the URL unparsable; fall back to the unversioned CDN path.
            return .url(URL(string: "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js")!)
        }
        return .url(url)
    }
}

// MARK: - Bundled Provider

/// A provider that loads Mermaid.js from the app bundle.
///
/// Use it to run offline. The app bundle must contain `mermaid.min.js`, which you can download
/// from https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js.
///
/// **Initialization returns `nil` when the resource is missing.** It used to fall back to the CDN
/// without saying so, which meant apps that expected offline behavior quietly made network
/// requests. Failing at creation turns a forgotten resource into a branch you write yourself:
///
/// ```swift
/// // Draw no diagrams if the script is missing
/// if let provider = BundledMermaidScriptProvider() {
///     view.markdownMermaidScriptProvider(provider)
/// }
///
/// // Falling back to the CDN is a decision the caller makes explicitly
/// let provider = BundledMermaidScriptProvider() ?? CDNMermaidScriptProvider()
/// ```
public struct BundledMermaidScriptProvider: MermaidScriptProvider {

    /// The location the script resolved to when the provider was created.
    public let url: URL

    /// Creates a bundle provider, or returns `nil` when the resource is not there.
    ///
    /// - Parameters:
    ///   - bundle: The bundle holding the script. Defaults to `.main`.
    ///   - filename: The script's file name without its extension. Defaults to `"mermaid.min"`.
    public init?(bundle: Bundle = .main, filename: String = "mermaid.min") {
        guard let url = bundle.url(forResource: filename, withExtension: "js") else { return nil }
        self.url = url
    }

    public var scriptSource: MermaidScriptSource { .localFile(url) }
}

// MARK: - Default Provider

public extension MermaidScriptProvider where Self == CDNMermaidScriptProvider {

    /// The default provider, which loads from the jsDelivr CDN.
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownMermaidScriptProvider(.cdn)
    /// ```
    static var cdn: CDNMermaidScriptProvider { CDNMermaidScriptProvider() }
}
