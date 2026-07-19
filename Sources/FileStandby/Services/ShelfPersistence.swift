import Foundation

struct ShelfPersistence: Sendable {
    let fileURL: URL

    static let live: ShelfPersistence = {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)

        return ShelfPersistence(
            fileURL: applicationSupport
                .appendingPathComponent("FileStandby", isDirectory: true)
                .appendingPathComponent("shelf.json", isDirectory: false)
        )
    }()

    func load() throws -> [ShelfItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([ShelfItem].self, from: data)
    }

    func save(_ items: [ShelfItem]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(items)
        try data.write(to: fileURL, options: .atomic)
    }
}
