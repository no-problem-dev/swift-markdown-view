import Foundation

/// A protocol that defines how to provide the Mermaid.js script for diagram rendering.
///
/// Implement this protocol to customize how Mermaid.js is loaded.
/// The library provides two built-in implementations:
/// - ``CDNMermaidScriptProvider``: Loads from CDN (default, requires internet)
/// - ``BundledMermaidScriptProvider``: Loads from app bundle (offline, larger app size)
///
/// ## Example: Custom Provider
/// ```swift
/// struct MyMermaidProvider: MermaidScriptProvider {
///     var scriptSource: MermaidScriptSource {
///         .url(URL(string: "https://my-cdn.com/mermaid.min.js")!)
///     }
/// }
/// ```
public protocol MermaidScriptProvider: Sendable {
    /// The source of the Mermaid.js script.
    var scriptSource: MermaidScriptSource { get }
}

/// Represents the source of the Mermaid.js script.
public enum MermaidScriptSource: Sendable, Equatable {
    /// Load script from a URL (CDN or custom server).
    case url(URL)

    /// Load script from inline JavaScript code.
    case inline(String)

    /// Load script from a local file URL.
    case localFile(URL)
}

// MARK: - CDN Provider

/// A Mermaid script provider that loads from jsDelivr CDN.
///
/// This is the default provider. It requires an internet connection
/// but keeps the app bundle size small.
///
/// ```swift
/// MarkdownView(source)
///     .mermaidScriptProvider(CDNMermaidScriptProvider())
/// ```
public struct CDNMermaidScriptProvider: MermaidScriptProvider {

    /// The Mermaid.js version to use.
    public let version: String

    /// Creates a CDN provider with the specified version.
    ///
    /// - Parameter version: The Mermaid.js version. Defaults to "11" (latest major).
    public init(version: String = "11") {
        self.version = version
    }

    public var scriptSource: MermaidScriptSource {
        let urlString = "https://cdn.jsdelivr.net/npm/mermaid@\(version)/dist/mermaid.min.js"
        guard let url = URL(string: urlString) else {
            // Fallback to latest if URL construction fails
            return .url(URL(string: "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js")!)
        }
        return .url(url)
    }
}

// MARK: - Bundled Provider (Placeholder)

/// A Mermaid script provider that loads from the app bundle.
///
/// Use this provider for offline support. You must include `mermaid.min.js`
/// in your app's bundle.
///
/// ```swift
/// MarkdownView(source)
///     .mermaidScriptProvider(BundledMermaidScriptProvider())
/// ```
///
/// - Note: You need to add `mermaid.min.js` to your app target's resources.
///   Download it from https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js
public struct BundledMermaidScriptProvider: MermaidScriptProvider {

    /// The bundle containing the Mermaid.js file.
    public let bundle: Bundle

    /// The filename of the Mermaid.js file.
    public let filename: String

    /// Creates a bundled provider.
    ///
    /// - Parameters:
    ///   - bundle: The bundle containing the script. Defaults to `.main`.
    ///   - filename: The script filename. Defaults to "mermaid.min".
    public init(bundle: Bundle = .main, filename: String = "mermaid.min") {
        self.bundle = bundle
        self.filename = filename
    }

    public var scriptSource: MermaidScriptSource {
        if let url = bundle.url(forResource: filename, withExtension: "js") {
            return .localFile(url)
        }
        // Fallback to CDN if bundle resource not found
        return CDNMermaidScriptProvider().scriptSource
    }
}

// MARK: - Default Provider

/// The default Mermaid script provider (CDN-based).
public let defaultMermaidScriptProvider: any MermaidScriptProvider = CDNMermaidScriptProvider()
