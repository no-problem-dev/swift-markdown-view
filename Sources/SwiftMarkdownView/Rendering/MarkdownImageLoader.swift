#if os(iOS) || os(macOS)
import Foundation
import os
import MarkdownAttributedKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Loads a Markdown image source into a platform image.
///
/// The source string comes from the document and is not to be trusted, so only the routes
/// ``MarkdownImagePolicy`` permits are taken. By default that means remote (http/https) URLs and
/// bundle resource names, and never the file system.
enum MarkdownImageLoader {

    /// Why a load failed, as a type, so the caller has to face it rather than swallow it.
    enum Failure: Error {
        /// The route was not one the policy permits.
        case disallowedSource(String)
        /// The remote fetch failed.
        case transport(any Error)
        /// The response ran past the byte limit.
        case tooLarge(byteCount: Int, limit: Int)
        /// The bytes arrived but did not decode as an image.
        case undecodable
    }

    /// - Parameter session: The session to fetch with. This is a seam for tests to inject a
    ///   `URLProtocol`; leave it at the default otherwise. It is passed in rather than held
    ///   globally so there is no shared mutable state.
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
                // data: and custom schemes are not handled.
                return .failure(.disallowedSource(source))
            }
        }

        // No scheme. Resolve it as an app bundle resource name first — the app decides what is
        // in its bundle, so the document has no say there.
        if let bundled = bundledImage(named: source) {
            return .success(bundled)
        }

        // Read it as a bare file path only where the policy says so explicitly.
        guard policy.allowsFileSystemAccess else {
            return .failure(.disallowedSource(source))
        }
        return decode(contentsOfFile: source)
    }

    /// Logs a failure so that a client can find out why an image is missing.
    ///
    /// Swallowing these leaves nothing behind but an image that never appears.
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

    // MARK: - Loading per route

    private static func loadRemote(_ url: URL, policy: MarkdownImagePolicy, session: URLSession) async -> Result<PlatformImage, Failure> {
        var request = URLRequest(url: url)
        request.timeoutInterval = policy.remoteTimeout

        let data: Data
        do {
            // Stop receiving the moment the limit is passed. `data(for:)` puts the whole body in
            // memory before returning, so checking the size afterwards is already too late: a
            // hostile `![x](https://…/2gb.bin)` could exhaust memory just by being drawn.
            // Content-Length can lie, so the decision always rests on bytes actually received.
            let (bytes, response) = try await session.bytes(for: request)

            let limit = policy.maximumRemoteByteCount
            // An honest declaration over the limit ends this without reading a single byte.
            // A dishonest one is still caught by the streaming check below.
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
