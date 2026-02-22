#if canImport(UIKit)
import Testing
import SwiftUI
import VisualTesting
@testable import SwiftMarkdownView

/// Snapshot tests for media elements.
///
/// Tests rendering of images (local, remote, placeholders).
@SnapshotSuite("Media")
@MainActor
struct MediaSnapshotTests {

    init() { setupVisualTesting() }

    // MARK: - Image Placeholder

    @ComponentSnapshot(width: 400, height: 600)
    func imagePlaceholder() -> some View {
        // Using a non-http URL to show fallback rendering
        MarkdownView("""
        Here is an image:

        ![Sample Image](./local/image.png)

        This tests the fallback placeholder view.
        """)
        .padding()
    }

    // MARK: - Local Bundle Image

    // Note: Bundle.module resource access requires runtime logic,
    // so this test uses the direct API instead of @ComponentSnapshot.
    @Test
    func localBundleImage() {
        guard let imageURL = Bundle.module.url(
            forResource: "test-profile-image",
            withExtension: "jpg",
            subdirectory: "Resources"
        ) else {
            Issue.record("Test image not found in bundle")
            return
        }

        let view = MarkdownView("""
        # Profile

        ![\(imageURL.lastPathComponent)](\(imageURL.absoluteString))

        This is a test with a local bundled image.
        """)
        .padding()

        VisualTesting.assertComponentSnapshot(
            of: view,
            componentName: "Media",
            stateName: "localBundleImage",
            size: CGSize(width: 400, height: 600),
            file: #filePath, line: #line
        )
    }

    // MARK: - Image with Alt Text Only

    @ComponentSnapshot(width: 400, height: 600)
    func imageAltOnly() -> some View {
        MarkdownView("""
        ![This is the alt text for a missing image](invalid://path)
        """)
        .padding()
    }
}
#endif
