import Foundation

/// ダイアグラムレンダリング向けに Mermaid.js スクリプトの提供方法を定義するプロトコル。
///
/// このプロトコルを実装して Mermaid.js の読み込み方法をカスタマイズする。
/// ライブラリは 2 つのビルトイン実装を提供する:
/// - ``CDNMermaidScriptProvider``: CDN から読み込む（デフォルト、インターネット接続が必要）
/// - ``BundledMermaidScriptProvider``: アプリバンドルから読み込む（オフライン対応、アプリサイズが増加）
///
/// ## カスタムプロバイダーの例
/// ```swift
/// struct MyMermaidProvider: MermaidScriptProvider {
///     var scriptSource: MermaidScriptSource {
///         .url(URL(string: "https://my-cdn.com/mermaid.min.js")!)
///     }
/// }
/// ```
public protocol MermaidScriptProvider: Sendable {
    /// Mermaid.js スクリプトのソース。
    var scriptSource: MermaidScriptSource { get }
}

/// Mermaid.js スクリプトのソースを表す。
public enum MermaidScriptSource: Sendable, Equatable {
    /// URL（CDN またはカスタムサーバー）からスクリプトを読み込む。
    case url(URL)

    /// インライン JavaScript コードからスクリプトを読み込む。
    case inline(String)

    /// ローカルファイル URL からスクリプトを読み込む。
    case localFile(URL)
}

// MARK: - CDN Provider

/// jsDelivr CDN から読み込む Mermaid スクリプトプロバイダー。
///
/// デフォルトプロバイダー。インターネット接続が必要だが、アプリバンドルサイズを小さく保つ。
///
/// ```swift
/// MarkdownView(source)
///     .mermaidScriptProvider(CDNMermaidScriptProvider())
/// ```
public struct CDNMermaidScriptProvider: MermaidScriptProvider {

    /// 使用する Mermaid.js のバージョン。
    public let version: String

    /// 指定したバージョンの CDN プロバイダーを生成する。
    ///
    /// - Parameter version: Mermaid.js のバージョン。デフォルトは "11"（最新メジャー）。
    public init(version: String = "11") {
        self.version = version
    }

    public var scriptSource: MermaidScriptSource {
        let urlString = "https://cdn.jsdelivr.net/npm/mermaid@\(version)/dist/mermaid.min.js"
        guard let url = URL(string: urlString) else {
            // URL 構築失敗時は最新版にフォールバック
            return .url(URL(string: "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js")!)
        }
        return .url(url)
    }
}

// MARK: - Bundled Provider (Placeholder)

/// アプリバンドルから読み込む Mermaid スクリプトプロバイダー。
///
/// オフラインサポートにはこのプロバイダーを使用する。アプリのバンドルに `mermaid.min.js` を
/// 含める必要がある。
///
/// ```swift
/// MarkdownView(source)
///     .mermaidScriptProvider(BundledMermaidScriptProvider())
/// ```
///
/// - Note: アプリターゲットのリソースに `mermaid.min.js` を追加する必要がある。
///   https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js からダウンロードできる。
public struct BundledMermaidScriptProvider: MermaidScriptProvider {

    /// Mermaid.js ファイルを含むバンドル。
    public let bundle: Bundle

    /// Mermaid.js ファイルのファイル名。
    public let filename: String

    /// バンドルプロバイダーを生成する。
    ///
    /// - Parameters:
    ///   - bundle: スクリプトを含むバンドル。デフォルトは `.main`。
    ///   - filename: スクリプトのファイル名。デフォルトは "mermaid.min"。
    public init(bundle: Bundle = .main, filename: String = "mermaid.min") {
        self.bundle = bundle
        self.filename = filename
    }

    public var scriptSource: MermaidScriptSource {
        if let url = bundle.url(forResource: filename, withExtension: "js") {
            return .localFile(url)
        }
        // バンドルリソースが見つからない場合は CDN にフォールバック
        return CDNMermaidScriptProvider().scriptSource
    }
}

// MARK: - Default Provider

/// デフォルトの Mermaid スクリプトプロバイダー（CDN ベース）。
public let defaultMermaidScriptProvider: any MermaidScriptProvider = CDNMermaidScriptProvider()
