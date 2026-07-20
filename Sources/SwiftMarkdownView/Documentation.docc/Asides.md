# Aside（コールアウト）

ブロッククォートをNote、Warning、Tipなどのコールアウトとして表示する方法を学ぶ。

## Overview

SwiftMarkdownViewはMarkdownのブロッククォート（`>`）を解析し、
特定のキーワードで始まる場合はAside（コールアウト）として表示する。
Asideは視覚的に強調された情報ブロックで、補足説明、警告、ヒントなどを表現するのに適している。

## 基本的な使い方

ブロッククォートの最初の行にキーワードとコロンを記述する：

```swift
MarkdownView("""
> Note: これは補足情報だ。

> Warning: 注意が必要な内容だ。

> Tip: 便利なヒントだ。
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

定義済みキーワード以外は`custom`として扱われる：

```swift
MarkdownView("""
> MyCustomNote: 独自のコールアウトだ。
""")
```

## デフォルトスタイル

既定の Aside 表示は以下の特徴を持つ：

- **アイコン**: SF Symbolsを使用した直感的なアイコン
- **アクセントカラー**: 種類に応じたセマンティックカラー
  - Note: 青系
  - Warning: オレンジ/赤系
  - Tip: 緑系
  - Bug: 赤系
- **背景色**: アクセントカラーの薄い透明版
- **左ボーダー**: アクセントカラーで強調

## ネストされたコンテンツ

Asideは複数行のコンテンツやネストされた要素を含むことができる：

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

Asideは以下のアクセシビリティ機能をサポートしている：

- VoiceOverでの種類の読み上げ
- ハイコントラストモードでの視認性確保
- Dynamic Typeへの対応
