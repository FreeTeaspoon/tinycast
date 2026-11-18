import Foundation

struct ClipboardSelection: Equatable {
    private(set) var ids: [UUID] = []
    private(set) var anchor: UUID?

    func selectedIDs(focusedID: UUID?) -> [UUID] {
        anchor == nil ? focusedID.map { [$0] } ?? [] : ids
    }

    mutating func select(
        _ id: UUID, in visibleIDs: [UUID], focusedID: UUID?,
        toggling: Bool = false, extending: Bool = false
    ) {
        guard let end = visibleIDs.firstIndex(of: id) else { return }
        if extending {
            let anchorIndex = anchor.flatMap { visibleIDs.firstIndex(of: $0) }
            let start = anchorIndex
                ?? focusedID.flatMap { visibleIDs.firstIndex(of: $0) }
                ?? end
            let range = Array(visibleIDs[min(start, end)...max(start, end)])
            if anchorIndex == nil { anchor = visibleIDs[start] }
            if toggling {
                let existing = Set(ids)
                ids += range.filter { !existing.contains($0) }
            } else {
                ids = range
            }
        } else if toggling {
            if anchor == nil { ids = selectedIDs(focusedID: focusedID) }
            if ids.contains(id) {
                ids.removeAll { $0 == id }
            } else {
                ids.append(id)
            }
            anchor = id
        } else {
            ids = [id]
            anchor = id
        }
        let visible = Set(visibleIDs)
        ids.removeAll { !visible.contains($0) }
    }
}
