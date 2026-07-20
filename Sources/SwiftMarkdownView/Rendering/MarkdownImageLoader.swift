#if os(iOS) || os(macOS)
import Foundation
import os
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Markdown 画像ソースをプラットフォーム画像に読み込む。
///
/// ソース文字列はドキュメント由来で信頼できないため、``MarkdownImagePolicy`` で
/// 許可された経路だけを使う。既定ではリモート（http/https）とバンドルリソース名のみで、
/// ファイルシステムへのアクセスは行わない。
enum MarkdownImageLoader {

    /// 読み込みに失敗した理由。呼び出し側が握りつぶさずに扱えるよう型で表す。
    enum Failure: Error {
        /// 方針で許可されていない経路だった。
        case disallowedSource(String)
        /// リモート取得が失敗した。
        case transport(any Error)
        /// 応答が上限バイト数を超えた。
        case tooLarge(byteCount: Int, limit: Int)
        /// 取得はできたが画像としてデコードできなかった。
        case undecodable
    }

    /// - Parameter session: 取得に使うセッション。テストが `URLProtocol` を差し込むための seam で、
    ///   通常は既定のまま。グローバルな可変状態を作らないよう引数で渡す。
    static func load(
        _ source: String,
        policy: MarkdownImagePolicy,
        session: URLSession = .shared
    ) async -> Result<PlatformImage, Failure> {
        if let url = URL(string: source), let scheme = url.scheme?.lowercased() {
            switch scheme {
            case "http", "https":
                guard policy.allowsRemoteImages else {
                    return .failure(.disallowedSource(source))
                }
                return await loadRemote(url, policy: policy, session: session)
            case "file":
                guard policy.allowsFileSystemAccess else {
                    return .failure(.disallowedSource(source))
                }
                return decode(contentsOfFile: url.path)
            default:
                // data: や独自スキームは扱わない。
                return .failure(.disallowedSource(source))
            }
        }

        // スキームなしの文字列。まずアプリバンドルのリソース名として解決する
        // （バンドルの中身はアプリが決めるものなので、ドキュメントに主導権が無い）。
        if let bundled = bundledImage(named: source) {
            return .success(bundled)
        }

        // 裸のファイルパスとしての解釈は、方針で明示的に許可された場合のみ。
        guard policy.allowsFileSystemAccess else {
            return .failure(.disallowedSource(source))
        }
        return decode(contentsOfFile: source)
    }

    /// 失敗をログに出す。画像が出ない原因を利用者が追えるようにするためで、
    /// 握りつぶすと「なぜか画像が表示されない」だけが残る。
    static func report(_ failure: Failure, source: String) {
        let reason: String
        switch failure {
        case .disallowedSource:
            reason = """
                画像ソースが MarkdownImagePolicy で許可されていません。\
                ローカルファイルを読み込む場合は .markdownImagePolicy(.trustedDocument) を指定してください。
                """
        case .transport(let error):
            reason = "取得に失敗しました: \(error)"
        case .tooLarge(let byteCount, let limit):
            reason = "サイズ上限を超えています（\(byteCount) > \(limit) バイト）"
        case .undecodable:
            reason = "画像としてデコードできませんでした"
        }
        logger.warning("Markdown 画像を読み込めませんでした [\(source, privacy: .public)]: \(reason, privacy: .public)")
    }

    private static let logger = Logger(
        subsystem: "com.no-problem.swift-markdown-view",
        category: "ImageLoader"
    )

    // MARK: - 経路ごとの読み込み

    private static func loadRemote(_ url: URL, policy: MarkdownImagePolicy, session: URLSession) async -> Result<PlatformImage, Failure> {
        var request = URLRequest(url: url)
        request.timeoutInterval = policy.remoteTimeout

        let data: Data
        do {
            // 上限に達した時点で受信を打ち切る。`data(for:)` は本文を全部メモリに載せてから
            // 返すので、そのあとで大きさを見ても遅い。悪意ある `![x](https://…/2gb.bin)` を
            // 描画しようとしただけでメモリを使い切れてしまう。
            // Content-Length は詐称できるので、判定は常に実受信バイト数で行う。
            let (bytes, response) = try await session.bytes(for: request)

            let limit = policy.maximumRemoteByteCount
            // 申告が正直で上限超えなら、1 バイトも読まずに終わる。
            // 詐称されていてもこの下のストリーミング判定で守られる。
            let declared = response.expectedContentLength
            if declared > 0 && declared > Int64(limit) {
                return .failure(.tooLarge(byteCount: Int(declared), limit: limit))
            }

            var received = Data()
            received.reserveCapacity(Swift.min(limit, 1 << 20))
            for try await byte in bytes {
                received.append(byte)
                if received.count > limit {
                    return .failure(.tooLarge(byteCount: received.count, limit: limit))
                }
            }
            data = received
        } catch {
            return .failure(.transport(error))
        }

        guard let image = PlatformImage(data: data) else {
            return .failure(.undecodable)
        }
        return .success(image)
    }

    private static func decode(contentsOfFile path: String) -> Result<PlatformImage, Failure> {
        guard let image = PlatformImage(contentsOfFile: path) else {
            return .failure(.undecodable)
        }
        return .success(image)
    }

    private static func bundledImage(named name: String) -> PlatformImage? {
        #if canImport(UIKit)
        return UIImage(named: name)
        #elseif canImport(AppKit)
        return NSImage(named: name)
        #else
        return nil
        #endif
    }
}
#endif
