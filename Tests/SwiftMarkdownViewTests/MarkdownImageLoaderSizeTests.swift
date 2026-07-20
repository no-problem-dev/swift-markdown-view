#if os(iOS) || os(macOS)
import Testing
import Foundation
@testable import SwiftMarkdownView

/// リモート画像のサイズ上限が、受信を**打ち切って**守られることの検証。
///
/// 以前は `URLSession.data(for:)` で本文を全部メモリに載せてから大きさを見ていた。
/// 上限を超えた事実は報告できても、メモリはもう使われている。
/// `![x](https://…/2gb.bin)` を描画しようとしただけでメモリを使い切れてしまう。
@Suite("リモート画像のサイズ上限")
struct MarkdownImageLoaderSizeTests {

    /// 応答の大きさを URL のクエリから読むスタブ。
    ///
    /// 設定を static に置くとテストの並列実行で混線する（実際に他のテストの値を拾って落ちた）。
    /// リクエストそのものにパラメータを載せれば、スタブは状態を持たなくて済む。
    ///   - `body`: 実際に返すバイト数
    ///   - `declared`: Content-Length として申告する値。省略で申告なし（詐称の再現）
    final class SizeStubProtocol: URLProtocol, @unchecked Sendable {

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        private func intValue(_ name: String) -> Int? {
            guard let url = request.url,
                  let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                  let raw = items.first(where: { $0.name == name })?.value else { return nil }
            return Int(raw)
        }

        override func startLoading() {
            let body = intValue("body") ?? 0
            let declared = intValue("declared")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: declared.map { ["Content-Length": "\($0)"] } ?? [:]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(repeating: 0x41, count: body))
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SizeStubProtocol.self]
        return URLSession(configuration: config)
    }

    private func isTooLarge(_ result: Result<PlatformImage, MarkdownImageLoader.Failure>) -> Bool {
        if case .failure(.tooLarge) = result { return true }
        return false
    }

    @Test("上限を超える本文は tooLarge になる")
    func oversizedBodyIsRejected() async {
        var policy = MarkdownImagePolicy.default
        policy.maximumRemoteByteCount = 1_024

        let result = await MarkdownImageLoader.load(
            "https://example.com/big.png?body=4096",
            policy: policy,
            session: makeSession()
        )
        #expect(isTooLarge(result))
    }

    @Test("正直な Content-Length は本文を読む前に弾く")
    func honestContentLengthIsRejectedEarly() async {
        var policy = MarkdownImagePolicy.default
        policy.maximumRemoteByteCount = 1_024

        let result = await MarkdownImageLoader.load(
            "https://example.com/lying.png?body=8&declared=999999",
            policy: policy,
            session: makeSession()
        )
        // 本文は 8 バイトしか無いが、申告が上限超えなので読まずに弾く。
        #expect(isTooLarge(result))
    }

    @Test("Content-Length を詐称しても実受信で守られる")
    func spoofedContentLengthIsStillCaught() async {
        var policy = MarkdownImagePolicy.default
        policy.maximumRemoteByteCount = 512

        // 申告なし＝詐称と同じ扱い。実受信で判定するしかない。
        let result = await MarkdownImageLoader.load(
            "https://example.com/spoof.png?body=4096",
            policy: policy,
            session: makeSession()
        )
        #expect(isTooLarge(result))
    }

    @Test("上限内の本文は tooLarge にならない")
    func withinLimitIsNotRejectedForSize() async {
        var policy = MarkdownImagePolicy.default
        policy.maximumRemoteByteCount = 1_024

        let result = await MarkdownImageLoader.load(
            "https://example.com/small.png?body=64&declared=64",
            policy: policy,
            session: makeSession()
        )
        // 中身は画像ではないのでデコードには失敗するが、サイズ判定は通っている。
        #expect(!isTooLarge(result))
    }
}
#endif
