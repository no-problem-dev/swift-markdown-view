# Changelog

このプロジェクトのすべての注目すべき変更はこのファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース]

<!-- 次のリリースに含める変更をここに追加 -->

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

[未リリース]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.9...HEAD
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
