import SwiftUI
import DesignSystem

/// A section card for organizing catalog content.
///
/// Use this to group related content within a catalog view.
public struct CatalogSectionCard<Content: View>: View {

    /// The title of the section.
    public let title: String

    /// Optional subtitle text.
    public let subtitle: String?

    /// The content of the section.
    @ViewBuilder public let content: () -> Content

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    /// Creates a new section card.
    ///
    /// - Parameters:
    ///   - title: The section title.
    ///   - subtitle: Optional subtitle text.
    ///   - content: The section content.
    public init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing.md) {
            // Header
            VStack(alignment: .leading, spacing: spacing.xs) {
                Text(title)
                    .typography(.titleLarge)
                    .foregroundStyle(colorPalette.onSurface)

                if let subtitle {
                    Text(subtitle)
                        .typography(.bodyMedium)
                        .foregroundStyle(colorPalette.onSurfaceVariant)
                }
            }

            // Content
            content()
        }
        .padding(spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorPalette.surface)
        .clipShape(RoundedRectangle(cornerRadius: radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: radius.lg)
                .stroke(colorPalette.outlineVariant.opacity(0.5), lineWidth: 1)
        )
    }
}

#Preview {
    CatalogSectionCard(title: "基本的な使い方", subtitle: "Markdownの基本構文") {
        Text("コンテンツがここに入ります")
    }
    .padding()
    .theme(ThemeProvider())
}
