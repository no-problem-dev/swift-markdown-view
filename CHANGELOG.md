# Changelog

このプロジェクトのすべての注目すべき変更はこのファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース]

### 修正

- コードブロックの中身が数式に置換される不具合を修正。`~~~` フェンス・4 スペースの
  インデントコード・`$` が先行する場合のインラインコードスパンが、いずれも数式スキャナの
  保護対象から漏れていた（`~~~python\ncost = $5$\n~~~` の中身が `cost = 0` になっていた）
- CRLF 改行のソースで、行末まで伸びるトークン（見出し本文・コードブロック）の範囲に
  `\r` が 1 コードユニット含まれ、ハイライトが行末まで伸びていたのを修正
- インデントされた閉じフェンス（リスト項目内など）を認識できず、以降のドキュメント全体が
  コードとして着色され続けていたのを修正

### 破壊的変更

- 画像の読み込みに `MarkdownImagePolicy` を導入し、**既定でローカルファイルシステムへの
  アクセスを行わなくなった**。`![alt](source)` の source はドキュメント由来の文字列で、
  LLM 出力やユーザー投稿の場合がある。従来は `file:` URL と裸のファイルパスを無条件に
  開いていたため、描画するだけでアプリのファイルを読みにいく指定が成立していた。
  - 既定（`.default`）: リモート（http/https）とバンドルリソース名のみ
  - `.bundleOnly`: ネットワークも使わない
  - `.trustedDocument`: 従来どおりローカルファイルを許可
  - 設定は `.markdownImagePolicy(_:)` で行う
- あわせてリモート取得にサイズ上限（既定 10 MB）とタイムアウト（既定 15 秒）を追加し、
  失敗を `try?` で握りつぶすのをやめてログに理由を出すようにした
- `BundledMermaidScriptProvider` はバンドルにスクリプトが無い場合、デバッグビルドで
  `assertionFailure` を発生させる。従来は無言で CDN にフォールバックしており、
  オフライン動作を期待した利用者のアプリから気づかないまま外部通信が発生していた

### 変更

- tvOS / watchOS のプラットフォーム宣言を削除。依存パッケージが iOS / macOS しか
  宣言しておらず、実際には解決・ビルドできなかった
- デモ画面を `SwiftMarkdownViewCatalog` として別 product に分離。本体を import しても
  カタログ画面が補完候補に出なくなる

## [3.0.0] - 2026-07-19

依存の世代を繰り上げただけのリリース。ライブラリ自身の API 変更はない。
依存に破壊的変更を含むため major とした。

### 変更

- `swift-design-system` のピンを 1.x から `2.0.1` 以上へ繰り上げ
- `swift-latex-view` のピンを 0.1 系から `0.2.0` 以上へ繰り上げ

### 移行

利用側のコード変更は不要。ただし `swift-design-system` を併用している場合は
2.x へ揃える必要がある（1.x のままでは依存解決が衝突する）。

## [2.0.0] - 2026-07-19

デモ用カタログとレンダリング内部の型を公開 API から外した。
公開面を実際の利用対象だけに絞るのが目的。

### 破壊的変更

- カタログ（デモ画面）の型を internal 化: `MarkdownCatalogCategory` /
  `BlockElementItem` / `InlineElementItem` / `ConfigurationItem` /
  `DesignSystemItem` / `MarkdownCatalogItem` / `MarkdownCatalogRouter` /
  `MarkdownCatalogListView` / `MarkdownCatalogSplitView` / `CategoryItemRow`
- レンダリング内部の定数を internal 化: `MarkdownColors` / `MarkdownSpacing` /
  `MarkdownRadius` / `MarkdownTypographyMapping`
- `MarkdownView.init(_:theme:)` を削除。この初期化子は `theme` 引数を受け取りながら
  何も適用せず `init(_:)` に委譲するだけで、テーマが効かない状態を黙って作っていた

### 変更

- doc コメントと DocC を日本語へ全面リライト、README を英日二本立てに統一

### 移行

- カタログ画面は開発用デモであり、ライブラリの機能ではない。参照していた場合は
  `Examples/MarkdownPlayground` を参考に利用側で実装する
- `MarkdownView(source, theme: provider)` を使っていた場合は
  `MarkdownView(source).theme(provider)` に置き換える。以前は引数が無視されていたため、
  この変更で初めてテーマが実際に適用される点に注意

## [1.4.3] - 2026-06-13

### 追加・改善

- **Mermaid ダイアグラムを新レンダラで表示**。コードブロックのフォールバックから、ライブの `WKWebView` を `NSTextAttachmentViewProvider` で埋め込む方式へ。固定高さ（280pt）のボックス内で**スクロール可能**（大きい図はスクロール、小さい図は収まる）。`.mermaidScriptProvider(_:)`（既定は jsDelivr CDN）で読み込み元を指定可能。
  - 画像ラスタライズ方式（静的・サイズ不定・非スクロール）を避け、ライブビュー方式を採用。コンテンツ幅に追従し、選択は1文字として貫通。

## [1.4.2] - 2026-06-13

### 追加・改善

- **数式（LaTeX）を新レンダラで表示**。`SwiftMarkdownViewLaTeX` の `LaTeXMathRenderer` を `MarkdownAttachmentRendering` にも適合させ、SwiftMath のベクター組版を**高 DPI（デバイススケール）でラスタライズ**して `NSTextAttachment` として埋め込む（通常サイズで十分シャープ）。既存の `.mathRenderer(LaTeXMathRenderer())` がそのまま新レンダラでも効く（`MarkdownView` が環境の math renderer を添付レンダラとして拾う）。インライン数式はベースラインに合わせて配置。
- **コードブロックの上下に余白**を追加し、コード文字が背景ボックスの縁に触れないように（iOS のレイヤー描画・macOS のフラグメント描画の両方）。

### 既知の残課題

- **Mermaid** は現状コードブロックとしてソース表示（ダイアグラム描画は WKWebView のビュー添付が必要で次段）。
- 「Markdown としてコピー」コマンドは未実装（デフォルトのコピーは選択範囲の読めるテキストを返す）。

## [1.4.1] - 2026-06-13

### 修正

- **macOS の表示が空白になる不具合を修正**（v1.4.0 リグレッション）。macOS バックエンドが `NSScrollView` を返していて SwiftUI 上で高さが決まらず潰れていたのを、iOS と同じ **content-sized な非スクロール `NSTextView`**（`intrinsicContentSize` ＋ `sizeThatFits`）へ作り替え。
- **iOS でコードブロック内を選択しても水色のハイライトが見えない不具合を修正**。iOS は選択が `UITextView.selectedRange`（UIKit 側）にあり TextKit2 の `textLayoutManager.textSelections` に来ないため、フラグメントの even-odd くり抜きが空振りして背景塗りが選択を覆っていた。iOS ではコード背景を**テキスト下のレイヤー**に描き、選択はシステム合成に任せる方式へ（macOS は従来どおりフラグメント描画＋くり抜き）。
- **斜体・太字が効かない不具合を修正**。SF システムフォントは記述子の italic トレイトを無視するため、`italicSystemFont`/`boldSystemFont`（macOS は `NSFontManager`）を使う確実な実装へ。
- 非スクロールビューが SwiftUI `ScrollView` 内で高さを失う問題に対し `sizeThatFits` を実装（iOS/macOS）。

### 追加・改善

- **Aside をコールアウト表示に**。`> [!NOTE]`/`[!WARNING]` 等のマーカーを検出・除去し、kind ごとの色付きラベル＋色付き左バーで描画（素の `>` 引用は従来どおり）。
- **画像を `NSTextAttachment` で表示**。`![](…)` をプレースホルダ添付として置き、ビューが非同期ロード（HTTP(S)/ローカル/バンドル）して差し込む。
- **DesignSystem 準拠を強化**。フォントを `Typography` トークン（本文 bodyLarge、見出し headline/title、semibold）、スペーシングを `SpacingScale` から解決。
- Examples の `MarkdownPlayground` を **macOS 対応**にし、横断選択・コピーを確認する「選択・コピー」画面を追加。

## [1.4.0] - 2026-06-13

### 追加

- **TextKit 2 連続選択レンダラ（描画バックエンド刷新）** — `MarkdownView` がブロックを横断した連続テキスト選択・部分コピーに対応（iOS/macOS）。従来はブロックごとに別の SwiftUI `Text` を積層していたため見出し→段落→リストを跨いだ選択が構造的に不可能だったのを、ドキュメント全体を単一の TextKit 2 テキストストレージに描画する方式へ作り変えた。デフォルトのコピーは「選択範囲の読めるテキスト」を返す。
  - 新レイヤー: `MarkdownModel`（UI 非依存の意味モデル＋パーサ。`MarkdownContent`/`MarkdownBlock`/`MarkdownInline` 等を移設し `@_exported`、ソース互換）、`MarkdownAttributedKit`（意味モデル→単一 `NSAttributedString` ビルダー、テーマ `MarkdownTextTheme`、ハイライト/添付の拡張プロトコル）、`MarkdownTextKit`（read-only 選択可能な TextKit 2 ビュー部品とカスタム `NSTextLayoutFragment`）。依存方向は `MarkdownModel → MarkdownAttributedKit → MarkdownTextKit → SwiftMarkdownView`。
  - コードブロックは全幅背景を描画しつつ**選択ハイライトを even-odd でくり抜いて維持**、水平線・引用バー・テーブル罫線もカスタムフラグメントで描画。テーブルはセル文字を実テキストとして保持するため**セル単位選択**が可能で、コピーはタブ区切り。
  - 公開 API 追加: `MarkdownSelectableText`（明示的に選択可能な Markdown ビュー）、`MarkdownTextTheme`、`MarkdownCodeHighlighting` / `MarkdownAttachmentRendering`（注入プロトコル）。
  - 設計の詳細は `Docs/RENDERER_ARCHITECTURE.md` を参照。

### 変更

- iOS/macOS の `MarkdownView` は内部的に SwiftUI `Text` 積層から TextKit 2 単一ストレージ描画へ切り替わった（`import SwiftMarkdownView` の公開 API はソース互換）。tvOS/watchOS は従来の SwiftUI ブロックレンダラを維持。

### 既知の制限

- 新バックエンドでは数式（`SwiftMarkdownViewLaTeX`）と画像が現状フォールバックで `$latex$` / `[alt]` の読めるソーステキストとして表示される（選択・コピーは可能、`.markdownSource` も保持）。`MarkdownAttachmentRendering` への SwiftLaTeXView ラスタライズ結線・リモート画像の非同期ロードは次段。
- 「Markdown としてコピー」コマンド、ページ内検索、ストリーミング最適化、および旧 SwiftUI Text 描画を前提としたスナップショットテストの再録は次段（目視確認後に再録）。

- **Markdown エディタ（Phase 1）** — iPhone/Mac 向けのソース編集機能を新しいレイヤー群として追加。
  - `SwiftMarkdownEditorCore`: UI 非依存のドキュメントモデル（`EditorState` / `TextChange` / 位置写像 / undo 履歴）、Markdown ハイライト用トークナイザ、整形コマンド（純関数）。
  - `SwiftMarkdownEditorRules`: 入力ルール（リスト自動継続・選択ラップ）。
  - `SwiftMarkdownEditorTextKit`: TextKit 2 の `UITextView`/`NSTextView` Representable とライブ・シンタックスハイライト、ツールバー司令塔 `MarkdownEditorController`。
  - `SwiftMarkdownEditor`: 公開 SwiftUI ビュー `MarkdownEditor(text:)`。デザインシステム由来のツールバー、編集/プレビュー/分割モード、プレビューは既存 `MarkdownView` を再利用。
  - iPhone: テキスト下方向スクロールのドラッグでキーボードを閉じられる（`keyboardDismissMode = .interactive`）。
  - モード切替コントロールを等幅化（全幅・最大 420pt で中央寄せ）。「編集／プレビュー」のセグメント幅が揃う。
  - **一体化編集（Live Preview, Phase 2 着手）**: `MarkdownEditor(text:, livePreview: true)` で、インライン記法（`**`/`*`/`` ` ``/`~~`）のマーカーを隠して本文をその場でスタイルし、カーソルがある行だけ生記法を再露出する（Notion / Obsidian Live Preview 型）。生 `.md` が常に真実。実装は権威ある実コード `nodes-app/swift-markdown-engine`（TextKit2）の手法（clear色＋極小フォント＋負kern の conceal、選択変更での reveal）に準拠。属性レベルのユニットテストで検証（シミュレータ不要）。
  - 設計の詳細は `Docs/EDITOR_STRATEGY.md` を参照。

## [1.0.10] - 2026-02-23

### 修正

- **列挙リスト内の太字レンダリング問題を修正**
  - `InlineRenderer` に `bodyFont` パラメータを追加し、全テキスト run に明示的な font 属性を設定
  - SwiftUI の View レベル `.font()` が AttributedString の最初の run を上書きする問題を解消
  - `ParagraphView`, `HeadingView`, `TableCellView` から `.typography()` を除去し、Typography トークンの font を直接渡す方式に変更

### 変更

- **スナップショットテストを SwiftVisualTesting に移行**
  - `swift-snapshot-testing` 直接依存を `swift-visual-testing` に置換
  - 全テストファイルを `@SnapshotSuite` / `@ComponentSnapshot` マクロベースに書き換え
  - テスト設定: iPhone 16、Light/Dark テーマ、日本語のみ
  - 非同期テスト（CodeBlock, Mermaid, Complex）は `VisualTesting.assertComponentSnapshot()` 直接 API を使用
  - 全スナップショットテストファイルに `#if canImport(UIKit)` ガードを追加（macOS ビルド対応）

## [1.0.9] - 2025-01-10

### 修正

- **Package.swift の依存関係を安定版に更新**
  - `swift-tools-version` を 6.0 から 6.2 にアップグレード
  - `swift-markdown` の依存を `branch: main` から安定版 `0.7.3` に変更
  - すべての依存関係を `.upToNextMajor(from:)` 形式で統一
  - これにより、安定版依存を要求するプロジェクトで使用可能になりました

## [1.0.8] - 2025-12-29

### 変更

- **シンタックスハイライトの簡素化**
  - `RegexSyntaxHighlighter` を削除し、`PlainTextHighlighter` をデフォルトに変更
  - シンタックスハイライトを使用する場合は `SwiftMarkdownViewHighlightJS` モジュールを使用
  - API の複雑さを低減し、依存関係を明確化

### ドキュメント

- **README の正確化**
  - 削除済みの機能（RegexSyntaxHighlighter、SyntaxTokenizer）への参照を削除
  - シンタックスハイライトの説明を現在の実装に合わせて更新
  - Mermaid ダイアグラムの動作環境（iOS 26+ 要件）を明記
  - 依存関係に HighlightSwift（オプション）を追記
  - 日本語/英語両方の README を同期更新

- **Documentation.docc の包括的整備**
  - `SyntaxHighlighting.md` を日本語化
  - `MermaidDiagrams.md` を新規作成（日本語）
  - `Asides.md` を新規作成（日本語）
  - `SwiftMarkdownViewHighlightJS` モジュールのドキュメントを新規作成
  - `theme-settings.json` を追加（統一テーマ設定）
  - メインドキュメントにパッケージ構成とモジュール相互参照を追加

- **ワークフロー更新**
  - `docc.yml` に `--enable-experimental-combined-documentation` を追加
  - `SwiftMarkdownViewHighlightJS` ターゲットを追加（複数モジュール統合ドキュメント対応）

### 修正

- `LinkStyle.swift` / `TableStyle.swift` のドキュメントコメント参照を修正

## [1.0.7] - 2025-12-28

### 追加

- **Aside (callout/admonition) サポート**: 注意書きやヒントなどのコールアウト表示
  - `AsideKind`: 24種類の定義済みタイプ（note, warning, tip, important など）+ カスタムタイプ
  - `AsideStyle` プロトコル: カスタマイズ可能なレンダリング
  - `DefaultAsideStyle`: セマンティックなアイコンと色を持つデフォルトスタイル
  - `AsideView`: アイコン、タイトル、コンテンツ、左ボーダーを持つビュー

- **適応型シンタックスハイライト**: ダーク/ライトモード自動対応
  - `adaptiveSyntaxHighlighting()` ビューモディファイア
  - `HighlightJSSyntaxHighlighter.forColorScheme()` ファクトリメソッド

### 変更

- カタログビューの改善
  - `CodeSnippetView` と `MarkdownPreviewCard` で `HighlightedCodeView` を使用
  - `SyntaxHighlighterCatalogView` でハードコードされた色の代わりに `colorPalette` を使用
  - プレビューモディファイアを簡素化（ルートレベルのテーマ適用に依存）

- DesignSystem カタログビューを削除（DesignSystem パッケージに移動）
- `RegexSyntaxHighlighter.fromPalette` メソッドを削除（HighlightJS が主要）

### 破壊的変更

- `MarkdownBlock.blockquote` が `MarkdownBlock.aside(kind:content:)` に置き換え

### テスト

- Asideユニットテスト（20+ケース）
- Asideスナップショットテスト（29ケース）

## [1.0.6] - 2025-12-27

### 追加

- **ダークモード対応**: MarkdownViewがシステムのダーク/ライトモードに対応
  - `ColorSchemeAwareMarkdownTheme`: カラースキーム対応テーマ
  - 自動的な配色切り替え

- **HighlightJS シンタックスハイライト**: より高品質なコードハイライト
  - `HighlightJSView`: HighlightJS ベースのシンタックスハイライトコンポーネント
  - 190以上の言語サポート
  - 複数のテーマ対応

- **サンプルアプリ**: ZennArticleSwiftUI サンプルアプリを追加
  - Zenn記事形式のMarkdownレンダリング例
  - 実装パターンのデモンストレーション

### 改善

- **Mermaidダイアグラム**: スクロールと初期表示を改善
  - ダイアグラムの初期表示位置を最適化
  - スクロール操作の安定性向上

### 修正

- CI: GitHub Pagesへのサブディレクトリデプロイを修正
- CI: スナップショット録画モードのテスト失敗を適切に処理
- CI: Xcode 26.1.1に固定（ローカル環境と一致）
- CI: macos-26ランナーをスナップショットテストに使用
- CI: テスト結果検出のロジックを修正

## [1.0.5] - 2025-12-27

### 追加

- **Mermaidダイアグラム対応**: macOS 26+ SwiftUI WebViewを使用したMermaid.jsレンダリング
  - `MermaidDiagramView`: ネイティブWebViewによるダイアグラム表示
  - `MermaidFallbackView`: 古いOS向けのフォールバック表示
  - `AdaptiveMermaidView`: OSバージョンに応じた自動切り替え
  - `MermaidScriptProvider`: CDN/インライン/ローカルファイルからのスクリプト読み込み
  - フローチャート、シーケンス図、クラス図、状態図などをサポート

- **CI: スナップショットレポートワークフロー**
  - mainブランチへのマージ時に自動実行
  - HTMLギャラリーレポート生成
  - GitHub Pagesへのデプロイ
  - Slack通知（結果サマリー + レポートURL）

### 変更

- **スナップショットテストのリファクタリング**
  - 責務ごとに6ファイルに分割（BlockElement, CodeBlock, InlineElement, Media, ComplexDocument, Mermaid）
  - ファイル名の改善（`snapshotView-_-named.*.png` → `*.1.png`）
  - 非同期スナップショットサポート追加（WebViewコンテンツ用）

### テスト

- 136テスト（+30テスト追加）
- Mermaidパーシングテスト
- MermaidScriptProviderテスト
- Mermaidスナップショットテスト

## [1.0.4] - 2025-12-27

### 修正

- CI: auto-release-on-merge.ymlのHEREDOCインデントを修正

## [1.0.3] - 2025-12-27

### 修正

- CI: スナップショットテストをCIでスキップ（環境間のレンダリング差異による失敗を回避）

## [1.0.2] - 2025-12-27

### 修正

- CI: GitHub Actionsランナーを`macos-15`に変更
- CI: Linuxテストを削除（macOSのみでテスト）
- Package: Swift tools versionを6.0に変更（参考リポジトリに合わせて修正）

## [1.0.1] - 2025-12-27

### 修正

- CI: GitHub Actionsランナーを`macos-26`に変更（Swift 6.2対応）
- CI: Xcode選択に`maxim-lobanov/setup-xcode@v1`アクションを使用（`latest-stable`）
- CI: LinuxテストでSwift 6.2公式Dockerイメージを使用
- CI: 自動リリースワークフローでPR作成前にコミットが存在することを保証

## [1.0.0] - 2025-12-27

### 追加

- MarkdownView: SwiftUIネイティブなMarkdownレンダリングコンポーネント
- ブロック要素サポート: 見出し、段落、コードブロック、リスト、引用、テーブル、水平線、タスクリスト
- インライン要素サポート: テキスト、強調、太字、インラインコード、リンク、画像、取り消し線
- シンタックスハイライト: 15言語対応（Swift, TypeScript, Python, Go, Rust, Java, Kotlin, Ruby, Shell, SQL, HTML, CSS, JSON, YAML）
- DesignSystem統合: ColorPalette, Typography, Spacingとの連携
- 画像サポート: AsyncImageによるリモート画像、ローカルファイル画像
- スナップショットテスト: 24種類のビジュアルテスト
- ユニットテスト: 106テスト

### ドキュメント

- README.md（日本語・英語）
- DocCドキュメント
- RELEASE_PROCESS.md

[未リリース]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.10...HEAD
[1.0.10]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.9...v1.0.10
[1.0.9]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.8...v1.0.9
[1.0.8]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.7...v1.0.8
[1.0.7]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.6...v1.0.7
[1.0.6]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/no-problem-dev/swift-markdown-view/releases/tag/v1.0.0

<!-- Auto-generated on 2025-12-27T03:56:48Z by release workflow -->

<!-- Auto-generated on 2025-12-27T05:11:31Z by release workflow -->

<!-- Auto-generated on 2025-12-27T07:53:44Z by release workflow -->

<!-- Auto-generated on 2025-12-28T02:20:39Z by release workflow -->

<!-- Auto-generated on 2025-12-29T12:24:42Z by release workflow -->

<!-- Auto-generated on 2026-01-10T09:32:28Z by release workflow -->
