import UIKit
import MLKit

class TranslateKeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    private var keyboardView: TranslateKeyboardView!
    private let pinyinEngine = PinyinEngine()
    private let translationManager = TranslationManager()
    private let candidateManager = CandidateManager()
    
    private var currentPinyin: String = ""
    private var isTranslateMode: Bool = true
    private var candidates: [String] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
        setupTranslationManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateKeyboardHeight()
    }
    
    // MARK: - Setup
    private func setupKeyboard() {
        keyboardView = TranslateKeyboardView(frame: CGRect.zero)
        keyboardView.delegate = self
        view.addSubview(keyboardView)
        
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTranslationManager() {
        translationManager.delegate = self
        translationManager.initializeTranslator()
    }
    
    private func updateKeyboardHeight() {
        let height: CGFloat = isTranslateMode ? 280 : 220
        
        if let constraint = view.constraints.first(where: { $0.firstAttribute == .height }) {
            constraint.constant = height
        } else {
            view.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
    
    // MARK: - Input Handling
    private func handleKeyInput(_ key: String) {
        switch key {
        case "delete":
            handleDeleteKey()
        case "space":
            handleSpaceKey()
        case "return":
            handleReturnKey()
        case "translate_toggle":
            toggleTranslateMode()
        default:
            if key.rangeOfCharacter(from: CharacterSet.letters) != nil {
                handleLetterInput(key)
            }
        }
    }
    
    private func handleLetterInput(_ letter: String) {
        currentPinyin.append(letter)
        updateCandidates()
        keyboardView.updateInputDisplay(currentPinyin)
    }
    
    private func handleDeleteKey() {
        if !currentPinyin.isEmpty {
            currentPinyin.removeLast()
            updateCandidates()
            keyboardView.updateInputDisplay(currentPinyin)
        } else {
            textDocumentProxy.deleteBackward()
        }
    }
    
    private func handleSpaceKey() {
        if !candidates.isEmpty {
            selectCandidate(candidates.first!)
        } else {
            textDocumentProxy.insertText(" ")
        }
    }
    
    private func handleReturnKey() {
        textDocumentProxy.insertText("\n")
        clearInput()
    }
    
    private func toggleTranslateMode() {
        isTranslateMode.toggle()
        keyboardView.updateTranslateMode(isTranslateMode)
        updateKeyboardHeight()
        clearInput()
    }
    
    // MARK: - Candidate Management
    private func updateCandidates() {
        if currentPinyin.isEmpty {
            candidates = []
        } else {
            candidates = candidateManager.getCandidates(for: currentPinyin)
        }
        keyboardView.updateCandidates(candidates)
    }
    
    private func selectCandidate(_ candidate: String) {
        if isTranslateMode {
            translationManager.translateText(candidate) { [weak self] translation in
                DispatchQueue.main.async {
                    self?.showTranslationOptions(original: candidate, translation: translation)
                }
            }
        } else {
            textDocumentProxy.insertText(candidate)
            clearInput()
        }
    }
    
    private func showTranslationOptions(original: String, translation: String) {
        keyboardView.showTranslationOptions(original: original, translation: translation)
    }
    
    private func clearInput() {
        currentPinyin = ""
        candidates = []
        keyboardView.updateInputDisplay("")
        keyboardView.updateCandidates([])
    }
    
    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        translationManager.clearCache()
        candidateManager.clearCache()
    }
}

// MARK: - TranslateKeyboardViewDelegate
extension TranslateKeyboardViewController: TranslateKeyboardViewDelegate {
    func didTapKey(_ key: String) {
        handleKeyInput(key)
    }
    
    func didSelectCandidate(_ candidate: String) {
        selectCandidate(candidate)
    }
    
    func didSelectTranslation(original: String, useTranslation: Bool) {
        let textToInsert = useTranslation ? 
            translationManager.getCachedTranslation(for: original) ?? original : original
        textDocumentProxy.insertText(textToInsert)
        clearInput()
    }
    
    func didRequestNextKeyboard() {
        advanceToNextInputMode()
    }
}

// MARK: - TranslationManagerDelegate
extension TranslateKeyboardViewController: TranslationManagerDelegate {
    func translationDidComplete(_ translation: String, for originalText: String) {
    }
    
    func translationDidFail(with error: Error, for originalText: String) {
        print("Translation failed: \(error.localizedDescription)")
    }
}
