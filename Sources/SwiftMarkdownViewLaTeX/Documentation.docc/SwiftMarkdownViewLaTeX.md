# ``SwiftMarkdownViewLaTeX``

SwiftLaTeXView による `SwiftMarkdownView` の LaTeX 数式組版モジュール。

@Metadata {
    @PageColor(purple)
}

## Overview

`SwiftMarkdownViewLaTeX` は `SwiftMarkdownView` のオプションアドオンで、数式をプレーンなソース表示から本格的な LaTeX 組版にアップグレードする。`LaTeXMathRenderer`（SwiftLaTeXView にレンダリングを委譲する `MathRenderer` 実装）を提供する。SwiftLaTeXView は WebView を使わず、SwiftMath エンジンで LaTeX を直接 Core Text グリフにレンダリングする軽量ラッパーだ。

Markdown ソース内のインライン数式（`$...$`）とディスプレイ数式（`$$...$$`）の両方をサポートする。インライン表現は周囲の `Text` 行内にフローし、ディスプレイ数式は全幅ブロックビューとしてレンダリングされる。`MarkdownView` が使用する TextKit 2 パスでは、ディスプレイ数式はデバイス解像度の画像アタッチメントとしてラスタライズされ、連続テキストビュー内で鮮明に表示される。

数式組版を有効にするには、ターゲットの依存関係に `SwiftMarkdownViewLaTeX` を追加し、レンダラーをビュー階層に注入する:

```swift
import SwiftMarkdownView
import SwiftMarkdownViewLaTeX

MarkdownView("""
The quadratic formula: $ax^2 + bx + c = 0$

$$x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}$$
""")
.mathRenderer(LaTeXMathRenderer())
```

レンダラーのビジュアルスタイル（フォントファミリー・フォントサイズ・テキストカラー）は SwiftUI 環境の `swift-design-system` テーマから導出される。デフォルトを上書きするには、イニシャライザにカスタム `MathStyle` を渡す。

## Topics

### 数式レンダラー

- ``LaTeXMathRenderer``
