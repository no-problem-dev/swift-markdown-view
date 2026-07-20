import Testing
import Foundation
@testable import SwiftMarkdownView

/// Mermaid スクリプト供給元の検証。
///
/// enum の associated value の往復や合成 `Equatable`、`Sendable` 適合はいずれも
/// 言語側が保証する性質で、実装を定数に置き換えても通ってしまうため検証しない。
/// ここで守るのは「どの URL を組み立てるか」「バンドル指定が保持されるか」という
/// 実装の判断が入る部分だけ。
struct MermaidScriptProviderTests {

    // MARK: - CDNMermaidScriptProvider

    @Test("既定のバージョンは 11")
    func cdnProviderUsesDefaultVersion() {
        #expect(CDNMermaidScriptProvider().version == "11")
    }

    @Test("既定バージョンで jsdelivr の URL を組み立てる")
    func cdnProviderGeneratesCorrectURL() {
        guard case .url(let url) = CDNMermaidScriptProvider(version: "11").scriptSource else {
            Issue.record("URL ソースが得られなかった")
            return
        }
        #expect(url.absoluteString == "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js")
    }

    @Test("指定バージョンが URL に反映される")
    func cdnProviderGeneratesURLWithSpecificVersion() {
        guard case .url(let url) = CDNMermaidScriptProvider(version: "10.6.1").scriptSource else {
            Issue.record("URL ソースが得られなかった")
            return
        }
        #expect(url.absoluteString == "https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js")
    }

    // MARK: - BundledMermaidScriptProvider

    /// 以前はバンドルにスクリプトが無いと無言で CDN にフォールバックしていた。
    /// オフライン動作を期待した利用者のアプリから、気づかないまま外部通信が飛ぶ。
    /// 生成時に失敗させることで、入れ忘れが利用者側の分岐として現れる。
    @Test("リソースが無ければ生成に失敗する。CDN には落ちない")
    func bundledProviderFailsWhenResourceIsMissing() {
        let testBundle = Bundle(for: BundleToken.self)

        #expect(BundledMermaidScriptProvider(bundle: testBundle, filename: "absent-mermaid") == nil)
        #expect(BundledMermaidScriptProvider(bundle: testBundle) == nil)
    }

    @Test("生成できたときはそのファイルを指す")
    func bundledProviderPointsAtResolvedFile() throws {
        let directory = URL.temporaryDirectory.appending(path: "mermaid-bundle-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let script = directory.appending(path: "mermaid.min.js")
        try "/* mermaid */".write(to: script, atomically: true, encoding: .utf8)

        let bundle = try #require(Bundle(url: directory) ?? Bundle(path: directory.path))
        let provider = try #require(BundledMermaidScriptProvider(bundle: bundle))

        #expect(provider.scriptSource == .localFile(provider.url))
        #expect(provider.url.lastPathComponent == "mermaid.min.js")
    }

    // MARK: - 既定プロバイダー

    @Test("既定プロバイダーは CDN ベース")
    func defaultProviderIsCDNBased() {
        guard case .url(let url) = CDNMermaidScriptProvider.cdn.scriptSource else {
            Issue.record("URL ソースが得られなかった")
            return
        }
        #expect(url.absoluteString.contains("cdn.jsdelivr.net"))
    }
}

// MARK: - Test Helpers

/// テストバンドルを取得するためのトークン。
private final class BundleToken {}
