// 意味モデル（MarkdownContent / MarkdownBlock / MarkdownInline / テーブル・リスト型）は
// UI 非依存の `MarkdownModel` ターゲットにあり、SwiftUI レンダラ・TextKit レンダラ・
// エディタが等しく共有する。第一級のドメイン型なので、`import SwiftMarkdownView` だけで
// 従来どおり使えるよう再輸出する。
@_exported import MarkdownModel

// TextKit レンダリング層。以前はこの再輸出が実装詳細まで丸ごと利用者スコープへ漏らしていた
// （ビルダー・コード領域・画像要求・ブロック装飾・属性キーなど）。それらは `package` に
// 落としたので、ここから見えるのは利用者が実際に触る 4 型だけになった:
//
//   - MarkdownTextTheme          … 解決済みのフォント・カラー・スペーシング
//   - MarkdownAttachment.Kind    … 画像 / 数式 / Mermaid の種別
//   - MarkdownRenderedImage      … アタッチメント画像 + ベースライン配置
//   - MarkdownAttachmentRendering… 自作アタッチメントレンダラの適合先
//
// いずれも `MarkdownAttachmentRendering` のシグネチャに現れるため、利用者が自分で
// 実装するには名前が届いている必要がある。
@_exported import MarkdownAttributedKit
