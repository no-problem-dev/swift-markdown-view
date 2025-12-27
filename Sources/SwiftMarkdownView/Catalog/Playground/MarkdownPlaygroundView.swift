import SwiftUI
import DesignSystem

/// Interactive playground for Markdown editing and preview.
public struct MarkdownPlaygroundView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var markdownSource: String = Self.defaultMarkdown
    @State private var showSource = true
    @State private var showPreview = true
    @State private var selectedPreset: PresetOption = .custom

    private enum PresetOption: String, CaseIterable {
        case custom = "カスタム"
        case headings = "見出し"
        case lists = "リスト"
        case codeBlocks = "コードブロック"
        case tables = "テーブル"
        case asides = "Aside"
        case mermaid = "Mermaid"
        case comprehensive = "総合"
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Content
            if horizontalSizeClass == .regular {
                // Side by side layout
                HStack(spacing: 0) {
                    if showSource {
                        editorPane
                        if showPreview {
                            Divider()
                        }
                    }
                    if showPreview {
                        previewPane
                    }
                }
            } else {
                // Stacked layout
                if showSource && showPreview {
                    VStack(spacing: 0) {
                        editorPane
                            .frame(maxHeight: .infinity)
                        Divider()
                        previewPane
                            .frame(maxHeight: .infinity)
                    }
                } else if showSource {
                    editorPane
                } else {
                    previewPane
                }
            }
        }
        .background(colorPalette.background)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing.md) {
                // View toggles
                HStack(spacing: spacing.sm) {
                    toolbarButton(
                        icon: "doc.text",
                        label: "ソース",
                        isActive: showSource
                    ) {
                        withAnimation { showSource.toggle() }
                    }

                    toolbarButton(
                        icon: "eye",
                        label: "プレビュー",
                        isActive: showPreview
                    ) {
                        withAnimation { showPreview.toggle() }
                    }
                }

                Divider()
                    .frame(height: 24)

                // Preset picker
                Menu {
                    ForEach(PresetOption.allCases, id: \.self) { preset in
                        Button(preset.rawValue) {
                            selectedPreset = preset
                            markdownSource = markdown(for: preset)
                        }
                    }
                } label: {
                    HStack(spacing: spacing.xs) {
                        Image(systemName: "doc.on.doc")
                        Text("プリセット")
                            .typography(.labelMedium)
                    }
                    .padding(.horizontal, spacing.sm)
                    .padding(.vertical, spacing.xs)
                    .background(colorPalette.surfaceVariant)
                    .clipShape(Capsule())
                }

                Spacer()

                // Clear button
                Button {
                    markdownSource = ""
                    selectedPreset = .custom
                } label: {
                    HStack(spacing: spacing.xs) {
                        Image(systemName: "trash")
                        Text("クリア")
                            .typography(.labelMedium)
                    }
                    .foregroundStyle(colorPalette.error)
                    .padding(.horizontal, spacing.sm)
                    .padding(.vertical, spacing.xs)
                }
            }
            .padding(.horizontal, spacing.md)
            .padding(.vertical, spacing.sm)
        }
        .background(colorPalette.surface)
    }

    @ViewBuilder
    private func toolbarButton(
        icon: String,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: spacing.xs) {
                Image(systemName: icon)
                Text(label)
                    .typography(.labelMedium)
            }
            .foregroundStyle(isActive ? colorPalette.onPrimary : colorPalette.onSurface)
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
            .background(isActive ? colorPalette.primary : colorPalette.surfaceVariant)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Editor Pane

    private var editorPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(colorPalette.primary)
                Text("Markdownソース")
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
                Spacer()
                Text("\(markdownSource.count) 文字")
                    .typography(.labelSmall)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
            }
            .padding(.horizontal, spacing.md)
            .padding(.vertical, spacing.sm)
            .background(colorPalette.surfaceVariant.opacity(0.5))

            // Editor
            TextEditor(text: $markdownSource)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(spacing.md)
                .background(colorPalette.surface)
                .onChange(of: markdownSource) { _, _ in
                    selectedPreset = .custom
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Preview Pane

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "eye")
                    .foregroundStyle(colorPalette.primary)
                Text("レンダリング結果")
                    .typography(.labelMedium)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
                Spacer()
            }
            .padding(.horizontal, spacing.md)
            .padding(.vertical, spacing.sm)
            .background(colorPalette.surfaceVariant.opacity(0.5))

            // Preview
            ScrollView {
                if markdownSource.isEmpty {
                    emptyState
                } else {
                    MarkdownView(markdownSource)
                        .padding(spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(colorPalette.surface)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: spacing.md) {
            Image(systemName: "text.alignleft")
                .typography(.displayMedium)
                .foregroundStyle(colorPalette.onSurfaceVariant.opacity(0.5))

            Text("Markdownを入力してください")
                .typography(.bodyMedium)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(spacing.xl)
    }

    // MARK: - Preset Markdown

    private func markdown(for preset: PresetOption) -> String {
        switch preset {
        case .custom:
            return markdownSource
        case .headings:
            return Self.headingsMarkdown
        case .lists:
            return Self.listsMarkdown
        case .codeBlocks:
            return Self.codeBlocksMarkdown
        case .tables:
            return Self.tablesMarkdown
        case .asides:
            return Self.asidesMarkdown
        case .mermaid:
            return Self.mermaidMarkdown
        case .comprehensive:
            return Self.defaultMarkdown
        }
    }

    // MARK: - Preset Content

    private static let defaultMarkdown = """
    # SwiftMarkdownView プレイグラウンド

    このプレイグラウンドでは、Markdownのレンダリングをリアルタイムで確認できます。

    ## 基本的なテキストスタイル

    **太字**、*斜体*、~~取り消し線~~、`インラインコード`をサポートしています。

    ## リスト

    - 順序なしリスト項目1
    - 順序なしリスト項目2
      - ネストされた項目

    1. 順序付きリスト項目1
    2. 順序付きリスト項目2

    - [x] 完了したタスク
    - [ ] 未完了のタスク

    ## コードブロック

    ```swift
    struct Greeting {
        let message: String

        func display() {
            print(message)
        }
    }
    ```

    ## Aside

    > [!NOTE]
    > これは補足情報です。

    ## テーブル

    | 名前 | 説明 |
    |------|------|
    | Swift | プログラミング言語 |
    | SwiftUI | UIフレームワーク |

    ## リンクと画像

    [Apple](https://www.apple.com) を訪問してください。

    ---

    *プレイグラウンドで自由に編集してみてください！*
    """

    private static let headingsMarkdown = """
    # 見出し1 (H1)

    これは見出し1の後の本文です。

    ## 見出し2 (H2)

    これは見出し2の後の本文です。

    ### 見出し3 (H3)

    これは見出し3の後の本文です。

    #### 見出し4 (H4)

    これは見出し4の後の本文です。

    ##### 見出し5 (H5)

    これは見出し5の後の本文です。

    ###### 見出し6 (H6)

    これは見出し6の後の本文です。
    """

    private static let listsMarkdown = """
    # リストのサンプル

    ## 順序なしリスト

    - 項目1
    - 項目2
    - 項目3
      - ネスト項目1
      - ネスト項目2
        - さらにネスト

    ## 順序付きリスト

    1. 最初の項目
    2. 二番目の項目
    3. 三番目の項目
       1. ネスト番号1
       2. ネスト番号2

    ## タスクリスト

    - [x] 完了したタスク
    - [x] これも完了
    - [ ] 未完了のタスク
    - [ ] 作業中のタスク
    """

    private static let codeBlocksMarkdown = """
    # コードブロックのサンプル

    ## Swift

    ```swift
    import SwiftUI

    struct ContentView: View {
        @State private var count = 0

        var body: some View {
            VStack {
                Text("Count: \\(count)")
                Button("Increment") {
                    count += 1
                }
            }
        }
    }
    ```

    ## Python

    ```python
    def greet(name: str) -> str:
        return f"Hello, {name}!"

    if __name__ == "__main__":
        print(greet("World"))
    ```

    ## JavaScript

    ```javascript
    const fetchData = async (url) => {
        const response = await fetch(url);
        return response.json();
    };
    ```

    ## インラインコード

    変数 `userName` を使用して、`print(userName)` で出力します。
    """

    private static let tablesMarkdown = """
    # テーブルのサンプル

    ## シンプルなテーブル

    | 名前 | 年齢 | 職業 |
    |------|------|------|
    | 田中 | 30 | エンジニア |
    | 佐藤 | 25 | デザイナー |
    | 鈴木 | 35 | マネージャー |

    ## 配置を指定したテーブル

    | 左揃え | 中央揃え | 右揃え |
    |:-------|:--------:|-------:|
    | Left | Center | Right |
    | 1234 | 5678 | 9012 |
    | ABC | DEF | GHI |

    ## 複雑なテーブル

    | 機能 | iOS | macOS | 備考 |
    |------|:---:|:-----:|------|
    | SwiftUI | ✓ | ✓ | 推奨 |
    | UIKit | ✓ | - | レガシー |
    | AppKit | - | ✓ | macOS専用 |
    """

    private static let asidesMarkdown = """
    # Asideのサンプル

    ## Note（補足）

    > [!NOTE]
    > これは補足情報です。追加の説明や参考情報を記載します。

    ## Tip（ヒント）

    > [!TIP]
    > これは便利なヒントです。効率的な方法やベストプラクティスを共有します。

    ## Important（重要）

    > [!IMPORTANT]
    > これは重要な情報です。見落としてはいけない重要事項を強調します。

    ## Warning（警告）

    > [!WARNING]
    > これは警告です。注意が必要な事項や潜在的な問題を示します。

    ## Caution（注意）

    > [!CAUTION]
    > これは注意喚起です。危険や重大な影響を及ぼす可能性がある事項を示します。
    """

    private static let mermaidMarkdown = """
    # Mermaidダイアグラムのサンプル

    ## フローチャート

    ```mermaid
    graph TD
        A[開始] --> B{条件}
        B -->|Yes| C[処理1]
        B -->|No| D[処理2]
        C --> E[終了]
        D --> E
    ```

    ## シーケンス図

    ```mermaid
    sequenceDiagram
        participant User
        participant App
        participant Server

        User->>App: リクエスト
        App->>Server: API呼び出し
        Server-->>App: レスポンス
        App-->>User: 結果表示
    ```

    ## クラス図

    ```mermaid
    classDiagram
        class Animal {
            +String name
            +int age
            +makeSound()
        }
        class Dog {
            +bark()
        }
        class Cat {
            +meow()
        }
        Animal <|-- Dog
        Animal <|-- Cat
    ```
    """
}

#Preview {
    NavigationStack {
        MarkdownPlaygroundView()
            .navigationTitle("プレイグラウンド")
    }
    .theme(ThemeProvider())
}
