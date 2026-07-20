// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-markdown-view",
    // tvOS / watchOS は宣言しない。本パッケージは swift-design-system と swift-latex-view に
    // 依存しており、どちらも iOS / macOS しか宣言していないため実際には解決・ビルドできない。
    // 支えられていないプラットフォームを宣言すると、利用者は原因の分からない失敗に当たる。
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SwiftMarkdownView",
            targets: ["SwiftMarkdownView"]
        ),
        .library(
            name: "SwiftMarkdownViewHighlightJS",
            targets: ["SwiftMarkdownViewHighlightJS"]
        ),
        .library(
            name: "SwiftMarkdownViewLaTeX",
            targets: ["SwiftMarkdownViewLaTeX"]
        ),
        .library(
            name: "SwiftMarkdownEditor",
            targets: ["SwiftMarkdownEditor"]
        ),
        // swift-design-system を使っているアプリ向けのブリッジ。本体は外部デザインシステムに
        // 依存しないので、テーマ連携が要る利用者だけがこちらを追加で取る。
        .library(
            name: "SwiftMarkdownViewDesignSystem",
            targets: ["SwiftMarkdownViewDesignSystem"]
        ),
        .library(
            name: "SwiftMarkdownEditorDesignSystem",
            targets: ["SwiftMarkdownEditorDesignSystem"]
        ),
        // 各機能を実際に描画して見せるデモ画面群。ライブラリの機能ではないので
        // 本体には含めず、見たい人だけが opt-in する。
        .library(
            name: "SwiftMarkdownViewCatalog",
            targets: ["SwiftMarkdownViewCatalog"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/no-problem-dev/swift-design-system.git", from: "2.0.1"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", .upToNextMajor(from: "0.7.3")),
        .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/appstefan/HighlightSwift.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/no-problem-dev/swift-latex-view.git", from: "0.2.0")
    ],
    targets: [
        // UI 非依存の意味モデル層。swift-markdown AST → ドメイン型（Block/Inline/Content）と
        // 数式プリプロセッサ。Foundation と swift-markdown のみに依存し、SwiftUI/UIKit を
        // 一切 import しない。SwiftUI レンダラ・TextKit レンダラ・エディタが等しく依存する土台。
        .target(
            name: "MarkdownModel",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),

        .testTarget(
            name: "MarkdownModelTests",
            dependencies: [
                "MarkdownModel"
            ]
        ),

        // クロスプラットフォーム（UIKit/AppKit）だが SwiftUI 非依存。意味モデルを単一の
        // NSAttributedString へ合成する「描画済みの読めるテキスト」ビルダーと、semantic 属性キー、
        // 装飾記述子、ハイライト/数式の TextKit 用拡張プロトコル。連続選択・コピーの正しさは
        // ここで決まり、ヘッドレスに単体テストできる。
        .target(
            name: "MarkdownAttributedKit",
            dependencies: [
                "MarkdownModel"
            ]
        ),

        .testTarget(
            name: "MarkdownAttributedKitTests",
            dependencies: [
                "MarkdownAttributedKit"
            ]
        ),

        // 単一ストレージ TextKit2 ビュー。read-only な UITextView/NSTextView の Representable、
        // layout fragment 描画、選択、コピー / Markdown コピー。iOS/macOS が対象。
        .target(
            name: "MarkdownTextKit",
            dependencies: [
                "MarkdownAttributedKit"
            ]
        ),

        .testTarget(
            name: "MarkdownTextKitTests",
            dependencies: [
                "MarkdownTextKit"
            ]
        ),

        // 描画本体。外部デザインシステムに依存しない。色・寸法・文字サイズは
        // MarkdownPalette / MarkdownMetrics / MarkdownTypeScale として自前で抽象化しており、
        // 既定実装はシステムの意味色でライト/ダークに自動追従する。
        .target(
            name: "SwiftMarkdownView",
            dependencies: [
                "MarkdownModel",
                "MarkdownAttributedKit",
                "MarkdownTextKit"
            ]
        ),

        // swift-design-system のトークンを Markdown 側の抽象へ写すブリッジ。
        .target(
            name: "SwiftMarkdownViewDesignSystem",
            dependencies: [
                "SwiftMarkdownView",
                .product(name: "DesignSystem", package: "swift-design-system")
            ]
        ),
        // 機能デモのカタログ画面。本体から切り出してあるのは、デモは
        // 「新機能を見せたい時」に、レンダラは「Markdown 仕様やレイアウトを直したい時」に
        // 変わるため。同居させると、デモ画面の変更が本体のメジャーバンプを強制する。
        .target(
            name: "SwiftMarkdownViewCatalog",
            dependencies: [
                "SwiftMarkdownView",
                "SwiftMarkdownViewDesignSystem",
                .product(name: "DesignSystem", package: "swift-design-system")
            ]
        ),

        .target(
            name: "SwiftMarkdownViewHighlightJS",
            dependencies: [
                "SwiftMarkdownView",
                .product(name: "HighlightSwift", package: "HighlightSwift")
            ]
        ),
        .target(
            name: "SwiftMarkdownViewLaTeX",
            dependencies: [
                "SwiftMarkdownView",
                // swift-latex-view の MathStyle プロトコルが ColorPalette / SpacingScale を
                // 要件に持つため、この付加モジュールだけは DesignSystem を避けられない。
                // 本体(SwiftMarkdownView)は依存しないので、利用者は opt-in で受け入れる。
                .product(name: "DesignSystem", package: "swift-design-system"),
                .product(name: "SwiftLaTeXView", package: "swift-latex-view")
            ]
        ),

        .testTarget(
            name: "SwiftMarkdownViewLaTeXTests",
            dependencies: [
                "SwiftMarkdownViewLaTeX"
            ]
        ),

        // MARK: - Editor

        // UI 非依存のドキュメントモデル層。EditorState / TextChange / 位置写像 /
        // トークナイザ。Foundation と意味モデル(MarkdownModel)のみに依存し、
        // UIKit/SwiftUI を一切 import しない（純ロジックを単体テストで固めるため）。
        .target(
            name: "SwiftMarkdownEditorCore",
            dependencies: [
                "MarkdownModel"
            ]
        ),

        .testTarget(
            name: "SwiftMarkdownEditorCoreTests",
            dependencies: [
                "SwiftMarkdownEditorCore"
            ]
        ),

        // Markdown オートフォーマット（input rules）。Core の上の純ロジック層。
        .target(
            name: "SwiftMarkdownEditorRules",
            dependencies: [
                "SwiftMarkdownEditorCore"
            ]
        ),

        .testTarget(
            name: "SwiftMarkdownEditorRulesTests",
            dependencies: [
                "SwiftMarkdownEditorRules"
            ]
        ),

        // TextKit 2 ブリッジ層。UITextView/NSTextView の Representable と
        // ライブ・シンタックスハイライト。UI を含むのでここから SwiftUI/UIKit に依存。
        .target(
            name: "SwiftMarkdownEditorTextKit",
            dependencies: [
                "SwiftMarkdownEditorCore",
                "SwiftMarkdownEditorRules"
            ]
        ),

        .testTarget(
            name: "SwiftMarkdownEditorTextKitTests",
            dependencies: [
                "SwiftMarkdownEditorTextKit"
            ]
        ),

        // 公開 SwiftUI 層。MarkdownEditor View・ツールバー・モード切替・分割プレビュー。
        // 外部デザインシステムに依存しない。着色は MarkdownEditorTheme 環境値から取る。
        .target(
            name: "SwiftMarkdownEditor",
            dependencies: [
                "SwiftMarkdownView",
                "SwiftMarkdownEditorCore",
                "SwiftMarkdownEditorRules",
                "SwiftMarkdownEditorTextKit"
            ]
        ),

        // swift-design-system のパレットから MarkdownEditorTheme を導出するブリッジ。
        .target(
            name: "SwiftMarkdownEditorDesignSystem",
            dependencies: [
                "SwiftMarkdownEditor",
                "SwiftMarkdownEditorTextKit",
                .product(name: "DesignSystem", package: "swift-design-system")
            ]
        ),

        .testTarget(
            name: "SwiftMarkdownEditorTests",
            dependencies: [
                "SwiftMarkdownEditor",
                .product(name: "VisualTesting", package: "swift-visual-testing")
            ]
        ),

        .testTarget(
            name: "SwiftMarkdownViewTests",
            dependencies: [
                "SwiftMarkdownView",
                "SwiftMarkdownViewHighlightJS",
                "SwiftMarkdownViewLaTeX",
                .product(name: "VisualTesting", package: "swift-visual-testing")
            ],
            resources: [
                // iOS バンドル直下の "Resources" ディレクトリは codesign が
                // macOS バンドル形式と誤認して失敗するため、この名前を使う
                .copy("TestResources")
            ]
        ),
        .testTarget(
            name: "SwiftMarkdownViewHighlightJSTests",
            dependencies: [
                "SwiftMarkdownViewHighlightJS",
                .product(name: "VisualTesting", package: "swift-visual-testing")
            ]
        )
    ]
)
