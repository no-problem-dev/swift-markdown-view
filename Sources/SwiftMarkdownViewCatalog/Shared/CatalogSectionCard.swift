import SwiftMarkdownView
import SwiftUI
import DesignSystem

/// A titled card that groups related content on a catalog screen.
public struct CatalogSectionCard<Content: View>: View {

    /// The heading shown at the top of the card.
    public let title: String

    /// A line of supporting text under the heading; omitted when `nil`.
    public let subtitle: String?

    /// The body of the card, laid out below the heading.
    @ViewBuilder public let content: () -> Content

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    /// Creates a section card.
    ///
    /// - Parameters:
    ///   - title: The heading shown at the top of the card.
    ///   - subtitle: Supporting text under the heading. Pass `nil` to omit the line.
    ///   - content: The body of the card.
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
