// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-markdown-view",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
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
        )
    ],
    dependencies: [
        .package(url: "https://github.com/no-problem-dev/swift-design-system.git", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", .upToNextMajor(from: "0.7.3")),
        .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/appstefan/HighlightSwift.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/no-problem-dev/swift-latex-view.git", .upToNextMajor(from: "0.1.0"))
    ],
    targets: [
        .target(
            name: "SwiftMarkdownView",
            dependencies: [
                .product(name: "DesignSystem", package: "swift-design-system"),
                .product(name: "Markdown", package: "swift-markdown")
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
                .product(name: "SwiftLaTeXView", package: "swift-latex-view")
            ]
        ),

        // MARK: - Editor

        // UI 非依存のドキュメントモデル層。EditorState / TextChange / 位置写像 /
        // トークナイザ。Foundation と既存パーサ(SwiftMarkdownView)のみに依存し、
        // UIKit/SwiftUI を一切 import しない（純ロジックを単体テストで固めるため）。
        .target(
            name: "SwiftMarkdownEditorCore",
            dependencies: [
                "SwiftMarkdownView"
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
        // デザインシステムと既存 MarkdownView（プレビュー）をここで消費する。
        .target(
            name: "SwiftMarkdownEditor",
            dependencies: [
                "SwiftMarkdownView",
                "SwiftMarkdownEditorCore",
                "SwiftMarkdownEditorRules",
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
