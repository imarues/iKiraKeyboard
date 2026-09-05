import Foundation

enum AppGroup {
    static var defaults: UserDefaults { .standard }
}

enum SharedKeys {
    static let clipboardItems = "clipboard.items.v2"
    static let clipboardInsertion = "clipboard.insertion"
    static let currentLanguage = "keyboard.currentLanguage"
    static let learnedWords = "keyboard.learnedWords"
    static let hapticsEnabled = "keyboard.haptics"
}
