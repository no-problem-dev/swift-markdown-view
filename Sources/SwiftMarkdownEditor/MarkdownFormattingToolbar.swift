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
                    IconButton(icon: "bold", size: .small) { controller.bold() }
                    IconButton(icon: "italic", size: .small) { controller.italic() }
                    IconButton(icon: "strikethrough", size: .small) { controller.strikethrough() }
                    IconButton(icon: "curlybraces", size: .small) { controller.code() }
                }

                Divider().frame(height: 20)

                group {
                    IconButton(icon: "number", size: .small) { controller.toggleHeading() }
                    IconButton(icon: "list.bullet", size: .small) { controller.bulletList() }
                    IconButton(icon: "text.quote", size: .small) { controller.toggleQuote() }
                    IconButton(icon: "link", size: .small) { controller.insertLink() }
                }
            }
            .padding(.horizontal, spacing.sm)
            .padding(.vertical, spacing.xs)
        }
    }

    @ViewBuilder
    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: spacing.xs) { content() }
    }
}
