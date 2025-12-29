# Aside（コールアウト）

ブロッククォートをNote、Warning、Tipなどのコールアウトとして表示する方法を学びます。

## Overview

SwiftMarkdownViewはMarkdownのブロッククォート（`>`）を解析し、
特定のキーワードで始まる場合はAside（コールアウト）として表示します。
Asideは視覚的に強調された情報ブロックで、補足説明、警告、ヒントなどを表現するのに適しています。

## 基本的な使い方

ブロッククォートの最初の行にキーワードとコロンを記述します：

```swift
MarkdownView("""
> Note: これは補足情報です。

> Warning: 注意が必要な内容です。

> Tip: 便利なヒントです。
""")
```

## 対応キーワード

### よく使うコールアウト

| キーワード | 用途 | アイコン |
|-----------|------|---------|
| `Note` | 補足情報、メモ | 📝 |
| `Tip` | ヒント、アドバイス | 💡 |
| `Important` | 重要な情報 | ❗ |
| `Warning` | 警告、注意事項 | ⚠️ |
| `Experiment` | 実験、試してみること | 🧪 |

### ドキュメント用コールアウト

| キーワード | 用途 |
|-----------|------|
| `Attention` | 注意を引く情報 |
| `Author` / `Authors` | 作成者情報 |
| `Bug` | 既知のバグ |
| `Complexity` | 計算量の情報 |
| `Copyright` | 著作権情報 |
| `Date` | 日付情報 |
| `Invariant` | 不変条件 |
| `MutatingVariant` | 変更を伴うバリアント |
| `NonMutatingVariant` | 変更を伴わないバリアント |
| `Postcondition` | 事後条件 |
| `Precondition` | 事前条件 |
| `Remark` | 備考 |
| `Requires` | 必要条件 |
| `Since` | バージョン情報 |
| `ToDo` | 未実装、今後の対応 |
| `Version` | バージョン |
| `Throws` | スローする例外 |
| `SeeAlso` | 関連情報 |

### カスタムキーワード

定義済みキーワード以外は`custom`として扱われます：

```swift
MarkdownView("""
> MyCustomNote: 独自のコールアウトです。
""")
```

## カスタムスタイル

``AsideStyle``プロトコルに準拠したスタイルを作成することで、
Asideの見た目をカスタマイズできます。

### AsideStyleプロトコル

```swift
public protocol AsideStyle: Sendable {
    func icon(for kind: AsideKind) -> String
    func accentColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color
    func backgroundColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color
    func titleColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color
}
```

### カスタムスタイルの例

```swift
struct MyAsideStyle: AsideStyle {
    func icon(for kind: AsideKind) -> String {
        switch kind {
        case .warning: return "flame.fill"
        case .tip: return "lightbulb.fill"
        case .bug: return "ant.fill"
        default: return DefaultAsideStyle().icon(for: kind)
        }
    }

    func accentColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        switch kind {
        case .tip: return .mint
        case .warning: return .orange
        default: return DefaultAsideStyle().accentColor(for: kind, colorPalette: colorPalette)
        }
    }

    func backgroundColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        accentColor(for: kind, colorPalette: colorPalette).opacity(0.15)
    }

    func titleColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        accentColor(for: kind, colorPalette: colorPalette)
    }
}
```

### スタイルの適用

```swift
MarkdownView(source)
    .asideStyle(MyAsideStyle())
```

## デフォルトスタイル

``DefaultAsideStyle``は以下の特徴を持ちます：

- **アイコン**: SF Symbolsを使用した直感的なアイコン
- **アクセントカラー**: 種類に応じたセマンティックカラー
  - Note: 青系
  - Warning: オレンジ/赤系
  - Tip: 緑系
  - Bug: 赤系
- **背景色**: アクセントカラーの薄い透明版
- **左ボーダー**: アクセントカラーで強調

## ネストされたコンテンツ

Asideは複数行のコンテンツやネストされた要素を含むことができます：

```swift
MarkdownView("""
> Warning: 本番環境での注意事項
>
> 以下の点に注意してください：
>
> - 環境変数の設定
> - データベース接続の確認
> - ログレベルの調整
>
> ```swift
> let config = Config.production
> ```
""")
```

## アクセシビリティ

Asideは以下のアクセシビリティ機能をサポートしています：

- VoiceOverでの種類の読み上げ
- ハイコントラストモードでの視認性確保
- Dynamic Typeへの対応
