#if os(iOS) || os(macOS)
import SwiftUI

/// Markdown ドキュメント中の画像ソースをどこまで信頼するかの方針。
///
/// `![alt](source)` の `source` は**ドキュメントが決める文字列**であり、多くの場合は
/// LLM の出力やユーザー投稿など、アプリが書いたものではない。したがって既定では
/// ローカルファイルシステムへのアクセスを許さない。許すと、描画するだけで
/// `![x](file:///…/Documents/secrets.db)` のような指定がアプリのファイルを読みにいく。
///
/// アプリ自身が用意した画像を差し込みたい場合は、バンドルリソース名での参照が既定で使える
/// （バンドルの中身はアプリが決めるものなので、ドキュメント側に主導権が無い）。
public struct MarkdownImagePolicy: Sendable, Equatable {

    /// http / https の画像を取得するか。
    public var allowsRemoteImages: Bool

    /// `file:` URL および裸のファイルパスを画像として読み込むか。
    ///
    /// ドキュメントが指すパスを無条件に開くことになるため、既定は `false`。
    /// 信頼できるソースの Markdown だけを描画すると分かっている場合にのみ有効にする。
    public var allowsFileSystemAccess: Bool

    /// リモート画像 1 枚あたりの最大バイト数。超えたものは読み込まない。
    public var maximumRemoteByteCount: Int

    /// リモート取得のタイムアウト（秒）。
    public var remoteTimeout: TimeInterval

    public init(
        allowsRemoteImages: Bool = true,
        allowsFileSystemAccess: Bool = false,
        maximumRemoteByteCount: Int = 10 * 1024 * 1024,
        remoteTimeout: TimeInterval = 15
    ) {
        self.allowsRemoteImages = allowsRemoteImages
        self.allowsFileSystemAccess = allowsFileSystemAccess
        self.maximumRemoteByteCount = maximumRemoteByteCount
        self.remoteTimeout = remoteTimeout
    }

    /// 既定。リモート画像とバンドルリソースを許可し、ファイルシステムへのアクセスは許さない。
    public static let `default` = MarkdownImagePolicy()

    /// ネットワークもファイルシステムも使わない。バンドルリソースのみ。
    public static let bundleOnly = MarkdownImagePolicy(
        allowsRemoteImages: false,
        allowsFileSystemAccess: false
    )

    /// ドキュメントを信頼できる場合のみ。ローカルファイルの読み込みを許可する。
    public static let trustedDocument = MarkdownImagePolicy(
        allowsFileSystemAccess: true
    )
}

// MARK: - Environment

private struct MarkdownImagePolicyKey: EnvironmentKey {
    static let defaultValue: MarkdownImagePolicy = .default
}

public extension EnvironmentValues {
    /// Markdown 画像の読み込み方針。
    var markdownImagePolicy: MarkdownImagePolicy {
        get { self[MarkdownImagePolicyKey.self] }
        set { self[MarkdownImagePolicyKey.self] = newValue }
    }
}

public extension View {
    /// Markdown 画像の読み込み方針を設定する。
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownImagePolicy(.bundleOnly)
    /// ```
    func markdownImagePolicy(_ policy: MarkdownImagePolicy) -> some View {
        environment(\.markdownImagePolicy, policy)
    }
}
#endif
