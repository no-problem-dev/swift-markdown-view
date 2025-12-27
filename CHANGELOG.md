# Changelog

このプロジェクトのすべての注目すべき変更はこのファイルに記録されます。

フォーマットは [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に基づいており、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [未リリース]

<!-- 次のリリースに含める変更をここに追加 -->

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

[未リリース]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.4...HEAD
[1.0.4]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/no-problem-dev/swift-markdown-view/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/no-problem-dev/swift-markdown-view/releases/tag/v1.0.0
