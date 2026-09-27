import AppKit
import Testing
@testable import FileStandby

@Suite("Shelf item interaction")
@MainActor
struct ShelfItemInteractionTests {
    @Test("clicks forward selection modifiers and double click still previews")
    func clickModifiersAndPreview() throws {
        let view = ShelfItemInteractionNSView()
        var receivedModifiers: NSEvent.ModifierFlags = []
        var previewCount = 0
        view.onClick = { receivedModifiers = $0 }
        view.onPreview = { previewCount += 1 }

        let event = try #require(NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: .zero,
            modifierFlags: [.command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 2,
            pressure: 0
        ))
        view.mouseUp(with: event)

        #expect(receivedModifiers.contains(.command))
        #expect(previewCount == 1)
    }

    @Test("multi-file drag creates one URL item per selected file")
    func draggingItems() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileStandbyDragTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let urls = [
            directory.appendingPathComponent("one.txt"),
            directory.appendingPathComponent("two.txt")
        ]
        for url in urls {
            try Data("test".utf8).write(to: url)
        }
        let items = ShelfItemInteractionNSView.draggingItems(
            for: urls,
            at: NSPoint(x: 30, y: 30)
        )

        #expect(items.count == urls.count)
        #expect(items.compactMap { ($0.item as? NSURL).map { $0 as URL } } == urls)
        #expect(items.allSatisfy { $0.draggingFrame.width == 42 })

        let pasteboard = NSPasteboard(name: .init("FileStandbyTests-\(UUID().uuidString)"))
        #expect(pasteboard.writeObjects(items.compactMap { $0.item as? NSURL }))
        let readURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )?.compactMap { ($0 as? NSURL).map { $0 as URL } }
        #expect(readURLs == urls)
    }

    @Test("unavailable files keep remove enabled but disable file actions")
    func contextMenuForUnavailableFile() throws {
        let view = ShelfItemInteractionNSView()
        view.isAvailable = false
        let event = try #require(NSEvent.mouseEvent(
            with: .rightMouseDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 0
        ))
        let menu = try #require(view.menu(for: event))

        #expect(menu.items[0].isEnabled == false)
        #expect(menu.items[1].isEnabled == false)
        #expect(menu.items[2].isEnabled == false)
        #expect(menu.items[4].isEnabled)
    }
}
