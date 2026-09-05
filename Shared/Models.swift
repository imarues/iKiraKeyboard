import Foundation

enum KeyboardLanguage: String, Codable, CaseIterable {
    case arabic = "ar"
    case english = "en"

    var isRTL: Bool { self == .arabic }
    var other: KeyboardLanguage { self == .arabic ? .english : .arabic }
}

enum ClipboardInsertionPosition: String, Codable {
    case beginning
    case end
}

struct ClipboardItem: Codable, Hashable, Identifiable {
    var id: UUID
    var text: String
    var createdAt: Date
    var isPinned: Bool

    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
    }
}
