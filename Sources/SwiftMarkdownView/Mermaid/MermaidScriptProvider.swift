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
///     .markdownMermaidScriptProvider(CDNMermaidScriptProvider())
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

// MARK: - Bundled Provider

/// アプリバンドルから読み込む Mermaid スクリプトプロバイダー。
///
/// オフラインで動かす場合に使う。アプリのバンドルに `mermaid.min.js` を含める必要がある
/// （https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js からダウンロードできる）。
///
/// **リソースが見つからない場合は `nil` を返す。** 以前は無言で CDN にフォールバックしており、
/// オフライン動作を期待した利用者のアプリから気づかないまま外部通信が飛んでいた。
/// 生成時に失敗させることで、入れ忘れがコンパイル時の分岐として現れる:
///
/// ```swift
/// // 見つからなければ Mermaid を描画しない
/// if let provider = BundledMermaidScriptProvider() {
///     view.markdownMermaidScriptProvider(provider)
/// }
///
/// // 明示的に CDN へ倒す判断も、利用者が書く
/// let provider = BundledMermaidScriptProvider() ?? CDNMermaidScriptProvider()
/// ```
public struct BundledMermaidScriptProvider: MermaidScriptProvider {

    /// 解決済みの Mermaid.js ファイルの場所。
    public let url: URL

    /// バンドルプロバイダーを生成する。リソースが見つからない場合は `nil`。
    ///
    /// - Parameters:
    ///   - bundle: スクリプトを含むバンドル。デフォルトは `.main`。
    ///   - filename: スクリプトのファイル名（拡張子なし）。デフォルトは "mermaid.min"。
    public init?(bundle: Bundle = .main, filename: String = "mermaid.min") {
        guard let url = bundle.url(forResource: filename, withExtension: "js") else { return nil }
        self.url = url
    }

    public var scriptSource: MermaidScriptSource { .localFile(url) }
}

// MARK: - Default Provider

public extension MermaidScriptProvider where Self == CDNMermaidScriptProvider {

    /// jsDelivr CDN から読み込む既定のプロバイダー。
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownMermaidScriptProvider(.cdn)
    /// ```
    static var cdn: CDNMermaidScriptProvider { CDNMermaidScriptProvider() }
}
