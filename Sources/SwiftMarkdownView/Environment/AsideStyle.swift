import SwiftUI
import DesignSystem

// MARK: - AsideStyle Protocol

/// Aside（コールアウト/警告ブロック）の外観スタイルを定義するプロトコル。
///
/// このプロトコルを実装することで、Markdownコンテンツ内の
/// Aside ブロックのアイコン・カラー・外観をカスタマイズできる。
///
/// ## Example
///
/// ```swift
/// struct MyAsideStyle: AsideStyle {
///     func icon(for kind: AsideKind) -> String {
///         switch kind {
///         case .warning: return "flame.fill"
///         default: return DefaultAsideStyle().icon(for: kind)
///         }
///     }
///
///     func accentColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
///         switch kind {
///         case .tip: return .mint
///         default: return DefaultAsideStyle().accentColor(for: kind, colorPalette: colorPalette)
///         }
///     }
///
///     func backgroundColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
///         accentColor(for: kind, colorPalette: colorPalette).opacity(0.15)
///     }
///
///     func titleColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
///         accentColor(for: kind, colorPalette: colorPalette)
///     }
/// }
///
/// // 使用例
/// MarkdownView(source)
///     .markdownAsideStyle(MyAsideStyle())
/// ```
public protocol AsideStyle: Sendable {

    /// 指定した Aside の種類に対応する SF Symbol 名を返す。
    ///
    /// - Parameter kind: Aside の種類。
    /// - Returns: Aside アイコンとして表示する SF Symbol 名。
    func icon(for kind: AsideKind) -> String

    /// 指定した Aside の種類に対応するアクセントカラーを返す。
    ///
    /// アクセントカラーは左ボーダーとアイコンに使用する。
    ///
    /// - Parameters:
    ///   - kind: Aside の種類。
    ///   - colorPalette: 環境から取得した現在のカラーパレット。
    /// - Returns: この Aside 種類のアクセントカラー。
    func accentColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color

    /// 指定した Aside の種類に対応する背景色を返す。
    ///
    /// - Parameters:
    ///   - kind: Aside の種類。
    ///   - colorPalette: 環境から取得した現在のカラーパレット。
    /// - Returns: この Aside 種類の背景色。
    func backgroundColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color

    /// 指定した Aside の種類に対応するタイトルテキストカラーを返す。
    ///
    /// - Parameters:
    ///   - kind: Aside の種類。
    ///   - colorPalette: 環境から取得した現在のカラーパレット。
    /// - Returns: この Aside 種類のタイトルカラー。
    func titleColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color
}

// MARK: - DefaultAsideStyle

/// ライト・ダーク両カラースキームに対応した、意味的カラーを用いるデフォルト Aside スタイル。
public struct DefaultAsideStyle: AsideStyle, Sendable {

    public init() {}

    public func icon(for kind: AsideKind) -> String {
        switch kind {
        case .note:
            return "info.circle.fill"
        case .tip:
            return "lightbulb.fill"
        case .important:
            return "exclamationmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .experiment:
            return "flask.fill"
        case .attention:
            return "bell.fill"
        case .author, .authors:
            return "person.fill"
        case .bug:
            return "ladybug.fill"
        case .complexity:
            return "chart.bar.fill"
        case .copyright:
            return "c.circle.fill"
        case .date:
            return "calendar"
        case .invariant:
            return "lock.fill"
        case .mutatingVariant, .nonMutatingVariant:
            return "arrow.triangle.swap"
        case .postcondition, .precondition:
            return "checkmark.seal.fill"
        case .remark:
            return "quote.bubble.fill"
        case .requires:
            return "list.bullet.rectangle.fill"
        case .since:
            return "clock.fill"
        case .todo:
            return "checklist"
        case .version:
            return "tag.fill"
        case .throws:
            return "xmark.octagon.fill"
        case .seeAlso:
            return "link"
        case .custom:
            return "text.bubble.fill"
        }
    }

    public func accentColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        switch kind {
        case .note, .remark:
            return colorPalette.primary
        case .tip, .experiment:
            return Color.green
        case .important, .attention:
            return Color.orange
        case .warning, .bug, .throws:
            return Color.red
        case .todo:
            return Color.purple
        case .seeAlso:
            return colorPalette.secondary
        default:
            return colorPalette.onSurfaceVariant
        }
    }

    public func backgroundColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        accentColor(for: kind, colorPalette: colorPalette).opacity(0.1)
    }

    public func titleColor(for kind: AsideKind, colorPalette: any ColorPalette) -> Color {
        accentColor(for: kind, colorPalette: colorPalette)
    }
}

// MARK: - Environment Key

private struct AsideStyleKey: EnvironmentKey {
    static let defaultValue: any AsideStyle = DefaultAsideStyle()
}

extension EnvironmentValues {

    /// Aside ブロックのレンダリングに使用するスタイル。
    ///
    /// この値を設定するには ``SwiftUICore/View/asideStyle(_:)`` モディファイアを使用する。
    public var asideStyle: any AsideStyle {
        get { self[AsideStyleKey.self] }
        set { self[AsideStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {

    /// このビュー階層に Aside のカスタムスタイルを設定する。
    ///
    /// ``MarkdownView`` がレンダリングする Aside ブロック（コールアウト/警告）の
    /// 外観をカスタマイズするにはこのモディファイアを使用する。
    ///
    /// ## Example
    ///
    /// ```swift
    /// MarkdownView("""
    /// > Note: これはノートだ。
    /// > Warning: これは警告だ。
    /// """)
    /// .markdownAsideStyle(MyCustomAsideStyle())
    /// ```
    ///
    /// - Parameter style: 使用する Aside スタイル。
    /// - Returns: Aside スタイルが適用されたビュー。
    public func markdownAsideStyle(_ style: some AsideStyle) -> some View {
        environment(\.asideStyle, style)
    }

    @available(*, deprecated, renamed: "markdownAsideStyle(_:)")
    public func asideStyle(_ style: some AsideStyle) -> some View {
        markdownAsideStyle(style)
    }
}
