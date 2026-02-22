#if canImport(UIKit)
import Testing
import Foundation
import VisualTesting

/// Generates snapshot catalog and HTML gallery from recorded snapshots.
///
/// This test should run AFTER all snapshot tests have completed.
/// It scans the __Snapshots__ directories, aggregates manifests,
/// and produces a self-contained HTML gallery file.
@Suite("Gallery Generation")
@MainActor
struct GalleryGeneratorTests {

    @Test
    func generateGallery() {
        let snapshotsDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()

        let snapshotsRoot = snapshotsDir.path

        let catalogPath = snapshotsDir
            .appendingPathComponent("snapshot-catalog.json")
            .path

        let galleryPath = snapshotsDir
            .appendingPathComponent("gallery.html")
            .path

        let catalog = VisualTesting.generateCatalog(
            rootDirectory: snapshotsRoot,
            outputPath: catalogPath
        )

        VisualTesting.generateGallery(
            catalog: catalog,
            outputPath: galleryPath
        )

        #expect(FileManager.default.fileExists(atPath: galleryPath))
    }
}
#endif
