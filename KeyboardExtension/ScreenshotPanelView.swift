import UIKit
import Photos

final class ScreenshotPanelView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var assets: [PHAsset] = []
    private var collectionView: UICollectionView!
    private let messageLabel = UILabel()
    private var refreshTimer: Timer?
    var onStatus: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardTheme.background
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 6
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ScreenshotCell.self, forCellWithReuseIdentifier: "shot")
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textColor = KeyboardTheme.secondaryText
        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2
        addSubview(collectionView); addSubview(messageLabel)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 4), collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6), collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6), collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor), messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor), messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 18), messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -18)
        ])
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in self?.refresh() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { refreshTimer?.invalidate() }

    func refresh() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            assets = []; collectionView.reloadData(); messageLabel.isHidden = false
            messageLabel.text = "فعّل صلاحية الصور من تطبيق iKira Keyboard"
            return
        }
        let since = Date().addingTimeInterval(-30 * 60)
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "creationDate >= %@", since as NSDate)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var found: [PHAsset] = []
        result.enumerateObjects { asset, _, stop in
            if asset.mediaSubtypes.contains(.photoScreenshot) { found.append(asset) }
            if found.count >= 30 { stop.pointee = true }
        }
        assets = found
        messageLabel.isHidden = !assets.isEmpty
        messageLabel.text = assets.isEmpty ? "لا توجد Screenshots خلال آخر 30 دقيقة" : nil
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { assets.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "shot", for: indexPath) as! ScreenshotCell
        let asset = assets[indexPath.item]
        cell.representedID = asset.localIdentifier
        let options = PHImageRequestOptions(); options.deliveryMode = .opportunistic; options.resizeMode = .fast
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 260, height: 260), contentMode: .aspectFill, options: options) { image, _ in
            guard cell.representedID == asset.localIdentifier else { return }
            cell.imageView.image = image
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 12) / 3)
        return CGSize(width: width, height: 78)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = assets[indexPath.item]
        let options = PHImageRequestOptions(); options.deliveryMode = .highQualityFormat; options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 2048, height: 2048), contentMode: .aspectFit, options: options) { [weak self] image, _ in
            guard let image else { return }
            UIPasteboard.general.image = image
            DispatchQueue.main.async {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                self?.onStatus?("تم نسخ لقطة الشاشة — استخدم لصق داخل التطبيق")
            }
        }
    }
}

final class ScreenshotCell: UICollectionViewCell {
    let imageView = UIImageView()
    var representedID: String?
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = contentView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        contentView.layer.cornerRadius = 9
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func prepareForReuse() { super.prepareForReuse(); representedID = nil; imageView.image = nil }
}
