import SwiftUI
import SwiftMarkdownEditorTextKit

/// The formatting bar shown above the source editor.
///
/// Items are given as an array of ``MarkdownEditorToolbarItem``. Each button receives
/// a `MarkdownEditorController` and applies its transform to the bound text view.
///
/// Use it directly to pair the bar with a mode switcher of your own:
///
/// ```swift
/// MarkdownFormattingToolbar(controller: controller, items: .standard)
/// ```
public struct MarkdownFormattingToolbar: View {

    private enum Metrics {
        static let itemSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 4
        static let iconSize: CGFloat = 15
        static let hitTarget: CGFloat = 28
        static let separatorHeight: CGFloat = 20
    }

    @ObservedObject private var controller: MarkdownEditorController
    private let items: [MarkdownEditorToolbarItem]

    /// Creates a formatting bar driving the given controller.
    ///
    /// - Parameters:
    ///   - controller: The controller the buttons send their commands to.
    ///   - items: The items to show, in order. The default set is ``Swift/Array/standard``.
    public init(
        controller: MarkdownEditorController,
        items: [MarkdownEditorToolbarItem] = .standard
    ) {
        self.controller = controller
        self.items = items
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.itemSpacing) {
                ForEach(items) { item in
                    switch item.kind {
                    case .separator:
                        Divider().frame(height: Metrics.separatorHeight)
                    case .button(let button):
                        toolbarButton(button)
                    }
                }
            }
            .padding(.horizontal, Metrics.horizontalPadding)
            .padding(.vertical, Metrics.verticalPadding)
        }
    }

    /// Builds an icon-only button carrying its accessibility label and shortcut.
    ///
    /// - An icon has no spoken name, so `accessibilityLabel` is always attached.
    ///   Without it VoiceOver cannot tell the buttons apart.
    /// - The shortcut works on macOS and on iPad with a hardware keyboard.
    @ViewBuilder
    private func toolbarButton(_ button: MarkdownEditorToolbarItem.Button) -> some View {
        let base = Button {
            button.action(controller)
        } label: {
            Image(systemName: button.icon)
                .font(.system(size: Metrics.iconSize))
                .frame(width: Metrics.hitTarget, height: Metrics.hitTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(button.label)

        if let key = button.key {
            base.keyboardShortcut(key, modifiers: button.modifiers)
        } else {
            base
        }
    }
}
