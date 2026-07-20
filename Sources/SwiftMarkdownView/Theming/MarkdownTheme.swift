import SwiftUI

// MARK: - MarkdownPalette

/// Markdown の描画に必要な色。
///
/// 役割で名前が付いており、特定のデザインシステムに依存しない。
/// `swift-design-system` を使っているなら `SwiftMarkdownViewDesignSystem` を追加すると
/// `ColorPalette` がそのまま適合する。
public protocol MarkdownPalette: Sendable {

    /// 本文の色。
    var text: Color { get }

    /// 引用本文やコードなど、本文より控えめに見せる要素の色。
    var secondaryText: Color { get }

    /// 見出しの色。
    var heading: Color { get }

    /// リンクの色。
    var link: Color { get }

    /// コードブロックとインラインコードの背景色。
    var codeBackground: Color { get }

    /// 引用バーと水平線の色。
    var rule: Color { get }
}

/// システムの意味色を使う既定パレット。ライト/ダークに自動追従する。
public struct DefaultMarkdownPalette: MarkdownPalette {

    public init() {}

    public var text: Color { .primary }
    public var secondaryText: Color { .secondary }
    public var heading: Color { .primary }
    public var link: Color { .accentColor }
    public var codeBackground: Color { Color.secondary.opacity(0.12) }
    public var rule: Color { Color.secondary.opacity(0.4) }
}

// MARK: - MarkdownMetrics

/// Markdown のブロックレイアウトに必要な寸法。
public protocol MarkdownMetrics: Sendable {

    /// 段落間の余白。
    var paragraphSpacing: CGFloat { get }

    /// 引用・リストの 1 段あたりのインデント幅。
    var indentStep: CGFloat { get }
}

/// 既定の寸法。
public struct DefaultMarkdownMetrics: MarkdownMetrics {

    public init() {}

    public var paragraphSpacing: CGFloat { 16 }
    public var indentStep: CGFloat { 32 }
}

// MARK: - MarkdownTypeScale

/// Markdown の文字サイズ。
public protocol MarkdownTypeScale: Sendable {

    /// 本文のポイントサイズ。
    var bodySize: CGFloat { get }

    /// 見出し 1〜6 のポイントサイズ。要素数が 6 未満なら不足分は末尾の値が使われる。
    var headingSizes: [CGFloat] { get }
}

/// 既定の文字サイズ。
public struct DefaultMarkdownTypeScale: MarkdownTypeScale {

    public init() {}

    public var bodySize: CGFloat { 17 }
    public var headingSizes: [CGFloat] { [32, 28, 24, 22, 20, 17] }
}

// MARK: - Environment

private struct MarkdownPaletteKey: EnvironmentKey {
    static let defaultValue: any MarkdownPalette = DefaultMarkdownPalette()
}

private struct MarkdownMetricsKey: EnvironmentKey {
    static let defaultValue: any MarkdownMetrics = DefaultMarkdownMetrics()
}

private struct MarkdownTypeScaleKey: EnvironmentKey {
    static let defaultValue: any MarkdownTypeScale = DefaultMarkdownTypeScale()
}

extension EnvironmentValues {

    /// Markdown の描画に使う色。
    public var markdownPalette: any MarkdownPalette {
        get { self[MarkdownPaletteKey.self] }
        set { self[MarkdownPaletteKey.self] = newValue }
    }

    /// Markdown のブロックレイアウトに使う寸法。
    public var markdownMetrics: any MarkdownMetrics {
        get { self[MarkdownMetricsKey.self] }
        set { self[MarkdownMetricsKey.self] = newValue }
    }

    /// Markdown の文字サイズ。
    public var markdownTypeScale: any MarkdownTypeScale {
        get { self[MarkdownTypeScaleKey.self] }
        set { self[MarkdownTypeScaleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層の Markdown に色を設定する。
    public func markdownPalette(_ palette: some MarkdownPalette) -> some View {
        environment(\.markdownPalette, palette)
    }

    /// このビュー階層の Markdown に寸法を設定する。
    public func markdownMetrics(_ metrics: some MarkdownMetrics) -> some View {
        environment(\.markdownMetrics, metrics)
    }

    /// このビュー階層の Markdown に文字サイズを設定する。
    public func markdownTypeScale(_ scale: some MarkdownTypeScale) -> some View {
        environment(\.markdownTypeScale, scale)
    }
}
