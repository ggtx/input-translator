import UIKit
import MLKitTranslate

class TranslateKeyboard: UIInputViewController {
    /// When true, translated English will be sent instead of the Chinese text.
    private var translateMode = true
    /// Buffer that accumulates pinyin from the user.
    private var pinyinBuffer = ""
    /// Simple in-memory cache of previous translations.
    private var translationCache: [String: String] = [:]

    private let pinyinField = UITextField()
    private let candidateLabel = UILabel()
    private let modeControl = UISegmentedControl(items: ["EN", "ZH"])
    private let sendButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        pinyinField.placeholder = "Type Pinyin"
        pinyinField.borderStyle = .roundedRect
        pinyinField.autocorrectionType = .no
        pinyinField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        candidateLabel.font = .systemFont(ofSize: 18)
        candidateLabel.textAlignment = .center

        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [pinyinField, candidateLabel, modeControl, sendButton])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
    }

    @objc private func textChanged() {
        guard let text = pinyinField.text else { return }
        handlePinyinInput(text)
    }

    @objc private func modeChanged() {
        translateMode = modeControl.selectedSegmentIndex == 0
    }

    @objc private func sendTapped() {
        let chinese = candidateLabel.text ?? ""
        guard !chinese.isEmpty else { return }

        translateText(chinese) { [weak self] english in
            guard let self = self else { return }
            let output = self.translateMode ? english : chinese
            self.insertText(output)
            self.resetInput()
        }
    }

    // MARK: - Pinyin Processing

    func handlePinyinInput(_ input: String) {
        pinyinBuffer = input
        updateCandidates()
    }

    func generateCandidates(_ pinyin: String) -> [String] {
        let table: [String: String] = [
            "ni": "你",
            "hao": "好",
            "shi": "是",
            "wo": "我",
            "zai": "在"
        ]
        if let candidate = table[pinyin] {
            return [candidate]
        }
        return []
    }

    private func updateCandidates() {
        let candidates = generateCandidates(pinyinBuffer)
        candidateLabel.text = candidates.first ?? pinyinBuffer
    }

    // MARK: - Translation

    func translateText(_ chinese: String, completion: @escaping (String) -> Void) {
        if let cached = translationCache[chinese] {
            completion(cached)
            return
        }

        let options = TranslatorOptions(sourceLanguage: .chinese, targetLanguage: .english)
        let translator = Translator.translator(options: options)
        let conditions = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)
        translator.downloadModelIfNeeded(with: conditions) { [weak self] error in
            guard error == nil else {
                completion(chinese)
                return
            }
            translator.translate(chinese) { text, _ in
                let result = text ?? chinese
                self?.translationCache[chinese] = result
                completion(result)
            }
        }
    }

    // MARK: - Output

    func insertText(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    private func resetInput() {
        pinyinBuffer = ""
        pinyinField.text = ""
        candidateLabel.text = ""
    }
}
