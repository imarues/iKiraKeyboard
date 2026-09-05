import Foundation

final class WordLearningStore {
    static let shared = WordLearningStore()
    private let defaults = AppGroup.defaults

    func learn(_ word: String) {
        let normalized = word.trimmingCharacters(in: .punctuationCharacters.union(.whitespacesAndNewlines))
        guard normalized.count >= 2, normalized.count <= 40 else { return }
        var map = defaults.dictionary(forKey: SharedKeys.learnedWords) as? [String: Int] ?? [:]
        map[normalized, default: 0] += 1
        if map.count > 1000 {
            let kept = map.sorted { lhs, rhs in lhs.value > rhs.value }.prefix(800)
            map = Dictionary(uniqueKeysWithValues: kept.map { ($0.key, $0.value) })
        }
        defaults.set(map, forKey: SharedKeys.learnedWords)
    }

    func suggestions(prefix: String, limit: Int = 6) -> [String] {
        let map = defaults.dictionary(forKey: SharedKeys.learnedWords) as? [String: Int] ?? [:]
        let filtered: [(key: String, value: Int)] = map.filter { entry in
            entry.key.lowercased().hasPrefix(prefix.lowercased()) &&
            entry.key.caseInsensitiveCompare(prefix) != .orderedSame
        }
        let sorted = filtered.sorted { lhs, rhs in
            if lhs.value == rhs.value {
                return lhs.key.count < rhs.key.count
            }
            return lhs.value > rhs.value
        }
        return sorted.prefix(limit).map { $0.key }
    }
}
