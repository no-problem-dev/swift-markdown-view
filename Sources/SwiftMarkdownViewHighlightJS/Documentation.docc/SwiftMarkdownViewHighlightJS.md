# ``SwiftMarkdownViewHighlightJS``

HighlightJSを使用した50+言語対応のシンタックスハイライトモジュール。

@Metadata {
    @PageColor(green)
}

## Overview

SwiftMarkdownViewHighlightJSは、SwiftMarkdownViewのオプションモジュールです。
[HighlightSwift](https://github.com/appstefan/HighlightSwift)ライブラリを使用して、
50以上の言語に対応した正確なシンタックスハイライトを提供します。

### 特徴

- **50+言語対応**: Swift、TypeScript、Python、Go、Rust、Java等
- **30+テーマ**: Xcode、GitHub、Atom One、Solarized、Tokyo Night等
- **ライト/ダークモード**: 自動またはマニュアルで切り替え可能
- **アクセシビリティ**: a11yテーマで高コントラスト表示

### クイックスタート

```swift
import SwiftMarkdownView
import SwiftMarkdownViewHighlightJS

// アダプティブハイライト（推奨）
MarkdownView(source)
    .adaptiveSyntaxHighlighting()
```

## Topics

### ハイライター

- ``HighlightJSSyntaxHighlighter``
- ``HighlightJSSyntaxHighlighter/ColorMode``

### テーマプリセット

- ``HighlightJSSyntaxHighlighter/xcodeLight``
- ``HighlightJSSyntaxHighlighter/xcodeDark``
- ``HighlightJSSyntaxHighlighter/githubLight``
- ``HighlightJSSyntaxHighlighter/githubDark``
- ``HighlightJSSyntaxHighlighter/atomOneLight``
- ``HighlightJSSyntaxHighlighter/atomOneDark``
- ``HighlightJSSyntaxHighlighter/a11yLight``
- ``HighlightJSSyntaxHighlighter/a11yDark``

### View拡張

- ``SwiftUICore/View/adaptiveSyntaxHighlighting(theme:)``

## 関連モジュール

このモジュールは**SwiftMarkdownView**（Markdownレンダリングのコアモジュール）と併用して使用します。
