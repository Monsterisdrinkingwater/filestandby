import Foundation

struct ShelfSelection {
    private(set) var ids: Set<UUID> = []
    private(set) var anchorID: UUID?

    mutating func select(_ id: UUID, in orderedIDs: [UUID], command: Bool, shift: Bool) {
        guard orderedIDs.contains(id) else { return }

        if shift,
           let anchorID,
           let anchorIndex = orderedIDs.firstIndex(of: anchorID),
           let clickedIndex = orderedIDs.firstIndex(of: id) {
            let range = min(anchorIndex, clickedIndex)...max(anchorIndex, clickedIndex)
            let rangeIDs = Set(range.map { orderedIDs[$0] })
            ids = command ? ids.union(rangeIDs) : rangeIDs
        } else if command {
            if !ids.insert(id).inserted {
                ids.remove(id)
            }
            anchorID = id
        } else {
            ids = [id]
            anchorID = id
        }
    }

    mutating func itemsToDrag(startingAt id: UUID, in orderedIDs: [UUID]) -> [UUID] {
        guard orderedIDs.contains(id) else { return [] }
        if !ids.contains(id) {
            ids = [id]
            anchorID = id
        }
        return orderedIDs.filter { ids.contains($0) }
    }

    mutating func retainOnly(_ validIDs: Set<UUID>) {
        ids.formIntersection(validIDs)
        if let anchorID, !validIDs.contains(anchorID) {
            self.anchorID = nil
        }
    }

    mutating func selectAll(_ orderedIDs: [UUID]) {
        ids = Set(orderedIDs)
        anchorID = orderedIDs.first
    }

    mutating func clear() {
        ids.removeAll()
        anchorID = nil
    }
}
