import Foundation

struct ShelfItem: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let displayName: String
    let originalPath: String
    let bookmarkData: Data?
    let addedAt: Date
    let fileSize: Int64?
    let isDirectory: Bool

    init(
        id: UUID = UUID(),
        displayName: String,
        originalPath: String,
        bookmarkData: Data?,
        addedAt: Date = Date(),
        fileSize: Int64?,
        isDirectory: Bool
    ) {
        self.id = id
        self.displayName = displayName
        self.originalPath = originalPath
        self.bookmarkData = bookmarkData
        self.addedAt = addedAt
        self.fileSize = fileSize
        self.isDirectory = isDirectory
    }

    static func make(from inputURL: URL) throws -> ShelfItem {
        // Keep Finder's URL semantics intact. In particular, a symlink should stay
        // a symlink on the shelf instead of silently becoming its destination.
        let url = inputURL.standardizedFileURL
        let values = try url.resourceValues(forKeys: [
            .isDirectoryKey,
            .fileSizeKey,
            .nameKey
        ])

        // A regular bookmark follows Finder renames and moves. The path remains a
        // readable fallback for volumes or providers that do not support bookmarks.
        let bookmark = try? url.bookmarkData(
            options: [.minimalBookmark],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        return ShelfItem(
            displayName: values.name ?? url.lastPathComponent,
            originalPath: url.path,
            bookmarkData: bookmark,
            fileSize: values.isDirectory == true ? nil : values.fileSize.map(Int64.init),
            isDirectory: values.isDirectory == true
        )
    }

    var canonicalPath: String {
        URL(fileURLWithPath: originalPath)
            .standardizedFileURL
            .path
    }

    func resolvedURL(fileManager: FileManager = .default) -> URL? {
        if let bookmarkData {
            var isStale = false
            if let bookmarkedURL = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), fileManager.fileExists(atPath: bookmarkedURL.path) {
                return bookmarkedURL.standardizedFileURL
            }
        }

        let fallbackURL = URL(fileURLWithPath: originalPath).standardizedFileURL
        return fileManager.fileExists(atPath: fallbackURL.path) ? fallbackURL : nil
    }
}
