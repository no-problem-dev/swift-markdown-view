import Testing
@testable import SwiftMarkdownView

/// Tests for Markdown task list (checkbox) parsing
struct TaskListTests {

    // MARK: - Basic Task List Parsing

    @Test("Task list with checked item parses correctly")
    func checkedTaskListParses() {
        let source = """
        - [x] Completed task
        """
        let content = MarkdownContent(parsing: source)

        #expect(content.blocks.count == 1)

        guard case .unorderedList(let items) = content.blocks.first else {
            Issue.record("Expected unordered list block")
            return
        }

        #expect(items.count == 1)
        #expect(items[0].isChecked == true)
    }

    @Test("Task list with unchecked item parses correctly")
    func uncheckedTaskListParses() {
        let source = """
        - [ ] Pending task
        """
        let content = MarkdownContent(parsing: source)

        guard case .unorderedList(let items) = content.blocks.first else {
            Issue.record("Expected unordered list block")
            return
        }

        #expect(items.count == 1)
        #expect(items[0].isChecked == false)
    }

    @Test("Mixed task list parses correctly")
    func mixedTaskListParses() {
        let source = """
        - [x] Done
        - [ ] Not done
        - [x] Also done
        """
        let content = MarkdownContent(parsing: source)

        guard case .unorderedList(let items) = content.blocks.first else {
            Issue.record("Expected unordered list block")
            return
        }

        #expect(items.count == 3)
        #expect(items[0].isChecked == true)
        #expect(items[1].isChecked == false)
        #expect(items[2].isChecked == true)
    }

    @Test("Regular list items have nil isChecked")
    func regularListItemsHaveNilIsChecked() {
        let source = """
        - Regular item
        - Another item
        """
        let content = MarkdownContent(parsing: source)

        guard case .unorderedList(let items) = content.blocks.first else {
            Issue.record("Expected unordered list block")
            return
        }

        #expect(items.count == 2)
        #expect(items[0].isChecked == nil)
        #expect(items[1].isChecked == nil)
    }

    // MARK: - Mixed Lists

    @Test("List with mixed regular and task items parses correctly")
    func mixedRegularAndTaskListParses() {
        let source = """
        - Regular item
        - [x] Checked task
        - [ ] Unchecked task
        - Another regular
        """
        let content = MarkdownContent(parsing: source)

        guard case .unorderedList(let items) = content.blocks.first else {
            Issue.record("Expected unordered list block")
            return
        }

        #expect(items.count == 4)
        #expect(items[0].isChecked == nil)   // Regular
        #expect(items[1].isChecked == true)  // Checked
        #expect(items[2].isChecked == false) // Unchecked
        #expect(items[3].isChecked == nil)   // Regular
    }

    // MARK: - Task List Content

    @Test("Task list item content parses correctly")
    func taskListItemContentParses() {
        let source = """
        - [x] Complete the **important** task
        """
        let content = MarkdownContent(parsing: source)

        guard case .unorderedList(let items) = content.blocks.first else {
            Issue.record("Expected unordered list block")
            return
        }

        guard case .paragraph(let inlines) = items[0].blocks.first else {
            Issue.record("Expected paragraph in list item")
            return
        }

        // Should contain text and strong formatting
        #expect(inlines.count >= 2)
        #expect(inlines.contains {
            if case .strong = $0 { return true }
            return false
        })
    }

    // MARK: - Ordered Task Lists

    @Test("Ordered task list parses correctly")
    func orderedTaskListParses() {
        let source = """
        1. [x] First done
        2. [ ] Second pending
        3. [x] Third done
        """
        let content = MarkdownContent(parsing: source)

        guard case .orderedList(let start, let items) = content.blocks.first else {
            Issue.record("Expected ordered list block")
            return
        }

        #expect(start == 1)
        #expect(items.count == 3)
        #expect(items[0].isChecked == true)
        #expect(items[1].isChecked == false)
        #expect(items[2].isChecked == true)
    }
}
