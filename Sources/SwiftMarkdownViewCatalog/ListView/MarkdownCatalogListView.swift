import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// The single-column catalog layout, used at a compact horizontal size class.
///
/// Rows are built from a scroll view rather than `List`, so they draw from the design
/// system's palette and spacing instead of the system list style.
struct MarkdownCatalogListView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    init() {}

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(MarkdownCatalogCategory.allCases) { category in
                        CategorySection(category: category)
                    }
                }
                .padding(.vertical, spacing.md)
            }
            .background(colorPalette.background)
            .navigationTitle("Markdownカタログ")
        }
    }
}

/// A category header followed by a navigation link for each item in the category.
private struct CategorySection: View {

    let category: MarkdownCatalogCategory

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            CategorySectionHeader(category: category)
                .padding(.horizontal, spacing.lg)
                .padding(.top, spacing.lg)
                .padding(.bottom, spacing.sm)

            // Items
            ForEach(category.items) { item in
                NavigationLink {
                    MarkdownCatalogRouter.destination(for: category, item: item)
                        .navigationTitle(item.name)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                } label: {
                    CategoryItemRowPlain(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CategoryItemRowPlain: View {

    let item: MarkdownCatalogItem

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        HStack(spacing: spacing.md) {
            // Icon
            Image(systemName: item.icon)
                .typography(.titleMedium)
                .foregroundStyle(colorPalette.primary)
                .frame(width: spacing.xl, height: spacing.xl)

            // Text content
            VStack(alignment: .leading, spacing: spacing.xxs) {
                Text(item.name)
                    .typography(.bodyMedium)
                    .foregroundStyle(colorPalette.onSurface)

                Text(item.description)
                    .typography(.bodySmall)
                    .foregroundStyle(colorPalette.onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .typography(.labelSmall)
                .foregroundStyle(colorPalette.onSurfaceVariant.opacity(0.5))
        }
        .padding(.horizontal, spacing.lg)
        .padding(.vertical, spacing.md)
        .background(colorPalette.surface)
        .contentShape(Rectangle())
    }
}

struct CategorySectionHeader: View {

    let category: MarkdownCatalogCategory

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        HStack(spacing: spacing.sm) {
            Image(systemName: category.icon)
                .typography(.labelMedium)
                .fontWeight(.semibold)
                .foregroundStyle(colorPalette.primary)

            Text(category.rawValue)
                .typography(.labelLarge)
                .foregroundStyle(colorPalette.onSurfaceVariant)
        }
    }
}

#Preview {
    MarkdownCatalogListView()
        .theme(ThemeProvider())
}
