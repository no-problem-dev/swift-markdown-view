// swift-tools-version: 6.0

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
        )
    ],
    dependencies: [
        .package(url: "https://github.com/no-problem-dev/swift-design-system.git", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", from: "1.17.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "SwiftMarkdownView",
            dependencies: [
                .product(name: "DesignSystem", package: "swift-design-system"),
                .product(name: "Markdown", package: "swift-markdown")
            ]
        ),
        .testTarget(
            name: "SwiftMarkdownViewTests",
            dependencies: [
                "SwiftMarkdownView",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
