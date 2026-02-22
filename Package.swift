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
        )
    ],
    dependencies: [
        .package(url: "https://github.com/no-problem-dev/swift-design-system.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", .upToNextMajor(from: "0.7.3")),
        .package(url: "https://github.com/no-problem-dev/swift-visual-testing.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/appstefan/HighlightSwift.git", .upToNextMajor(from: "1.0.0"))
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
        .testTarget(
            name: "SwiftMarkdownViewTests",
            dependencies: [
                "SwiftMarkdownView",
                "SwiftMarkdownViewHighlightJS",
                .product(name: "VisualTesting", package: "swift-visual-testing")
            ],
            resources: [
                .copy("Resources")
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
