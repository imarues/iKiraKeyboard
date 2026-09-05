import UIKit

class KeyButton: UIButton {
    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?
    private var longPressTriggered = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = KeyboardTheme.cornerRadius
        layer.borderWidth = 1
        layer.borderColor = KeyboardTheme.border.cgColor
        titleLabel?.font = .systemFont(ofSize: 25, weight: .regular)
        setTitleColor(KeyboardTheme.text, for: .normal)
        backgroundColor = KeyboardTheme.key
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        let press = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        press.minimumPressDuration = 0.48
        addGestureRecognizer(press)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func touchDown() {
        longPressTriggered = false
        UIView.animate(withDuration: 0.06) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.backgroundColor = KeyboardTheme.keyPressed
        }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.09) {
            self.transform = .identity
            self.backgroundColor = self.tag == 99 ? KeyboardTheme.specialKey : KeyboardTheme.key
        }
    }

    @objc private func tapped() {
        guard !longPressTriggered else { return }
        onTap?()
    }

    @objc private func longPressed(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            longPressTriggered = true
            onLongPress?()
        }
    }
}

final class SpaceKeyButton: KeyButton {
    private let subtitle = UILabel()
    private let leftArrow = UIImageView(image: UIImage(systemName: "chevron.left"))
    private let rightArrow = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        subtitle.text = "iKira Keyboard"
        subtitle.font = .systemFont(ofSize: 10, weight: .semibold)
        subtitle.textColor = KeyboardTheme.secondaryText
        subtitle.textAlignment = .center
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        leftArrow.tintColor = KeyboardTheme.secondaryText
        rightArrow.tintColor = KeyboardTheme.secondaryText
        [leftArrow,rightArrow].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }
        addSubview(subtitle)
        NSLayoutConstraint.activate([
            subtitle.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            leftArrow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), leftArrow.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightArrow.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), rightArrow.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
