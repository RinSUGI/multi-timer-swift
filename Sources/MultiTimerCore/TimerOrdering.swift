import Foundation

/// Pure rules for drag-reordering timers. See docs/design-docs/20-spec/reordering.md.
public enum TimerOrdering {
    /// Number of other cards whose original center lies strictly above `currentCenter`.
    public static func insertionIndex(originalCenters: [Double], draggedIndex: Int, currentCenter: Double) -> Int {
        originalCenters.indices.filter { $0 != draggedIndex && originalCenters[$0] < currentCenter }.count
    }

    /// Moves the element at `from` so it ends up at index `to` in the result.
    public static func moved<T>(_ items: [T], from: Int, to: Int) -> [T] {
        var result = items
        let item = result.remove(at: from)
        result.insert(item, at: min(max(to, 0), result.count))
        return result
    }

    /// Orders `items` by `ids`; unknown ids are ignored, duplicates keep the first,
    /// and items missing from `ids` keep their relative order at the end.
    public static func reordered<T>(_ items: [T], by ids: [String], id: (T) -> String) -> [T] {
        var remaining = items
        var result: [T] = []
        for target in ids {
            if let idx = remaining.firstIndex(where: { id($0) == target }) {
                result.append(remaining.remove(at: idx))
            }
        }
        return result + remaining
    }
}
