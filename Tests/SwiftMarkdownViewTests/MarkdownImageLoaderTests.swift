#if os(iOS) || os(macOS)
import Testing
import Foundation
@testable import SwiftMarkdownView

/// 画像ソースの信頼境界の検証。
///
/// `![alt](source)` の source はドキュメント由来で、LLM 出力やユーザー投稿の場合がある。
/// 既定でローカルファイルを開かないことが、このライブラリの安全性の前提になっている。
@Suite("MarkdownImageLoader の信頼境界")
struct MarkdownImageLoaderTests {

    private func isDisallowed(_ result: Result<PlatformImage, MarkdownImageLoader.Failure>) -> Bool {
        if case .failure(.disallowedSource) = result { return true }
        return false
    }

    @Test("既定では file: URL を読み込まない")
    func defaultPolicyRejectsFileURL() async {
        let result = await MarkdownImageLoader.load(
            "file:///etc/hosts",
            policy: .default
        )
        #expect(isDisallowed(result))
    }

    @Test("既定では裸のファイルパスを読み込まない")
    func defaultPolicyRejectsBarePath() async {
        let result = await MarkdownImageLoader.load(
            "../../../etc/hosts",
            policy: .default
        )
        #expect(isDisallowed(result))
    }

    @Test("既定では絶対パスを読み込まない")
    func defaultPolicyRejectsAbsolutePath() async {
        let result = await MarkdownImageLoader.load("/etc/hosts", policy: .default)
        #expect(isDisallowed(result))
    }

    @Test("未知のスキームは拒否する")
    func rejectsUnknownScheme() async {
        let result = await MarkdownImageLoader.load(
            "data:image/png;base64,iVBORw0KGgo=",
            policy: .default
        )
        #expect(isDisallowed(result))
    }

    @Test("bundleOnly ではリモート画像を取得しない")
    func bundleOnlyRejectsRemote() async {
        let result = await MarkdownImageLoader.load(
            "https://example.com/pixel.png",
            policy: .bundleOnly
        )
        #expect(isDisallowed(result))
    }

    @Test("trustedDocument では file: URL が許可される")
    func trustedDocumentAllowsFileURL() async {
        // 存在しないパスなので undecodable になる。ここで確認したいのは
        // 「方針で弾かれない」ことであって、読み込みの成否ではない。
        let result = await MarkdownImageLoader.load(
            "file:///nonexistent-\(UUID().uuidString).png",
            policy: .trustedDocument
        )
        #expect(isDisallowed(result) == false)
    }

    @Test("既定の方針はファイルシステムを許可していない")
    func defaultPolicyDisallowsFileSystem() {
        #expect(MarkdownImagePolicy.default.allowsFileSystemAccess == false)
        #expect(MarkdownImagePolicy.default.allowsRemoteImages)
    }
}
#endif
