import Testing
import SwiftUI
@testable import SwiftMarkdownView

/// Snapshot tests for media elements.
///
/// Tests rendering of images (local, remote, placeholders).
@Suite("Media Snapshots")
@MainActor
struct MediaSnapshotTests {

    // MARK: - Image Placeholder

    @Test
    func imagePlaceholder() {
        // Using a non-http URL to show fallback rendering
        let view = MarkdownView("""
        Here is an image:

        ![Sample Image](./local/image.png)

        This tests the fallback placeholder view.
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Local Bundle Image

    @Test
    func localBundleImage() {
        // Test with bundled test image
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
        SnapshotTestHelper.assertSnapshot(of: view)
    }

    // MARK: - Image with Alt Text Only

    @Test
    func imageAltOnly() {
        let view = MarkdownView("""
        ![This is the alt text for a missing image](invalid://path)
        """)
        SnapshotTestHelper.assertSnapshot(of: view)
    }
}
