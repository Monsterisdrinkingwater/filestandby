import Foundation
import Observation

struct AddItemsResult: Equatable, Sendable {
    let addedCount: Int
    let duplicateCount: Int
    let failedCount: Int
}

@MainActor
@Observable
final class ShelfStore {
    private(set) var items: [ShelfItem] = []
    var errorMessage: String?
    var isDropTargeted = false

    private let persistence: ShelfPersistence

    init(persistence: ShelfPersistence = .live) {
        self.persistence = persistence
        load()
    }

    @discardableResult
    func add(urls: [URL]) -> AddItemsResult {
        var addedCount = 0
        var duplicateCount = 0
        var failedCount = 0
        var knownPaths = Set(items.map(\.canonicalPath))

        for url in urls where url.isFileURL {
            do {
                let item = try ShelfItem.make(from: url)
                guard knownPaths.insert(item.canonicalPath).inserted else {
                    duplicateCount += 1
                    continue
                }
                items.insert(item, at: 0)
                addedCount += 1
            } catch {
                failedCount += 1
            }
        }

        if addedCount > 0 {
            persist()
        }

        if failedCount > 0 {
            errorMessage = "有 \(failedCount) 个项目无法读取，未加入文件架。"
        }

        return AddItemsResult(
            addedCount: addedCount,
            duplicateCount: duplicateCount,
            failedCount: failedCount
        )
    }

    func remove(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
        persist()
    }

    func clear() {
        guard !items.isEmpty else { return }
        items.removeAll()
        persist()
    }

    func resolvedURL(for item: ShelfItem) -> URL? {
        item.resolvedURL()
    }

    private func load() {
        do {
            items = try persistence.load()
        } catch {
            items = []
            errorMessage = "暂存列表无法读取，已从空文件架启动。"
        }
    }

    private func persist() {
        do {
            try persistence.save(items)
        } catch {
            errorMessage = "暂存列表保存失败：\(error.localizedDescription)"
        }
    }
}
