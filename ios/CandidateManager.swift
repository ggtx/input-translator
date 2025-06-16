import Foundation
import UIKit

class CandidateManager {
    
    // MARK: - Properties
    private var candidates: [String] = []
    private var selectedIndex: Int = 0
    private let maxCandidates = 8
    
    private let textChecker = UITextChecker()
    
    // MARK: - Public Methods
    func generateCandidates(for input: String) -> [String] {
        if input.isEmpty {
            candidates = []
            return candidates
        }
        
        let range = NSRange(location: 0, length: input.count)
        let suggestions = textChecker.completions(
            forPartialWordRange: range,
            in: input,
            language: "zh-Hans"
        ) ?? []
        
        candidates = Array(suggestions.prefix(maxCandidates))
        selectedIndex = 0
        
        return candidates
    }
    
    func getCandidates() -> [String] {
        return candidates
    }
    
    func getSelectedIndex() -> Int {
        return selectedIndex
    }
    
    func selectCandidate(at index: Int) -> String? {
        guard index >= 0 && index < candidates.count else {
            return nil
        }
        
        selectedIndex = index
        return candidates[index]
    }
    
    func getSelectedCandidate() -> String? {
        guard selectedIndex >= 0 && selectedIndex < candidates.count else {
            return nil
        }
        return candidates[selectedIndex]
    }
    
    func moveSelectionUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    func moveSelectionDown() {
        if selectedIndex < candidates.count - 1 {
            selectedIndex += 1
        }
    }
    
    func clearCandidates() {
        candidates = []
        selectedIndex = 0
    }
    
    func hasCandidates() -> Bool {
        return !candidates.isEmpty
    }
    
    func getCandidateCount() -> Int {
        return candidates.count
    }
    
    // MARK: - Cache Management
    private var candidateCache: [String: [String]] = [:]
    private let maxCacheSize = 100
    
    func getCachedCandidates(for input: String) -> [String]? {
        return candidateCache[input]
    }
    
    func cacheCandidates(_ candidates: [String], for input: String) {
        if candidateCache.count >= maxCacheSize {
            let keysToRemove = Array(candidateCache.keys.prefix(10))
            for key in keysToRemove {
                candidateCache.removeValue(forKey: key)
            }
        }
        
        candidateCache[input] = candidates
    }
    
    func clearCache() {
        candidateCache.removeAll()
    }
    
    // MARK: - Enhanced Candidate Generation
    func generateEnhancedCandidates(for input: String) -> [String] {
        if let cachedCandidates = getCachedCandidates(for: input) {
            candidates = cachedCandidates
            selectedIndex = 0
            return candidates
        }
        
        var allCandidates: [String] = []
        
        let range = NSRange(location: 0, length: input.count)
        if let systemSuggestions = textChecker.completions(
            forPartialWordRange: range,
            in: input,
            language: "zh-Hans"
        ) {
            allCandidates.append(contentsOf: systemSuggestions)
        }
        
        let uniqueCandidates = Array(Set(allCandidates)).prefix(maxCandidates)
        candidates = Array(uniqueCandidates)
        selectedIndex = 0
        
        cacheCandidates(candidates, for: input)
        
        return candidates
    }
}
