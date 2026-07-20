import SwiftUI
import SwiftMarkdownEditorTextKit

/// ソースエディタ上部に表示されるフォーマットバー。
///
/// 各ボタンは ``MarkdownEditorController`` のコマンドを呼び出し、
/// アクティブなテキストビューに純粋なフォーマット変換を適用する。
struct MarkdownFormattingToolbar: View {

    private enum Metrics {
        static let itemSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 4
        static let iconSize: CGFloat = 15
        static let hitTarget: CGFloat = 28
    }

    @ObservedObject var controller: MarkdownEditorController

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.itemSpacing) {
                group {
                    button("bold", label: "太字", key: "b") { controller.toggleBold() }
                    button("italic", label: "斜体", key: "i") { controller.toggleItalic() }
                    button("strikethrough", label: "取り消し線", key: "x", modifiers: [.command, .shift]) {
                        controller.toggleStrikethrough()
                    }
                    button("curlybraces", label: "インラインコード", key: "e") { controller.toggleInlineCode() }
                }

                Divider().frame(height: 20)

                group {
                    button("number", label: "見出し") { controller.toggleHeading() }
                    button("list.bullet", label: "箇条書き") { controller.toggleBulletList() }
                    button("text.quote", label: "引用") { controller.toggleQuote() }
                    button("link", label: "リンクを挿入", key: "k") { controller.insertLink() }
                }
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.verticalPadding)
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
        let base = Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: Metrics.iconSize))
                .frame(width: Metrics.hitTarget, height: Metrics.hitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)

        if let key {
            base.keyboardShortcut(key, modifiers: modifiers)
        } else {
            base
        }
    }

    @ViewBuilder
    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: Metrics.itemSpacing) { content() }
    }
}
