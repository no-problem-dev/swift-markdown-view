// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-markdown-view",
    // tvOS and watchOS are deliberately absent. swift-design-system and swift-latex-view declare
    // neither, so the graph cannot resolve for them. Declaring a platform the dependencies cannot
    // support turns a clear "unsupported" into a failure nobody can explain.
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
        // Bridge for apps already on swift-design-system. The core does not depend on any external
        // design system, so only those who need theme integration take this on top.
        .library(
            name: "SwiftMarkdownViewDesignSystem",
            targets: ["SwiftMarkdownViewDesignSystem"]
        ),
        .library(
            name: "SwiftMarkdownEditorDesignSystem",
            targets: ["SwiftMarkdownEditorDesignSystem"]
        ),
        // Demo screens that render each feature. Not a library capability, so it stays out of the
        // core and is opted into by whoever wants to look.
        .library(
            name: "SwiftMarkdownViewCatalog",
            targets: ["SwiftMarkdownViewCatalog"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/no-problem-dev/swift-design-system.git", from: "4.0.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", .upToNextMajor(from: "0.7.3")),
        .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/appstefan/HighlightSwift.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/no-problem-dev/swift-latex-view.git", .upToNextMinor(from: "0.5.0"))
    ],
    targets: [
        // Nothing but the UIKit / AppKit cross-platform aliases. The renderer side
        // (MarkdownAttributedKit) and the editor side (SwiftMarkdownEditorTextKit) each declared
        // their own public typealias under the same name, which became ambiguous in the scope of
        // anyone importing both. One definition, in one place.
        .target(name: "MarkdownPlatform"),

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

        // Cross-platform (UIKit / AppKit) but free of SwiftUI. Composes the model into a single
        // NSAttributedString, and owns the semantic attribute keys, the decoration descriptors, and
        // the TextKit extension protocols for highlighting and math. Whether selection and Copy come
        // out right is decided here, which is why this layer is headless and unit-testable.
        .target(
            name: "MarkdownAttributedKit",
            dependencies: [
                "MarkdownPlatform",
                "MarkdownModel"
            ]
        ),

        .testTarget(
            name: "MarkdownAttributedKitTests",
            dependencies: [
                "MarkdownAttributedKit"
            ]
        ),

        // One text storage, one TextKit 2 view: a representable over a read-only UITextView /
        // NSTextView, custom layout fragment drawing, selection, and Copy. iOS and macOS only.
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

        // The renderer itself, with no external design system in it. Colors, metrics, and type
        // sizes are its own abstractions — MarkdownPalette, MarkdownMetrics, MarkdownTypeScale — and
        // the defaults are system semantic colors, which follow light and dark on their own.
        .target(
            name: "SwiftMarkdownView",
            dependencies: [
                "MarkdownModel",
                "MarkdownAttributedKit",
                "MarkdownTextKit"
            ]
        ),

        // Maps swift-design-system tokens onto the renderer's own theming abstractions.
        .target(
            name: "SwiftMarkdownViewDesignSystem",
            dependencies: [
                "SwiftMarkdownView",
                .product(name: "DesignSystem", package: "swift-design-system")
            ]
        ),
        // The catalog of feature demos. It is split out because a demo changes when there is
        // something new to show, and the renderer changes when the Markdown handling or the layout
        // is wrong. Together in one target, editing a demo screen forces a major bump on the library.
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
                // swift-latex-view's MathStyle protocol requires ColorPalette and SpacingScale, so
                // this is the one add-on that cannot avoid DesignSystem. The core does not depend on
                // it, so the cost is taken on only by whoever opts into math.
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

        // The editor's UI-free document model: EditorState, TextChange, offset mapping, tokenizer.
        // Depends only on Foundation and the content model, and imports neither UIKit nor SwiftUI, so
        // the logic can be pinned down by unit tests.
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

        // Markdown autoformatting (input rules). Pure logic, layered on the editor core.
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

        // The TextKit 2 bridge: representables over UITextView / NSTextView, plus live syntax
        // highlighting. This is where UI enters, so SwiftUI and UIKit arrive with it.
        .target(
            name: "SwiftMarkdownEditorTextKit",
            dependencies: [
                "MarkdownPlatform",
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

        // The public SwiftUI layer: the MarkdownEditor view, its toolbar, mode switching, and the
        // split preview. No external design system; colors come from the MarkdownEditorTheme
        // environment value.
        .target(
            name: "SwiftMarkdownEditor",
            dependencies: [
                "SwiftMarkdownView",
                "SwiftMarkdownEditorCore",
                "SwiftMarkdownEditorRules",
                "SwiftMarkdownEditorTextKit"
            ]
        ),

        // Derives a MarkdownEditorTheme from the swift-design-system palette.
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
                // A directory named "Resources" at the root of an iOS bundle is mistaken by codesign
                // for the macOS bundle layout and fails signing. Hence this name.
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
