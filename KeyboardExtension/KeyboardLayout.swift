import UIKit

enum KeyboardMode {
    case letters
    case symbols
}

enum KeyKind: Hashable {
    case text(String)
    case delete
    case shift
    case numbers
    case letters
    case emoji
    case microphone
    case space
    case punctuation
    case returnKey
    case spacer
}

struct KeySpec: Hashable {
    let kind: KeyKind
    let weight: CGFloat
    init(_ kind: KeyKind, _ weight: CGFloat = 1) { self.kind = kind; self.weight = weight }
}

enum KeyboardLayouts {
    static func mainRows(language: KeyboardLanguage, mode: KeyboardMode, shifted: Bool) -> [[KeySpec]] {
        if mode == .symbols { return symbolRows(language: language) }
        return language == .arabic ? arabicRows : englishRows(shifted: shifted)
    }

    static let arabicRows: [[KeySpec]] = [
        ["١","٢","٣","٤","٥","٦","٧","٨","٩","٠"].map { KeySpec(.text($0)) },
        ["ض","ص","ث","ق","ف","غ","ع","ه","خ","ح","ج"].map { KeySpec(.text($0)) },
        ["ش","س","ي","ب","ل","ا","ت","ن","م","ك","ة"].map { KeySpec(.text($0)) },
        [KeySpec(.text("ء")),KeySpec(.text("ظ")),KeySpec(.text("ط")),KeySpec(.text("ذ")),KeySpec(.text("د")),KeySpec(.text("ز")),KeySpec(.text("ر")),KeySpec(.text("و")),KeySpec(.text("ى")),KeySpec(.delete, 1.35)]
    ]

    static func englishRows(shifted: Bool) -> [[KeySpec]] {
        let transform: (String) -> String = { shifted ? $0.uppercased() : $0.lowercased() }
        return [
            ["1","2","3","4","5","6","7","8","9","0"].map { KeySpec(.text($0)) },
            ["Q","W","E","R","T","Y","U","I","O","P"].map { KeySpec(.text(transform($0))) },
            [KeySpec(.spacer, 0.52),KeySpec(.text(transform("A"))),KeySpec(.text(transform("S"))),KeySpec(.text(transform("D"))),KeySpec(.text(transform("F"))),KeySpec(.text(transform("G"))),KeySpec(.text(transform("H"))),KeySpec(.text(transform("J"))),KeySpec(.text(transform("K"))),KeySpec(.text(transform("L"))),KeySpec(.spacer, 0.52)],
            [KeySpec(.shift, 1.15),KeySpec(.text(transform("Z"))),KeySpec(.text(transform("X"))),KeySpec(.text(transform("C"))),KeySpec(.text(transform("V"))),KeySpec(.text(transform("B"))),KeySpec(.text(transform("N"))),KeySpec(.text(transform("M"))),KeySpec(.delete, 1.15)]
        ]
    }

    static func symbolRows(language: KeyboardLanguage) -> [[KeySpec]] {
        let numbers = language == .arabic ? ["١","٢","٣","٤","٥","٦","٧","٨","٩","٠"] : ["1","2","3","4","5","6","7","8","9","0"]
        let comma = language == .arabic ? "،" : ","
        let question = language == .arabic ? "؟" : "?"
        return [
            numbers.map { KeySpec(.text($0)) },
            ["[","]","{","}","#","%","^","*","+","="].map { KeySpec(.text($0)) },
            ["-","/",":",";","(",")","$","&","@","\""].map { KeySpec(.text($0)) },
            [KeySpec(.text("#+="), 1.15),KeySpec(.text(".")),KeySpec(.text(comma)),KeySpec(.text(question)),KeySpec(.text("!")),KeySpec(.text("'")),KeySpec(.delete, 1.15)]
        ]
    }

    static func bottomRow(language: KeyboardLanguage, mode: KeyboardMode) -> [KeySpec] {
        let modeKey: KeyKind = mode == .symbols ? .letters : .numbers
        return [
            KeySpec(modeKey, 1.15),
            KeySpec(.emoji, 0.86),
            KeySpec(.microphone, 0.86),
            KeySpec(.space, 3.2),
            KeySpec(.punctuation, 0.86),
            KeySpec(.returnKey, 1.0)
        ]
    }
}
