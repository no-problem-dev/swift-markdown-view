import SwiftUI
import DesignSystem

/// A list-based catalog view for compact layouts.
///
/// Uses a custom plain style instead of system list styles.
public struct MarkdownCatalogListView: View {

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
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

/// A section containing a category header and its items.
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

/// Plain style item row for custom list.
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

/// Header view for a category section.
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
