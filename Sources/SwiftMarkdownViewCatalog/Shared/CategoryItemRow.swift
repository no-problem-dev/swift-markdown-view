import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// A catalog item as a row: icon, name, one-line description, and a trailing chevron.
///
/// The row pads itself vertically only, and takes its horizontal insets from the container.
struct CategoryItemRow: View {

    let item: MarkdownCatalogItem

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    init(item: MarkdownCatalogItem) {
        self.item = item
    }

    var body: some View {
        HStack(spacing: spacing.md) {
            Image(systemName: item.icon)
                .typography(.titleLarge)
                .foregroundStyle(colorPalette.primary)
                .frame(width: spacing.xxl, height: spacing.xxl)

            VStack(alignment: .leading, spacing: spacing.xxs) {
                Text(item.name)
                    .typography(.bodyLarge)
                    .foregroundStyle(colorPalette.onSurface)

                Text(item.description)
                    .typography(.bodySmall)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .typography(.labelMedium)
                .fontWeight(.semibold)
                .foregroundStyle(colorPalette.onSurfaceVariant.opacity(0.5))
        }
        .padding(.vertical, spacing.sm)
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        CategoryItemRow(item: MarkdownCatalogItem(
            name: "見出し",
            icon: "textformat.size",
            description: "H1〜H6の見出しレベル"
        ))
    }
    .theme(ThemeProvider())
}
