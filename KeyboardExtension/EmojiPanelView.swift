import UIKit

final class EmojiPanelView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let emojis = Array("😀😃😄😁😆😅😂🤣😊🙂🙃😉😍🥰😘😎🤩🥳😢😭😡🤯😱🤔🫡👍👎👌✌️🤞🤝👏🙏❤️🩷🧡💛💚💙💜🖤🤍🔥✨🎉💯✅❌⚡️🌙☀️⭐️🍎☕️🚗✈️📱💻📷")
    private var collectionView: UICollectionView!
    var onInsert: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        let layout = UICollectionViewFlowLayout(); layout.minimumInteritemSpacing = 2; layout.minimumLineSpacing = 2
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = KeyboardTheme.background
        collectionView.dataSource = self; collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "e")
        addSubview(collectionView)
        NSLayoutConstraint.activate([collectionView.topAnchor.constraint(equalTo: topAnchor),collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { emojis.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: "e", for: indexPath)
        c.contentView.subviews.forEach { $0.removeFromSuperview() }
        let l = UILabel(frame: c.contentView.bounds); l.autoresizingMask = [.flexibleWidth,.flexibleHeight]; l.textAlignment = .center; l.font = .systemFont(ofSize: 26); l.text = String(emojis[indexPath.item]); c.contentView.addSubview(l)
        return c
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: floor(collectionView.bounds.width / 8) - 2, height: 42)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { onInsert?(String(emojis[indexPath.item])) }
}
