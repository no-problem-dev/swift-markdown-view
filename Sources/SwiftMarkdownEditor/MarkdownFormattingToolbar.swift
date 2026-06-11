import SwiftUI
import DesignSystem
import SwiftMarkdownEditorTextKit

/// The formatting bar shown above the source editor.
///
/// Built from design-system `IconButton`s so it inherits the app's theme. Each
/// button calls a command on the ``MarkdownEditorController``, which applies a
/// pure formatting transform to the active text view.
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
