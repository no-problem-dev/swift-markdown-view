import Foundation
import Testing
@testable import SwiftMarkdownEditorCore

struct TextSpanTests {

    @Test("Length and emptiness")
    func lengthAndEmptiness() {
        #expect(TextSpan(location: 3, length: 4).length == 4)
        #expect(TextSpan(caret: 5).isEmpty)
        #expect(!TextSpan(location: 0, length: 1).isEmpty)
    }

    @Test("Contains uses half-open interval")
    func contains() {
        let r = TextSpan(location: 2, length: 3) // [2,5)
        #expect(!r.contains(1))
        #expect(r.contains(2))
        #expect(r.contains(4))
        #expect(!r.contains(5))
    }

    @Test("Overlap counts shared boundaries (for cursor reveal)")
    func overlaps() {
        let a = TextSpan(location: 2, length: 3) // [2,5)
        #expect(a.overlaps(TextSpan(location: 4, length: 2)))  // [4,6)
        #expect(a.overlaps(TextSpan(caret: 5)))                // touching upper boundary
        #expect(a.overlaps(TextSpan(caret: 2)))                // touching lower boundary
        #expect(!a.overlaps(TextSpan(location: 6, length: 1))) // [6,7)
    }

    @Test("NSRange bridging round-trips")
    func nsRangeBridge() {
        let r = TextSpan(location: 7, length: 4)
        #expect(r.nsRange == NSRange(location: 7, length: 4))
        #expect(TextSpan(NSRange(location: 1, length: 2)) == TextSpan(location: 1, length: 2))
    }

    @Test("Selection normalizes range regardless of direction")
    func selectionRange() {
        #expect(Selection(anchor: 5, head: 2).range == TextSpan(location: 2, length: 3))
        #expect(Selection(anchor: 2, head: 5).range == TextSpan(location: 2, length: 3))
        #expect(Selection(caret: 4).isCaret)
    }
}
