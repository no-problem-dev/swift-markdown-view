import Testing
@testable import SwiftMarkdownView

/// Tests for Markdown table parsing and rendering
struct TableTests {

    // MARK: - Basic Table Parsing

    @Test("Simple table parses correctly")
    func simpleTableParses() {
        let source = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """
        let content = MarkdownContent(parsing: source)

        #expect(content.blocks.count == 1)

        guard case .table(let table) = content.blocks.first else {
            Issue.record("Expected table block")
            return
        }

        #expect(table.headerRow.cells.count == 2)
        #expect(table.bodyRows.count == 1)
        #expect(table.bodyRows.first?.cells.count == 2)
    }

    @Test("Table with multiple rows parses correctly")
    func multiRowTableParses() {
        let source = """
        | Name  | Age | City    |
        |-------|-----|---------|
        | Alice | 30  | Tokyo   |
        | Bob   | 25  | Osaka   |
        | Carol | 35  | Kyoto   |
        """
        let content = MarkdownContent(parsing: source)

        guard case .table(let table) = content.blocks.first else {
            Issue.record("Expected table block")
            return
        }

        #expect(table.headerRow.cells.count == 3)
        #expect(table.bodyRows.count == 3)
    }

    @Test("Table with alignment parses correctly")
    func alignedTableParses() {
        let source = """
        | Left | Center | Right |
        |:-----|:------:|------:|
        | L    | C      | R     |
        """
        let content = MarkdownContent(parsing: source)

        guard case .table(let table) = content.blocks.first else {
            Issue.record("Expected table block")
            return
        }

        #expect(table.columnAlignments.count == 3)
        #expect(table.columnAlignments[0] == .left)
        #expect(table.columnAlignments[1] == .center)
        #expect(table.columnAlignments[2] == .right)
    }

    @Test("Table cells with inline formatting parse correctly")
    func tableCellsWithFormattingParse() {
        let source = """
        | Feature | Status |
        |---------|--------|
        | **Bold** | *Italic* |
        | `Code`  | [Link](url) |
        """
        let content = MarkdownContent(parsing: source)

        guard case .table(let table) = content.blocks.first else {
            Issue.record("Expected table block")
            return
        }

        // First body row, first cell should contain strong
        let firstCell = table.bodyRows[0].cells[0]
        #expect(firstCell.contains {
            if case .strong = $0 { return true }
            return false
        })
    }

    @Test("Empty table cells parse correctly")
    func emptyCellsTableParses() {
        let source = """
        | A | B |
        |---|---|
        |   |   |
        """
        let content = MarkdownContent(parsing: source)

        guard case .table(let table) = content.blocks.first else {
            Issue.record("Expected table block")
            return
        }

        #expect(table.bodyRows.count == 1)
        // Empty cells should still exist
        #expect(table.bodyRows[0].cells.count == 2)
    }

    // MARK: - Edge Cases

    @Test("Table header only (no body rows) parses correctly")
    func headerOnlyTableParses() {
        let source = """
        | Header 1 | Header 2 |
        |----------|----------|
        """
        let content = MarkdownContent(parsing: source)

        guard case .table(let table) = content.blocks.first else {
            Issue.record("Expected table block")
            return
        }

        #expect(table.headerRow.cells.count == 2)
        #expect(table.bodyRows.isEmpty)
    }

    @Test("Table with single column parses correctly")
    func singleColumnTableParses() {
        let source = """
        | Single |
        |--------|
        | Value  |
        """
        let content = MarkdownContent(parsing: source)

        guard case .table(let table) = content.blocks.first else {
            Issue.record("Expected table block")
            return
        }

        #expect(table.headerRow.cells.count == 1)
        #expect(table.columnAlignments.count == 1)
    }
}
