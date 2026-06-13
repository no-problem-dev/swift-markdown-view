//
//  SelectionShowcaseView.swift
//  MarkdownPlayground
//
//  混在ブロックを1枚に並べ、見出し→段落→リスト→コード→表を横断した
//  連続選択・部分コピー（TextKit 2 バックエンド）を確認するための画面。
//

import SwiftUI
import SwiftMarkdownView
import DesignSystem

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private func readClipboard() -> String {
    #if canImport(UIKit)
    return UIPasteboard.general.string ?? "(空)"
    #elseif canImport(AppKit)
    return NSPasteboard.general.string(forType: .string) ?? "(空)"
    #endif
}

struct SelectionShowcaseView: View {
    @Environment(\.colorPalette) private var colorPalette

    /// 直近にコピーした内容（クリップボード確認用）。
    @State private var clipboard: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("見出し→段落→リスト→コード→表を横断してドラッグ選択し、長押し→コピー。下のボタンでクリップボードの中身を確認できます。")
                    .font(.footnote)
                    .foregroundStyle(colorPalette.onSurfaceVariant)

                MarkdownView(Self.sample)

                Divider()

                Button("クリップボードを確認") {
                    clipboard = readClipboard()
                }
                .buttonStyle(.borderedProminent)

                if !clipboard.isEmpty {
                    Text("コピーされた内容:")
                        .font(.caption)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                    Text(clipboard)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(20)
        }
        .navigationTitle("選択・コピー")
    }

    private static let sample = """
    # 連続選択のデモ

    この段落から下の**表**まで、ブロックを横断して一気に選択できます。*斜体*や \
    `インラインコード`、[リンク](https://example.com) もそのまま選べます。

    ## やること
    1. ここから
    2. ドラッグして
    3. 表の中まで選択

    - 箇条書きも
    - 横断選択の
    - 対象です

    - [x] 完了したタスク
    - [ ] 未完了のタスク

    > 引用ブロックも選択範囲に含められます。
    > 行をまたいでも 1 本の選択になります。

    ```swift
    func greet(_ name: String) -> String {
        "Hello, \\(name)!"
    }
    ```

    ---

    | 言語 | 型付け | 用途 |
    | --- | :---: | --- |
    | Swift | 静的 | アプリ |
    | Python | 動的 | スクリプト |

    最後の段落。ここまで一度の選択でコピーできれば成功です。
    """
}

#Preview {
    NavigationStack {
        SelectionShowcaseView()
            .theme(ThemeProvider())
    }
}
