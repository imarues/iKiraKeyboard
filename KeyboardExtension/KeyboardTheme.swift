import UIKit

enum KeyboardTheme {
    static let background = UIColor(red: 0.105, green: 0.115, blue: 0.145, alpha: 1)
    static let toolbar = UIColor(red: 0.235, green: 0.240, blue: 0.275, alpha: 1)
    static let key = UIColor(red: 0.235, green: 0.240, blue: 0.275, alpha: 1)
    static let keyPressed = UIColor(red: 0.33, green: 0.34, blue: 0.39, alpha: 1)
    static let specialKey = UIColor(red: 0.14, green: 0.15, blue: 0.18, alpha: 1)
    static let text = UIColor.white
    static let secondaryText = UIColor(white: 0.70, alpha: 1)
    static let border = UIColor.black.withAlphaComponent(0.72)
    static let accent = UIColor.systemBlue
    static let cornerRadius: CGFloat = 7
    static let keyGap: CGFloat = 5
    static let rowGap: CGFloat = 6
}
