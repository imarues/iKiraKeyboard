import UIKit

final class ClipboardPanelView: UIView, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let segmented = UISegmentedControl(items: ["الجديد بالبداية", "الجديد بالنهاية"])
    private var items: [ClipboardItem] = []
    var onInsert: ((String) -> Void)?
    var onChanged: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardTheme.background
        let header = UIStackView(arrangedSubviews: [segmented])
        header.axis = .horizontal
        header.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentIndex = ClipboardStore.shared.insertionPosition == .beginning ? 0 : 1
        segmented.addTarget(self, action: #selector(orderChanged), for: .valueChanged)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.08)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        addSubview(header); addSubview(tableView)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: 4), header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8), header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8), header.heightAnchor.constraint(equalToConstant: 34),
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4), tableView.leadingAnchor.constraint(equalTo: leadingAnchor), tableView.trailingAnchor.constraint(equalTo: trailingAnchor), tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        reload()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func reload() {
        items = ClipboardStore.shared.displayItems()
        tableView.reloadData()
    }

    @objc private func orderChanged() {
        ClipboardStore.shared.insertionPosition = segmented.selectedSegmentIndex == 0 ? .beginning : .end
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = items[indexPath.row]
        var config = UIListContentConfiguration.subtitleCell()
        config.text = (item.isPinned ? "📌 " : "") + item.text.replacingOccurrences(of: "\n", with: " ↵ ")
        config.textProperties.color = .white
        config.textProperties.numberOfLines = 1
        config.secondaryText = relativeDate(item.createdAt)
        config.secondaryTextProperties.color = KeyboardTheme.secondaryText
        cell.contentConfiguration = config
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onInsert?(items[indexPath.row].text)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let item = items[indexPath.row]
        return UIContextMenuConfiguration(identifier: item.id.uuidString as NSString, previewProvider: nil) { [weak self] _ in
            let pinTitle = item.isPinned ? "إلغاء التثبيت" : "تثبيت"
            let pin = UIAction(title: pinTitle, image: UIImage(systemName: item.isPinned ? "pin.slash" : "pin")) { _ in
                ClipboardStore.shared.togglePin(id: item.id); self?.reload(); self?.onChanged?()
            }
            let first = UIAction(title: "إلى البداية", image: UIImage(systemName: "arrow.up.to.line")) { _ in
                ClipboardStore.shared.moveToBeginning(id: item.id); self?.reload(); self?.onChanged?()
            }
            let last = UIAction(title: "إلى النهاية", image: UIImage(systemName: "arrow.down.to.line")) { _ in
                ClipboardStore.shared.moveToEnd(id: item.id); self?.reload(); self?.onChanged?()
            }
            let delete = UIAction(title: "مسح", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                ClipboardStore.shared.delete(id: item.id); self?.reload(); self?.onChanged?()
            }
            return UIMenu(children: [pin, first, last, delete])
        }
    }

    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter(); f.locale = Locale(identifier: "ar"); f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
