import Foundation

final class ClipboardStore {
    static let shared = ClipboardStore()
    private let defaults = AppGroup.defaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let maxItems = 300

    var insertionPosition: ClipboardInsertionPosition {
        get { ClipboardInsertionPosition(rawValue: defaults.string(forKey: SharedKeys.clipboardInsertion) ?? "beginning") ?? .beginning }
        set { defaults.set(newValue.rawValue, forKey: SharedKeys.clipboardInsertion) }
    }

    func allItems() -> [ClipboardItem] {
        guard let data = defaults.data(forKey: SharedKeys.clipboardItems),
              let items = try? decoder.decode([ClipboardItem].self, from: data) else { return [] }
        return items
    }

    func displayItems() -> [ClipboardItem] {
        let items = allItems()
        return items.filter(\.isPinned) + items.filter { !$0.isPinned }
    }

    @discardableResult
    func capture(_ rawText: String) -> Bool {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        var items = allItems()

        if let existingIndex = items.firstIndex(where: { $0.text == text }) {
            var existing = items.remove(at: existingIndex)
            existing.createdAt = Date()
            if insertionPosition == .beginning { items.insert(existing, at: 0) }
            else { items.append(existing) }
        } else {
            let item = ClipboardItem(text: text)
            if insertionPosition == .beginning { items.insert(item, at: 0) }
            else { items.append(item) }
        }
        trim(&items)
        save(items)
        return true
    }

    func delete(id: UUID) {
        var items = allItems()
        items.removeAll { $0.id == id }
        save(items)
    }

    func togglePin(id: UUID) {
        var items = allItems()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isPinned.toggle()
        save(items)
    }

    func moveToBeginning(id: UUID) {
        var items = allItems()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: index)
        items.insert(item, at: 0)
        save(items)
    }

    func moveToEnd(id: UUID) {
        var items = allItems()
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let item = items.remove(at: index)
        items.append(item)
        save(items)
    }

    private func trim(_ items: inout [ClipboardItem]) {
        guard items.count > maxItems else { return }
        var overflow = items.count - maxItems
        var index = items.count - 1
        while overflow > 0 && index >= 0 {
            if !items[index].isPinned {
                items.remove(at: index)
                overflow -= 1
            }
            index -= 1
        }
    }

    private func save(_ items: [ClipboardItem]) {
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: SharedKeys.clipboardItems)
        }
    }
}
