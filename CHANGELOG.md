# Changelog

## [Unreleased]

### 修正

- `MarkdownRenderingOptions.renderMath` を `MarkdownView` が読むようにした。これまで読んでいたのは
  `MathText` だけで、`renderMath: false` を渡してもドキュメント内の数式は組版されていた。
  画像と Mermaid は従来どおり描画される。
- `MarkdownEditor` がテーマの `baseFontSize` を書き換えるのをやめた。環境に置いたテーマの
  フォントサイズがそのまま効く。

### 削除

- `MarkdownEditor` のイニシャライザから `baseFontSize` を外した。本文サイズを決める場所は
  `MarkdownEditorTheme` 一箇所になった。
- `RuleTransform.allowCoalescing` を削除した。どのルールも立てず、どこからも読まれていなかった。
- 属性キー `.markdownSource` を削除した。4 箇所で書かれ、読み手がいなかった。

### 変更

- ツールバーのラベル、モードピッカーの表示名、画像・Mermaid・ハイライト失敗時のログを英語にした。

## [5.0.0] - 2026-08-10

### 変更

- swift-design-system を 3.0.0、swift-latex-view を 0.3.0 へ繰り上げた。
