import Foundation
import Testing
@testable import FileStandby

@Suite("ShelfStore")
@MainActor
struct ShelfStoreTests {
    @Test("adds files, rejects duplicates, and persists the shelf")
    func addDeduplicateAndReload() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }

        let firstFile = try fixture.makeFile(named: "draft.txt", contents: "hello")
        let secondFile = try fixture.makeFile(named: "image.png", contents: "png")
        let store = ShelfStore(persistence: fixture.persistence)

        let firstResult = store.add(urls: [firstFile, secondFile, firstFile])

        #expect(firstResult == AddItemsResult(addedCount: 2, duplicateCount: 1, failedCount: 0))
        #expect(store.items.count == 2)
        #expect(store.items.first?.displayName == "image.png")

        let reloadedStore = ShelfStore(persistence: fixture.persistence)
        #expect(reloadedStore.items == store.items)
    }

    @Test("removing and clearing only changes shelf metadata")
    func removeAndClear() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }

        let firstFile = try fixture.makeFile(named: "one.txt", contents: "1")
        let secondFile = try fixture.makeFile(named: "two.txt", contents: "2")
        let store = ShelfStore(persistence: fixture.persistence)
        store.add(urls: [firstFile, secondFile])

        let itemToRemove = try #require(store.items.first)
        store.remove(itemToRemove)
        #expect(store.items.count == 1)
        #expect(FileManager.default.fileExists(atPath: firstFile.path))
        #expect(FileManager.default.fileExists(atPath: secondFile.path))

        store.clear()
        #expect(store.items.isEmpty)
        #expect(FileManager.default.fileExists(atPath: firstFile.path))
        #expect(FileManager.default.fileExists(atPath: secondFile.path))
    }

    @Test("missing source files stay on the shelf as unavailable items")
    func missingFilesRemainVisible() throws {
        let fixture = try Fixture()
        defer { fixture.cleanUp() }

        let file = try fixture.makeFile(named: "offline.mov", contents: "video")
        let store = ShelfStore(persistence: fixture.persistence)
        store.add(urls: [file])
        let item = try #require(store.items.first)

        try FileManager.default.removeItem(at: file)

        #expect(store.resolvedURL(for: item) == nil)
        let reloadedStore = ShelfStore(persistence: fixture.persistence)
        #expect(reloadedStore.items.count == 1)
        #expect(reloadedStore.resolvedURL(for: try #require(reloadedStore.items.first)) == nil)
    }
}

private struct Fixture {
    let directory: URL
    let persistence: ShelfPersistence

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileStandbyTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        persistence = ShelfPersistence(
            fileURL: directory.appendingPathComponent("metadata/shelf.json")
        )
    }

    func makeFile(named name: String, contents: String) throws -> URL {
        let url = directory.appendingPathComponent(name)
        try Data(contents.utf8).write(to: url, options: .atomic)
        return url
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: directory)
    }
}
