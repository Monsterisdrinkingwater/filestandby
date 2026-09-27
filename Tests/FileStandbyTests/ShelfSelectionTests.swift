import Foundation
import Testing
@testable import FileStandby

@Suite("Shelf multi-selection")
struct ShelfSelectionTests {
    private let ids = (0..<5).map { _ in UUID() }

    @Test("Command toggles individual items and Shift selects an ordered range")
    func modifierSelection() {
        var selection = ShelfSelection()

        selection.select(ids[1], in: ids, command: false, shift: false)
        selection.select(ids[3], in: ids, command: true, shift: false)
        #expect(selection.ids == Set([ids[1], ids[3]]))

        selection.select(ids[4], in: ids, command: false, shift: true)
        #expect(selection.ids == Set([ids[3], ids[4]]))

        selection.select(ids[3], in: ids, command: true, shift: false)
        #expect(selection.ids == Set([ids[4]]))
    }

    @Test("dragging a selected item keeps the group in shelf order")
    func groupDrag() {
        var selection = ShelfSelection()
        selection.select(ids[3], in: ids, command: false, shift: false)
        selection.select(ids[1], in: ids, command: true, shift: false)

        #expect(selection.itemsToDrag(startingAt: ids[3], in: ids) == [ids[1], ids[3]])
        #expect(selection.itemsToDrag(startingAt: ids[0], in: ids) == [ids[0]])
        #expect(selection.ids == Set([ids[0]]))
    }

    @Test("select all includes every shelf item")
    func selectAll() {
        var selection = ShelfSelection()
        selection.selectAll(ids)
        #expect(selection.ids == Set(ids))
        #expect(selection.itemsToDrag(startingAt: ids[2], in: ids) == ids)
        selection.clear()
        #expect(selection.ids.isEmpty)
    }

    @Test("removed items leave selection without affecting remaining files")
    func removeSelectedItem() {
        var selection = ShelfSelection()
        selection.select(ids[0], in: ids, command: false, shift: false)
        selection.select(ids[2], in: ids, command: true, shift: false)

        selection.retainOnly(Set([ids[1], ids[2], ids[3]]))
        #expect(selection.ids == Set([ids[2]]))
        #expect(selection.anchorID == ids[2])
    }
}
