import SwiftUI
import DesignSystem

/// カタログコンテンツを整理するセクションカード。
///
/// カタログ View 内で関連コンテンツをグループ化する際に使用する。
public struct CatalogSectionCard<Content: View>: View {

    /// セクションのタイトル。
    public let title: String

    /// オプションのサブタイトルテキスト。
    public let subtitle: String?

    /// セクションのコンテンツ。
    @ViewBuilder public let content: () -> Content

    @Environment(\.colorPalette) private var colorPalette
    @Environment(\.spacingScale) private var spacing
    @Environment(\.radiusScale) private var radius

    /// セクションカードを作成する。
    ///
    /// - Parameters:
    ///   - title: セクションのタイトル。
    ///   - subtitle: オプションのサブタイトルテキスト。
    ///   - content: セクションのコンテンツ。
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
