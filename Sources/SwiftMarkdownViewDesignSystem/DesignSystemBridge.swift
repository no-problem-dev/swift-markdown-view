import SwiftUI
import DesignSystem
import SwiftMarkdownView

// MARK: - Palette

/// `swift-design-system` のカラーパレットを Markdown の色として解釈する。
public struct DesignSystemMarkdownPalette: MarkdownPalette {

    private let palette: any ColorPalette

    public init(_ palette: any ColorPalette) {
        self.palette = palette
    }

    public var text: Color { palette.onSurface }
    public var secondaryText: Color { palette.onSurfaceVariant }
    public var heading: Color { palette.onSurface }
    public var link: Color { palette.primary }
    public var codeBackground: Color { palette.surfaceVariant }
    public var rule: Color { palette.outlineVariant }
}

// MARK: - Metrics

/// `swift-design-system` のスペーシングスケールを Markdown の寸法として解釈する。
public struct DesignSystemMarkdownMetrics: MarkdownMetrics {

    private let spacing: any SpacingScale

    public init(_ spacing: any SpacingScale) {
        self.spacing = spacing
    }

    public var paragraphSpacing: CGFloat { spacing.md }
    public var indentStep: CGFloat { spacing.xl }
}

// MARK: - Type scale

/// `swift-design-system` の `Typography` を Markdown の文字サイズとして解釈する。
public struct DesignSystemMarkdownTypeScale: MarkdownTypeScale {

    public init() {}

    public var bodySize: CGFloat { Typography.bodyLarge.size }

    public var headingSizes: [CGFloat] {
        [
            Typography.headlineLarge.size,
            Typography.headlineMedium.size,
            Typography.headlineSmall.size,
            Typography.titleLarge.size,
            Typography.titleMedium.size,
            Typography.titleSmall.size,
        ]
    }
}

// MARK: - View Extension

extension View {

    /// MarkdownView とそのコンテンツに DesignSystem テーマを適用する。
    ///
    /// これにより Markdown の色・寸法・文字サイズがアプリのテーマに追従する。
    ///
    /// ```swift
    /// MarkdownView(source)
    ///     .markdownTheme(themeProvider)
    /// ```
    ///
    /// - Parameter provider: テーマ設定を保持する ThemeProvider。
    /// - Returns: テーマが適用されたビュー。
    public func markdownTheme(_ provider: ThemeProvider) -> some View {
        self.theme(provider)
            .markdownDesignSystemTokens()
    }

    /// 環境の DesignSystem トークンを Markdown 側の環境値へ写す。
    ///
    /// `.theme(_:)` を自前で当てている場合はこちらを直接使う。
    public func markdownDesignSystemTokens() -> some View {
        modifier(DesignSystemTokenBridge())
    }
}

/// `ThemeProvider` が環境に流す DesignSystem トークンを読み、Markdown 側の環境値へ写す。
private struct DesignSystemTokenBridge: ViewModifier {

    @Environment(\.colorPalette) private var palette
    @Environment(\.spacingScale) private var spacing

    func body(content: Content) -> some View {
        content
            .markdownPalette(DesignSystemMarkdownPalette(palette))
            .markdownMetrics(DesignSystemMarkdownMetrics(spacing))
            .markdownTypeScale(DesignSystemMarkdownTypeScale())
    }
}
