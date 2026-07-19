// README.md / README.ja.md に載せているコード例をそのまま置き、コンパイルを通すことで
// 例の腐敗を防ぐ。README の例は「動かないまま公開されていた」実績があるため
// （テーマの例が `any ColorPalette` に存在しない `.dark` を参照していた）、
// 例を変更したらこのファイルも同じ形に更新すること。
//
// ここに実行時アサーションは置かない。守りたいのは「例が現在の公開 API で書けること」だけ。

import SwiftUI
import DesignSystem
import SwiftMarkdownView

// README: Quick Start
private struct QuickStartExample: View {
    var body: some View {
        MarkdownView("""
        # Hello, Markdown!

        This is a **bold** and *italic* text.

        - [x] Task completed
        - [ ] Task pending
        """)
    }
}

// README: DesignSystem Theme（テーマ全体の適用）
private struct ThemeProviderExample: View {
    @State private var theme = ThemeProvider(initialMode: .dark)

    var body: some View {
        MarkdownView("# Themed Markdown")
            .theme(theme)
    }
}

// README: DesignSystem Theme（単一トークンの差し替え）
private struct SingleTokenOverrideExample: View {
    var body: some View {
        MarkdownView("# Themed Markdown")
            .environment(\.colorPalette, DarkColorPalette())
    }
}
