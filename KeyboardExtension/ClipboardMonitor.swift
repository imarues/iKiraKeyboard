import UIKit

final class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount = UIPasteboard.general.changeCount
    var onCapture: (() -> Void)?

    func start() {
        stop()
        let pasteboard = UIPasteboard.general
        lastChangeCount = pasteboard.changeCount
        if pasteboard.hasStrings, let value = pasteboard.string, ClipboardStore.shared.capture(value) {
            onCapture?()
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let pasteboard = UIPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard pasteboard.hasStrings, let value = pasteboard.string else { return }
        if ClipboardStore.shared.capture(value) { onCapture?() }
    }

    deinit { stop() }
}
