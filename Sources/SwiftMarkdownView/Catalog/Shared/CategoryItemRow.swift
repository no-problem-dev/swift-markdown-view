import SwiftUI
import DesignSystem

/// A row for displaying a catalog item in a list.
public struct CategoryItemRow: View {

    /// The catalog item to display.
    public let item: MarkdownCatalogItem

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    /// Creates a new category item row.
    ///
    /// - Parameter item: The catalog item to display.
    public init(item: MarkdownCatalogItem) {
        self.item = item
    }

    public var body: some View {
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
