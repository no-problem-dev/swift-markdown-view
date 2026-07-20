import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Markdown アタッチメント用に生成された画像。テキストベースラインを基準とした配置メトリクスを保持し、`NSTextAttachment` として埋め込む際に使用する。
///
/// `@unchecked Sendable`: 画像はレンダラー（多くの場合メインアクター上）が生成し、その後変更されない。そのため、isolation 境界をまたいで安全に受け渡せる。
public struct MarkdownRenderedImage: @unchecked Sendable {
    public var image: PlatformImage
    public var size: CGSize
    /// 画像底辺のテキストベースラインからの垂直オフセット（負値でベースライン下に沈む）。インライン数式の垂直整列に使用する。
    public var baselineOffset: CGFloat

    public init(image: PlatformImage, size: CGSize, baselineOffset: CGFloat = 0) {
        self.image = image
        self.size = size
        self.baselineOffset = baselineOffset
    }
}

/// 画像/数式アタッチメント用の画像をレンダリングするプロトコル。同期的に動作し、数式組版（SwiftLaTeXView/SwiftMath）とローカル画像はビルド時に即座に解決する。リモート画像のロードはビュー層が別途担う。
///
/// UI 非依存の抽象（このターゲットに置く）。具体的なレンダラーはサテライトターゲット（数式は `SwiftMarkdownViewLaTeX`）に置き、注入する。
/// 戻り値の ``MarkdownRenderedImage`` が `@unchecked Sendable` を名乗る一方、
/// 生成側には並行性の契約が無かった。レンダラーはレイアウトパスから
/// isolation 境界をまたいで参照されるため、`Sendable` を要求する。
public protocol MarkdownAttachmentRendering: Sendable {
    /// アタッチメント用のレンダリング済み画像を返す。`nil` を返すと読み取り可能なフォールバックテキスト（`[alt]` / `$latex$`）にフォールバックする。
    func renderedImage(for kind: MarkdownAttachment.Kind, theme: MarkdownTextTheme) -> MarkdownRenderedImage?
}
