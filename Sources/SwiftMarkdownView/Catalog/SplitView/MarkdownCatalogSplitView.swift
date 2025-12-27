import SwiftUI
import DesignSystem

/// A split-view catalog for regular layouts.
///
/// Uses custom plain list style instead of system list styles.
public struct MarkdownCatalogSplitView: View {

    @State private var selectedCategory: MarkdownCatalogCategory? = .blockElements
    @State private var selectedItem: MarkdownCatalogItem?

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    public init() {}

    public var body: some View {
        NavigationSplitView {
            sidebarView
        } content: {
            contentView
        } detail: {
            detailView
        }
    }

    @ViewBuilder
    private var sidebarView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(MarkdownCatalogCategory.allCases) { category in
                    SidebarCategoryRow(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        selectedItem = nil
                    }
                }
            }
            .padding(.vertical, spacing.sm)
        }
        .background(colorPalette.background)
        .navigationTitle("カタログ")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        if let category = selectedCategory {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(category.items) { item in
                        ContentItemRow(
                            item: item,
                            isSelected: selectedItem == item
                        ) {
                            selectedItem = item
                        }
                    }
                }
                .padding(.vertical, spacing.sm)
            }
            .background(colorPalette.background)
            .navigationTitle(category.rawValue)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        } else {
            ContentUnavailableView(
                "カテゴリを選択",
                systemImage: "sidebar.left",
                description: Text("左のサイドバーからカテゴリを選択してください")
            )
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let category = selectedCategory, let item = selectedItem {
            MarkdownCatalogRouter.destination(for: category, item: item)
                .navigationTitle(item.name)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        } else {
            ContentUnavailableView(
                "アイテムを選択",
                systemImage: "doc.text",
                description: Text("リストからアイテムを選択してください")
            )
        }
    }
}

// MARK: - Sidebar Category Row

private struct SidebarCategoryRow: View {

    let category: MarkdownCatalogCategory
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing

    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing.md) {
                Image(systemName: category.icon)
                    .typography(.titleMedium)
                    .foregroundStyle(isSelected ? colorPalette.onPrimary : colorPalette.primary)
                    .frame(width: spacing.xl, height: spacing.xl)

                VStack(alignment: .leading, spacing: spacing.xxs) {
                    Text(category.rawValue)
                        .typography(.bodyMedium)
                        .foregroundStyle(isSelected ? colorPalette.onPrimary : colorPalette.onSurface)

                    Text(category.description)
                        .typography(.bodySmall)
                        .foregroundStyle(
                            isSelected
                                ? colorPalette.onPrimary.opacity(0.8)
                                : colorPalette.onSurfaceVariant
                        )
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, spacing.lg)
            .padding(.vertical, spacing.md)
            .background(isSelected ? colorPalette.primary : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Content Item Row

private struct ContentItemRow: View {

    let item: MarkdownCatalogItem
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    var body: some View {
        Button(action: action) {
            HStack(spacing: spacing.md) {
                Image(systemName: item.icon)
                    .typography(.bodyLarge)
                    .foregroundStyle(isSelected ? colorPalette.onPrimary : colorPalette.primary)
                    .frame(width: spacing.lg, height: spacing.lg)

                VStack(alignment: .leading, spacing: spacing.xxs) {
                    Text(item.name)
                        .typography(.bodyMedium)
                        .foregroundStyle(isSelected ? colorPalette.onPrimary : colorPalette.onSurface)

                    Text(item.description)
                        .typography(.bodySmall)
                        .foregroundStyle(
                            isSelected
                                ? colorPalette.onPrimary.opacity(0.8)
                                : colorPalette.onSurfaceVariant
                        )
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .typography(.labelSmall)
                    .foregroundStyle(
                        isSelected
                            ? colorPalette.onPrimary.opacity(0.6)
                            : colorPalette.onSurfaceVariant.opacity(0.5)
                    )
            }
            .padding(.horizontal, spacing.md)
            .padding(.vertical, spacing.sm)
            .background(isSelected ? colorPalette.primary : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: radius.md))
            .padding(.horizontal, spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MarkdownCatalogSplitView()
        .theme(ThemeProvider())
}
