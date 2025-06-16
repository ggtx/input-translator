import UIKit
import Foundation

class InputMethodManager {
    
    // MARK: - Properties
    private weak var textDocumentProxy: UITextDocumentProxy?
    private var currentInput: String = ""
    private var isComposing: Bool = false
    
    // MARK: - Initialization
    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
    }
    
    // MARK: - Public Methods
    func handleKeyInput(_ key: String) {
        switch key {
        case "delete":
            handleDelete()
        case "space":
            handleSpace()
        case "return":
            handleReturn()
        default:
            if key.count == 1 && key.rangeOfCharacter(from: .letters) != nil {
                handleLetterInput(key)
            }
        }
    }
    
    func getCurrentInput() -> String {
        return currentInput
    }
    
    func isCurrentlyComposing() -> Bool {
        return isComposing
    }
    
    func insertText(_ text: String) {
        textDocumentProxy?.insertText(text)
        clearComposition()
    }
    
    func clearComposition() {
        currentInput = ""
        isComposing = false
    }
    
    // MARK: - Private Methods
    private func handleLetterInput(_ letter: String) {
        currentInput += letter.lowercased()
        isComposing = true
    }
    
    private func handleDelete() {
        if isComposing && !currentInput.isEmpty {
            currentInput.removeLast()
            if currentInput.isEmpty {
                isComposing = false
            }
        } else {
            textDocumentProxy?.deleteBackward()
        }
    }
    
    private func handleSpace() {
        if isComposing {
            commitCurrentInput()
        } else {
            textDocumentProxy?.insertText(" ")
        }
    }
    
    private func handleReturn() {
        if isComposing {
            commitCurrentInput()
        }
        textDocumentProxy?.insertText("\n")
    }
    
    private func commitCurrentInput() {
        if !currentInput.isEmpty {
            textDocumentProxy?.insertText(currentInput)
        }
        clearComposition()
    }
    
    // MARK: - Helper Methods
    func getInputLength() -> Int {
        return currentInput.count
    }
    
    func hasInput() -> Bool {
        return !currentInput.isEmpty
    }
}
