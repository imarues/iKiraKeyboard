import UIKit
import SwiftUI

final class KeyboardViewController: UIInputViewController {
    private enum Panel { case keyboard, clipboard, screenshots, emoji }

    private let rootStack = UIStackView()
    private let featureBar = UIStackView()
    private let suggestionBar = UIStackView()
    private let mainArea = UIView()
    private let bottomRow = UIStackView()
    private let statusLabel = UILabel()
    private let clipboardMonitor = ClipboardMonitor()
    private let suggestionEngine = SuggestionEngine()
    private let translator = TranslationBridgeModel()
    private var translationHost: UIHostingController<TranslationBridgeView>!
    private var supplementaryLexicon: [String] = []
    private var language: KeyboardLanguage = .arabic
    private var mode: KeyboardMode = .letters
    private var shifted = false
    private var activePanel: Panel = .keyboard
    private var currentPanelView: UIView?
    private var contextTimer: Timer?
    private var lastContext = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        language = KeyboardLanguage(rawValue: AppGroup.defaults.string(forKey: SharedKeys.currentLanguage) ?? "ar") ?? .arabic
        setupUI()
        installTranslationBridge()
        requestSupplementaryLexicon { [weak self] lexicon in
            self?.supplementaryLexicon = lexicon.entries.map(\.userInput)
            self?.refreshSuggestions()
        }
        clipboardMonitor.onCapture = { [weak self] in
            if let panel = self?.currentPanelView as? ClipboardPanelView { panel.reload() }
            self?.showStatus("تم حفظ نسخة جديدة في الحافظة")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if hasFullAccess { clipboardMonitor.start() }
        contextTimer = Timer.scheduledTimer(withTimeInterval: 0.28, repeats: true) { [weak self] _ in self?.pollContext() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clipboardMonitor.stop(); contextTimer?.invalidate(); contextTimer = nil
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refreshSuggestions()
    }

    private func setupUI() {
        view.backgroundColor = KeyboardTheme.background
        rootStack.axis = .vertical
        rootStack.spacing = KeyboardTheme.rowGap
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            rootStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
            view.heightAnchor.constraint(greaterThanOrEqualToConstant: 318)
        ])

        featureBar.axis = .horizontal; featureBar.distribution = .fillEqually; featureBar.spacing = 4
        featureBar.backgroundColor = KeyboardTheme.toolbar; featureBar.layer.cornerRadius = 0
        featureBar.heightAnchor.constraint(equalToConstant: 42).isActive = true
        rootStack.addArrangedSubview(featureBar)
        addFeatureButton(symbol: "doc.on.clipboard", accessibility: "الحافظة") { [weak self] in self?.togglePanel(.clipboard) }
        addFeatureButton(symbol: "camera", accessibility: "لقطات الشاشة") { [weak self] in self?.togglePanel(.screenshots) }
        addFeatureButton(symbol: "character.bubble", accessibility: "ترجمة") { [weak self] in self?.translateCurrentMessage() }
        addFeatureButton(symbol: "face.smiling", accessibility: "إيموجي") { [weak self] in self?.togglePanel(.emoji) }

        suggestionBar.axis = .horizontal; suggestionBar.distribution = .fillEqually; suggestionBar.spacing = 1
        suggestionBar.heightAnchor.constraint(equalToConstant: 31).isActive = true
        rootStack.addArrangedSubview(suggestionBar)
        for _ in 0..<3 {
            let b = UIButton(type: .system); b.setTitleColor(.white, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium); b.backgroundColor = KeyboardTheme.background
            b.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            suggestionBar.addArrangedSubview(b)
        }

        mainArea.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(mainArea)
        mainArea.heightAnchor.constraint(greaterThanOrEqualToConstant: 184).isActive = true

        statusLabel.font = .systemFont(ofSize: 11, weight: .medium); statusLabel.textColor = KeyboardTheme.secondaryText; statusLabel.textAlignment = .center; statusLabel.isHidden = true
        statusLabel.heightAnchor.constraint(equalToConstant: 14).isActive = true
        rootStack.addArrangedSubview(statusLabel)

        bottomRow.axis = .horizontal; bottomRow.spacing = KeyboardTheme.keyGap; bottomRow.distribution = .fill
        bottomRow.heightAnchor.constraint(equalToConstant: 45).isActive = true
        rootStack.addArrangedSubview(bottomRow)
        rebuildKeyboard()
    }

    private func installTranslationBridge() {
        translationHost = UIHostingController(rootView: TranslationBridgeView(model: translator))
        addChild(translationHost)
        translationHost.view.translatesAutoresizingMaskIntoConstraints = false
        translationHost.view.backgroundColor = .clear
        view.addSubview(translationHost.view)
        NSLayoutConstraint.activate([
            translationHost.view.widthAnchor.constraint(equalToConstant: 1),
            translationHost.view.heightAnchor.constraint(equalToConstant: 1),
            translationHost.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            translationHost.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        translationHost.didMove(toParent: self)
    }

    private func addFeatureButton(symbol: String, accessibility: String, action: @escaping () -> Void) {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = .white
        button.accessibilityLabel = accessibility
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        featureBar.addArrangedSubview(button)
    }

    private func rebuildKeyboard() {
        if activePanel != .keyboard { showPanel(activePanel); rebuildBottomRow(); return }
        currentPanelView?.removeFromSuperview(); currentPanelView = nil
        mainArea.subviews.forEach { $0.removeFromSuperview() }
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = KeyboardTheme.rowGap; stack.distribution = .fillEqually; stack.translatesAutoresizingMaskIntoConstraints = false
        mainArea.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: mainArea.topAnchor),stack.bottomAnchor.constraint(equalTo: mainArea.bottomAnchor),stack.leadingAnchor.constraint(equalTo: mainArea.leadingAnchor),stack.trailingAnchor.constraint(equalTo: mainArea.trailingAnchor)])
        for row in KeyboardLayouts.mainRows(language: language, mode: mode, shifted: shifted) {
            stack.addArrangedSubview(makeRow(row))
        }
        rebuildBottomRow(); refreshSuggestions()
    }

    private func makeRow(_ specs: [KeySpec]) -> UIView {
        let row = UIStackView(); row.axis = .horizontal; row.spacing = KeyboardTheme.keyGap; row.distribution = .fill
        let total = specs.reduce(CGFloat.zero) { $0 + $1.weight }
        var first: UIView?
        for spec in specs {
            let button = makeKey(spec)
            row.addArrangedSubview(button)
            if let first, let firstSpec = specs.first {
                button.widthAnchor.constraint(equalTo: first.widthAnchor, multiplier: spec.weight / firstSpec.weight).isActive = true
            } else { first = button }
        }
        _ = total
        return row
    }

    private func makeKey(_ spec: KeySpec) -> KeyButton {
        let button: KeyButton = spec.kind == .space ? SpaceKeyButton() : KeyButton()
        button.onTap = { [weak self] in self?.handle(spec.kind) }
        switch spec.kind {
        case .delete, .shift, .numbers, .letters, .emoji, .microphone, .punctuation, .returnKey:
            button.tag = 99; button.backgroundColor = KeyboardTheme.specialKey
        default: break
        }
        switch spec.kind {
        case .spacer:
            button.isUserInteractionEnabled = false
            button.backgroundColor = .clear
            button.layer.borderWidth = 0
        case .text(let text): button.setTitle(text, for: .normal)
        case .delete: button.setImage(UIImage(systemName: "delete.left"), for: .normal); button.tintColor = .white
        case .shift: button.setImage(UIImage(systemName: shifted ? "shift.fill" : "shift"), for: .normal); button.tintColor = .white
        case .numbers: button.setTitle(language == .arabic ? "٣٢١" : "123", for: .normal); button.titleLabel?.font = .systemFont(ofSize: 19)
        case .letters: button.setTitle(language == .arabic ? "ابج" : "abc", for: .normal); button.titleLabel?.font = .systemFont(ofSize: 19)
        case .emoji: button.setImage(UIImage(systemName: "face.smiling"), for: .normal); button.tintColor = .white
        case .microphone: button.setImage(UIImage(systemName: "mic"), for: .normal); button.tintColor = .white
        case .space:
            button.setTitle("AR        EN", for: .normal)
            let pan = UIPanGestureRecognizer(target: self, action: #selector(spacePanned(_:))); button.addGestureRecognizer(pan)
        case .punctuation: button.setTitle(language == .arabic ? "؟!،" : "?!,", for: .normal); button.titleLabel?.font = .systemFont(ofSize: 14)
        case .returnKey:
            button.setImage(UIImage(systemName: "return"), for: .normal); button.tintColor = .white
            button.onLongPress = { [weak self] in self?.translateCurrentMessage() }
        }
        return button
    }

    private func rebuildBottomRow() {
        bottomRow.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let specs = KeyboardLayouts.bottomRow(language: language, mode: mode)
        var first: UIView?
        for spec in specs {
            let b = makeKey(spec); bottomRow.addArrangedSubview(b)
            if let first, let firstSpec = specs.first { b.widthAnchor.constraint(equalTo: first.widthAnchor, multiplier: spec.weight / firstSpec.weight).isActive = true }
            else { first = b }
        }
    }

    private func handle(_ kind: KeyKind) {
        haptic()
        switch kind {
        case .text(let text):
            textDocumentProxy.insertText(text)
            if language == .english && shifted { shifted = false; rebuildKeyboard() }
        case .delete: textDocumentProxy.deleteBackward()
        case .shift: shifted.toggle(); rebuildKeyboard()
        case .numbers: mode = .symbols; activePanel = .keyboard; rebuildKeyboard()
        case .letters: mode = .letters; activePanel = .keyboard; rebuildKeyboard()
        case .emoji: togglePanel(.emoji)
        case .microphone: showStatus("iOS لا يسمح للكيبوردات الخارجية باستخدام المايك مباشرة")
        case .space:
            learnCurrentWord(); textDocumentProxy.insertText(" ")
        case .punctuation: textDocumentProxy.insertText(language == .arabic ? "،" : ",")
        case .returnKey:
            learnCurrentWord(); textDocumentProxy.insertText("\n")
        case .spacer:
            break
        }
        refreshSuggestions()
    }

    @objc private func spacePanned(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let velocity = gesture.velocity(in: gesture.view)
        if abs(velocity.x) > 250 { switchLanguage() }
    }

    private func switchLanguage() {
        language = language.other; AppGroup.defaults.set(language.rawValue, forKey: SharedKeys.currentLanguage); shifted = false; mode = .letters; activePanel = .keyboard; rebuildKeyboard(); haptic()
    }

    private func togglePanel(_ panel: Panel) {
        activePanel = activePanel == panel ? .keyboard : panel
        rebuildKeyboard()
    }

    private func showPanel(_ panel: Panel) {
        mainArea.subviews.forEach { $0.removeFromSuperview() }
        let panelView: UIView
        switch panel {
        case .clipboard:
            let p = ClipboardPanelView(); p.onInsert = { [weak self] text in self?.textDocumentProxy.insertText(text) }; panelView = p
        case .screenshots:
            let p = ScreenshotPanelView(); p.onStatus = { [weak self] text in self?.showStatus(text) }; panelView = p
        case .emoji:
            let p = EmojiPanelView(); p.onInsert = { [weak self] emoji in self?.textDocumentProxy.insertText(emoji) }; panelView = p
        case .keyboard: rebuildKeyboard(); return
        }
        currentPanelView = panelView
        panelView.translatesAutoresizingMaskIntoConstraints = false; mainArea.addSubview(panelView)
        NSLayoutConstraint.activate([panelView.topAnchor.constraint(equalTo: mainArea.topAnchor),panelView.bottomAnchor.constraint(equalTo: mainArea.bottomAnchor),panelView.leadingAnchor.constraint(equalTo: mainArea.leadingAnchor),panelView.trailingAnchor.constraint(equalTo: mainArea.trailingAnchor)])
    }

    private func pollContext() {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        guard context != lastContext else { return }
        lastContext = context; refreshSuggestions()
    }

    private func refreshSuggestions() {
        let buttons = suggestionBar.arrangedSubviews.compactMap { $0 as? UIButton }
        guard activePanel == .keyboard, mode == .letters else { buttons.forEach { $0.setTitle("", for: .normal) }; return }
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let suggestions = suggestionEngine.suggestions(context: context, language: language, lexicon: supplementaryLexicon, limit: 3)
        for (i, button) in buttons.enumerated() { button.setTitle(i < suggestions.count ? suggestions[i] : "", for: .normal) }
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let suggestion = sender.title(for: .normal), !suggestion.isEmpty else { return }
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let current = suggestionEngine.currentWord(in: context)
        for _ in current { textDocumentProxy.deleteBackward() }
        textDocumentProxy.insertText(suggestion + " ")
        WordLearningStore.shared.learn(suggestion); haptic(); refreshSuggestions()
    }

    private func learnCurrentWord() {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        WordLearningStore.shared.learn(suggestionEngine.currentWord(in: context))
    }

    private func translateCurrentMessage() {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let message = currentMessage(from: context)
        guard !message.isEmpty else { showStatus("اكتب رسالة أولاً"); return }
        let source = detectLanguage(message)
        let target = source.other
        showStatus("جارِ الترجمة…")
        translator.translate(message, source: source, target: target) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let translated):
                    self?.textDocumentProxy.insertText("\n" + translated)
                    self?.showStatus(source == .arabic ? "تمت الترجمة إلى English" : "تمت الترجمة إلى العربية")
                case .failure(let error):
                    self?.showStatus("تعذر الترجمة: \(error.localizedDescription)")
                }
            }
        }
    }

    private func currentMessage(from context: String) -> String {
        let lines = context.components(separatedBy: .newlines)
        return (lines.last ?? context).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func detectLanguage(_ text: String) -> KeyboardLanguage {
        let arabicCount = text.unicodeScalars.filter { scalar in
            (0x0600...0x06FF).contains(Int(scalar.value)) || (0x0750...0x077F).contains(Int(scalar.value))
        }.count
        let latinCount = text.unicodeScalars.filter { (65...90).contains(Int($0.value)) || (97...122).contains(Int($0.value)) }.count
        return arabicCount >= latinCount ? .arabic : .english
    }

    private func showStatus(_ text: String) {
        statusLabel.text = text; statusLabel.isHidden = false
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideStatus), object: nil)
        perform(#selector(hideStatus), with: nil, afterDelay: 2.8)
    }
    @objc private func hideStatus() { statusLabel.isHidden = true }
    private func haptic() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}
