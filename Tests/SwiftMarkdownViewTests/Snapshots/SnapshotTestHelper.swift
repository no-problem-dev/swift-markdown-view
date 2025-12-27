import SwiftUI
import SnapshotTesting
import Testing

/// Common snapshot testing configuration and helpers.
enum SnapshotTestHelper {

    /// Standard size for snapshot testing.
    static let defaultSize = CGSize(width: 400, height: 600)

    /// Whether to record new reference snapshots.
    /// Set `SNAPSHOT_RECORD=1` environment variable to enable recording mode.
    static let isRecording: Bool = {
        ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
    }()

    /// Takes a snapshot of a SwiftUI view and compares against reference.
    ///
    /// The snapshot filename is derived from the test function name.
    /// For example, `func testParagraph()` creates `testParagraph.png`.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view to snapshot.
    ///   - size: The size of the snapshot frame. Defaults to `defaultSize`.
    ///   - file: The source file (auto-populated).
    ///   - testName: The test function name (auto-populated).
    ///   - line: The source line (auto-populated).
    @MainActor
    static func assertSnapshot<V: View>(
        of view: V,
        size: CGSize = defaultSize,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let hostingController = NSHostingController(
            rootView: view
                .frame(width: size.width)
                .padding()
                .background(Color.white)
        )

        hostingController.view.frame = CGRect(
            origin: .zero,
            size: CGSize(width: size.width + 32, height: size.height)
        )

        SnapshotTesting.assertSnapshot(
            of: hostingController,
            as: .image,
            record: isRecording,
            file: file,
            testName: testName,
            line: line
        )
    }

    /// Takes a snapshot of a SwiftUI view after waiting for async content to load.
    ///
    /// Use this for views containing WebView or other async-loading content.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view to snapshot.
    ///   - delay: Time to wait for content to load (in seconds).
    ///   - size: The size of the snapshot frame. Defaults to `defaultSize`.
    ///   - file: The source file (auto-populated).
    ///   - testName: The test function name (auto-populated).
    ///   - line: The source line (auto-populated).
    @MainActor
    static func assertSnapshotAsync<V: View>(
        of view: V,
        delay: TimeInterval = 3.0,
        size: CGSize = defaultSize,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) async {
        let hostingController = NSHostingController(
            rootView: view
                .frame(width: size.width)
                .padding()
                .background(Color.white)
        )

        hostingController.view.frame = CGRect(
            origin: .zero,
            size: CGSize(width: size.width + 32, height: size.height)
        )

        // Force layout
        hostingController.view.layoutSubtreeIfNeeded()

        // Wait for WebView content to load
        try? await Task.sleep(for: .seconds(delay))

        SnapshotTesting.assertSnapshot(
            of: hostingController,
            as: .image,
            record: isRecording,
            file: file,
            testName: testName,
            line: line
        )
    }
}
