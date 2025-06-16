import UIKit

protocol TranslateKeyboardViewDelegate: AnyObject {
    func didTapKey(_ key: String)
    func didSelectCandidate(_ candidate: String)
    func didSelectTranslation(original: String, useTranslation: Bool)
    func didRequestNextKeyboard()
}

class TranslateKeyboardView: UIView {
    
    // MARK: - Properties
    weak var delegate: TranslateKeyboardViewDelegate?
    
    private var candidateScrollView: UIScrollView!
    private var candidateStackView: UIStackView!
    private var inputDisplayLabel: UILabel!
    private var translationOptionsView: UIView!
    private var keyboardStackView: UIStackView!
    private var toggleButton: UIButton!
    
    private var isTranslateMode: Bool = true
    private var currentCandidates: [String] = []
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        backgroundColor = UIColor.systemBackground
        
        setupInputDisplay()
        setupCandidateView()
        setupTranslationOptionsView()
        setupKeyboard()
        setupConstraints()
    }
    
    private func setupInputDisplay() {
        inputDisplayLabel = UILabel()
        inputDisplayLabel.font = UIFont.systemFont(ofSize: 16)
        inputDisplayLabel.textAlignment = .left
        inputDisplayLabel.backgroundColor = UIColor.systemGray6
        inputDisplayLabel.layer.cornerRadius = 6
        inputDisplayLabel.layer.masksToBounds = true
        inputDisplayLabel.text = ""
        inputDisplayLabel.textColor = UIColor.label
        
        // 添加内边距
        inputDisplayLabel.layer.sublayerTransform = CATransform3DMakeTranslation(8, 0, 0)
        
        addSubview(inputDisplayLabel)
    }
    
    private func setupCandidateView() {
        candidateScrollView = UIScrollView()
        candidateScrollView.showsHorizontalScrollIndicator = false
        candidateScrollView.backgroundColor = UIColor.systemGray6
        candidateScrollView.layer.cornerRadius = 6
        
        candidateStackView = UIStackView()
        candidateStackView.axis = .horizontal
        candidateStackView.distribution = .equalSpacing
        candidateStackView.spacing = 12
        candidateStackView.alignment = .center
        
        candidateScrollView.addSubview(candidateStackView)
        addSubview(candidateScrollView)
    }
    
    private func setupTranslationOptionsView() {
        translationOptionsView = UIView()
        translationOptionsView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        translationOptionsView.layer.cornerRadius = 8
        translationOptionsView.isHidden = true
        
        addSubview(translationOptionsView)
    }
    
    private func setupKeyboard() {
        keyboardStackView = UIStackView()
        keyboardStackView.axis = .vertical
        keyboardStackView.distribution = .fillEqually
        keyboardStackView.spacing = 8
        
        // 第一行键盘
        let firstRow = createKeyRow(["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"])
        
        // 第二行键盘
        let secondRow = createKeyRow(["a", "s", "d", "f", "g", "h", "j", "k", "l"])
        
        // 第三行键盘
        let thirdRow = createThirdRow()
        
        // 第四行（空格等）
        let fourthRow = createFourthRow()
        
        keyboardStackView.addArrangedSubview(firstRow)
        keyboardStackView.addArrangedSubview(secondRow)
        keyboardStackView.addArrangedSubview(thirdRow)
        keyboardStackView.addArrangedSubview(fourthRow)
        
        addSubview(keyboardStackView)
    }
    
    private func createKeyRow(_ keys: [String]) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 6
        
        for key in keys {
            let button = createKeyButton(key)
            stackView.addArrangedSubview(button)
        }
        
        return stackView
    }
    
    private func createThirdRow() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        
        // 翻译模式切换按钮
        toggleButton = UIButton(type: .system)
        toggleButton.setTitle("中/EN", for: .normal)
        toggleButton.backgroundColor = UIColor.systemBlue
        toggleButton.setTitleColor(.white, for: .normal)
        toggleButton.layer.cornerRadius = 6
        toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        
        // 字母键
        let letterKeys = ["z", "x", "c", "v", "b", "n", "m"]
        let letterStackView = UIStackView()
        letterStackView.axis = .horizontal
        letterStackView.distribution = .fillEqually
        letterStackView.spacing = 6
        
        for key in letterKeys {
            let button = createKeyButton(key)
            letterStackView.addArrangedSubview(button)
        }
        
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("⌫", for: .normal)
        deleteButton.backgroundColor = UIColor.systemGray4
        deleteButton.layer.cornerRadius = 6
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        stackView.addArrangedSubview(toggleButton)
        stackView.addArrangedSubview(letterStackView)
        stackView.addArrangedSubview(deleteButton)
        
        toggleButton.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.15).isActive = true
        letterStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.7).isActive = true
        deleteButton.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.15).isActive = true
        
        return stackView
    }
    
    private func createFourthRow() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        
        let nextKeyboardButton = UIButton(type: .system)
        nextKeyboardButton.setTitle("🌐", for: .normal)
        nextKeyboardButton.backgroundColor = UIColor.systemGray4
        nextKeyboardButton.layer.cornerRadius = 6
        nextKeyboardButton.addTarget(self, action: #selector(nextKeyboardTapped), for: .touchUpInside)
        
        let spaceButton = UIButton(type: .system)
        spaceButton.setTitle("空格", for: .normal)
        spaceButton.backgroundColor = UIColor.systemGray4
        spaceButton.layer.cornerRadius = 6
        spaceButton.addTarget(self, action: #selector(spaceButtonTapped), for: .touchUpInside)
        
        let returnButton = UIButton(type: .system)
        returnButton.setTitle("换行", for: .normal)
        returnButton.backgroundColor = UIColor.systemGray4
        returnButton.layer.cornerRadius = 6
        returnButton.addTarget(self, action: #selector(returnButtonTapped), for: .touchUpInside)
        
        stackView.addArrangedSubview(nextKeyboardButton)
        stackView.addArrangedSubview(spaceButton)
        stackView.addArrangedSubview(returnButton)
        
        nextKeyboardButton.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.2).isActive = true
        spaceButton.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.6).isActive = true
        returnButton.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.2).isActive = true
        
        return stackView
    }
    
    private func createKeyButton(_ key: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(key.uppercased(), for: .normal)
        button.backgroundColor = UIColor.systemBackground
        button.setTitleColor(UIColor.label, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.addTarget(self, action: #selector(keyButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func setupConstraints() {
        inputDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        candidateScrollView.translatesAutoresizingMaskIntoConstraints = false
        candidateStackView.translatesAutoresizingMaskIntoConstraints = false
        translationOptionsView.translatesAutoresizingMaskIntoConstraints = false
        keyboardStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            inputDisplayLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            inputDisplayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            inputDisplayLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            inputDisplayLabel.heightAnchor.constraint(equalToConstant: 30),
            
            candidateScrollView.topAnchor.constraint(equalTo: inputDisplayLabel.bottomAnchor, constant: 4),
            candidateScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            candidateScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            candidateScrollView.heightAnchor.constraint(equalToConstant: 40),
            
            candidateStackView.topAnchor.constraint(equalTo: candidateScrollView.topAnchor, constant: 8),
            candidateStackView.leadingAnchor.constraint(equalTo: candidateScrollView.leadingAnchor, constant: 8),
            candidateStackView.trailingAnchor.constraint(equalTo: candidateScrollView.trailingAnchor, constant: -8),
            candidateStackView.bottomAnchor.constraint(equalTo: candidateScrollView.bottomAnchor, constant: -8),
            candidateStackView.heightAnchor.constraint(equalTo: candidateScrollView.heightAnchor, constant: -16),
            
            translationOptionsView.topAnchor.constraint(equalTo: candidateScrollView.bottomAnchor, constant: 4),
            translationOptionsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            translationOptionsView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            translationOptionsView.heightAnchor.constraint(equalToConstant: 50),
            
            keyboardStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            keyboardStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            keyboardStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            keyboardStackView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }
    
    // MARK: - Public Methods
    func updateInputDisplay(_ text: String) {
        inputDisplayLabel.text = text.isEmpty ? "" : text
    }
    
    func updateCandidates(_ candidates: [String]) {
        currentCandidates = candidates
        
        candidateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for candidate in candidates {
            let button = UIButton(type: .system)
            button.setTitle(candidate, for: .normal)
            button.setTitleColor(UIColor.label, for: .normal)
            button.backgroundColor = UIColor.systemBackground
            button.layer.cornerRadius = 4
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
            button.addTarget(self, action: #selector(candidateButtonTapped(_:)), for: .touchUpInside)
            
            candidateStackView.addArrangedSubview(button)
        }
    }
    
    func updateTranslateMode(_ isOn: Bool) {
        isTranslateMode = isOn
        toggleButton.backgroundColor = isOn ? UIColor.systemBlue : UIColor.systemGray4
        toggleButton.setTitleColor(isOn ? .white : .label, for: .normal)
    }
    
    func showTranslationOptions(original: String, translation: String) {
        translationOptionsView.subviews.forEach { $0.removeFromSuperview() }
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        let chineseButton = UIButton(type: .system)
        chineseButton.setTitle("中文: \(original)", for: .normal)
        chineseButton.backgroundColor = UIColor.systemGray5
        chineseButton.layer.cornerRadius = 6
        chineseButton.addTarget(self, action: #selector(chineseOptionTapped), for: .touchUpInside)
        
        let englishButton = UIButton(type: .system)
        englishButton.setTitle("English: \(translation)", for: .normal)
        englishButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        englishButton.layer.cornerRadius = 6
        englishButton.addTarget(self, action: #selector(englishOptionTapped), for: .touchUpInside)
        
        stackView.addArrangedSubview(chineseButton)
        stackView.addArrangedSubview(englishButton)
        
        translationOptionsView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: translationOptionsView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: translationOptionsView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: translationOptionsView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: translationOptionsView.bottomAnchor, constant: -8)
        ])
        
        translationOptionsView.isHidden = false
        
        chineseButton.accessibilityIdentifier = original
        englishButton.accessibilityIdentifier = original
    }
    
    func hideTranslationOptions() {
        translationOptionsView.isHidden = true
    }
    
    // MARK: - Button Actions
    @objc private func keyButtonTapped(_ sender: UIButton) {
        guard let key = sender.title(for: .normal)?.lowercased() else { return }
        delegate?.didTapKey(key)
    }
    
    @objc private func deleteButtonTapped() {
        delegate?.didTapKey("delete")
    }
    
    @objc private func spaceButtonTapped() {
        delegate?.didTapKey("space")
    }
    
    @objc private func returnButtonTapped() {
        delegate?.didTapKey("return")
    }
    
    @objc private func toggleButtonTapped() {
        delegate?.didTapKey("translate_toggle")
    }
    
    @objc private func nextKeyboardTapped() {
        delegate?.didRequestNextKeyboard()
    }
    
    @objc private func candidateButtonTapped(_ sender: UIButton) {
        guard let candidate = sender.title(for: .normal) else { return }
        delegate?.didSelectCandidate(candidate)
    }
    
    @objc private func chineseOptionTapped(_ sender: UIButton) {
        guard let original = sender.accessibilityIdentifier else { return }
        delegate?.didSelectTranslation(original: original, useTranslation: false)
        hideTranslationOptions()
    }
    
    @objc private func englishOptionTapped(_ sender: UIButton) {
        guard let original = sender.accessibilityIdentifier else { return }
        delegate?.didSelectTranslation(original: original, useTranslation: true)
        hideTranslationOptions()
    }
}
