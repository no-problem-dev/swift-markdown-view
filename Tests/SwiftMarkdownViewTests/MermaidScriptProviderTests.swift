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

    @Test("既定のバンドルとファイル名")
    func bundledProviderUsesDefaults() {
        let provider = BundledMermaidScriptProvider()
        #expect(provider.bundle == Bundle.main)
        #expect(provider.filename == "mermaid.min")
    }

    @Test("指定したバンドルとファイル名が保持される")
    func bundledProviderUsesSpecifiedValues() {
        let testBundle = Bundle(for: BundleToken.self)
        let provider = BundledMermaidScriptProvider(bundle: testBundle, filename: "custom-mermaid")
        #expect(provider.bundle == testBundle)
        #expect(provider.filename == "custom-mermaid")
    }

    // バンドル欠落時に CDN へ落ちる経路はここでは検証しない。
    // その挙動は「オフライン動作を期待した利用者のアプリから無言で外部通信が飛ぶ」
    // 欠陥として扱うことにし、デバッグビルドでは assertionFailure で停止させている。
    // 次のメジャーで failable / throwing 化して型で表現する予定。

    // MARK: - 既定プロバイダー

    @Test("既定プロバイダーは CDN ベース")
    func defaultProviderIsCDNBased() {
        guard case .url(let url) = defaultMermaidScriptProvider.scriptSource else {
            Issue.record("URL ソースが得られなかった")
            return
        }
        #expect(url.absoluteString.contains("cdn.jsdelivr.net"))
    }
}

// MARK: - Test Helpers

/// テストバンドルを取得するためのトークン。
private final class BundleToken {}
