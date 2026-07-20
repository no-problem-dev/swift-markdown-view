import SwiftUI
import DesignSystem
import SwiftMarkdownEditorTextKit

/// ソースエディタ上部に表示されるフォーマットバー。
///
/// デザインシステムの `IconButton` で構築されアプリテーマを継承する。
/// 各ボタンは ``MarkdownEditorController`` のコマンドを呼び出し、
/// アクティブなテキストビューに純粋なフォーマット変換を適用する。
struct MarkdownFormattingToolbar: View {

    @ObservedObject var controller: MarkdownEditorController
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing.xs) {
                group {
                    button("bold", label: "太字", key: "b") { controller.bold() }
                    button("italic", label: "斜体", key: "i") { controller.italic() }
                    button("strikethrough", label: "取り消し線", key: "x", modifiers: [.command, .shift]) {
                        controller.strikethrough()
                    }
                    button("curlybraces", label: "インラインコード", key: "e") { controller.code() }
                }

                Divider().frame(height: 20)

                group {
                    button("number", label: "見出し") { controller.toggleHeading() }
                    button("list.bullet", label: "箇条書き") { controller.bulletList() }
                    button("text.quote", label: "引用") { controller.toggleQuote() }
                    button("link", label: "リンクを挿入", key: "k") { controller.insertLink() }
                }
            }
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
        }
    }

    /// アイコンだけのボタンにラベルとショートカットを与える。
    ///
    /// - アイコンには読み上げ名が無いので、`accessibilityLabel` を必ず付ける。
    ///   付けないと VoiceOver では 8 個のボタンが区別できない。
    /// - ショートカットはツールバー側に置く。テキストビューを継承しなくても、
    ///   ハードウェアキーボードのある iPad と macOS の両方で効く。
    @ViewBuilder
    private func button(
        _ icon: String,
        label: String,
        key: KeyEquivalent? = nil,
        modifiers: EventModifiers = .command,
        action: @escaping () -> Void
    ) -> some View {
        let base = IconButton(icon: icon, size: .small, action: action)
            .accessibilityLabel(label)
        if let key {
            base.keyboardShortcut(key, modifiers: modifiers)
        } else {
            base
        }
    }

    @ViewBuilder
    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: spacing.xs) { content() }
    }
}
