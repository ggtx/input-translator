import Foundation
import MLKit

protocol TranslationManagerDelegate: AnyObject {
    func translationDidComplete(_ translation: String, for originalText: String)
    func translationDidFail(with error: Error, for originalText: String)
}

class TranslationManager {
    
    // MARK: - Properties
    weak var delegate: TranslationManagerDelegate?
    
    private var translator: Translator?
    private var translationCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "translation.cache", qos: .utility)
    private let translationQueue = DispatchQueue(label: "translation.work", qos: .userInitiated)
    
    private let maxCacheSize = 1000
    private let sourceLanguage = TranslateLanguage.chinese
    private let targetLanguage = TranslateLanguage.english
    
    // MARK: - Initialization
    init() {
        loadCacheFromDisk()
    }
    
    deinit {
        saveCacheToDisk()
    }
    
    // MARK: - Public Methods
    func initializeTranslator() {
        let options = TranslatorOptions(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        translator = Translator.translator(options: options)
        
        // 下载翻译模型
        downloadModelIfNeeded()
    }
    
    func translateText(_ text: String, completion: @escaping (String) -> Void) {
        // 首先检查缓存
        if let cachedTranslation = getCachedTranslation(for: text) {
            completion(cachedTranslation)
            return
        }
        
        // 执行翻译
        translationQueue.async { [weak self] in
            self?.performTranslation(text, completion: completion)
        }
    }
    
    func getCachedTranslation(for text: String) -> String? {
        return cacheQueue.sync {
            return translationCache[text]
        }
    }
    
    func clearCache() {
        cacheQueue.async { [weak self] in
            self?.translationCache.removeAll()
        }
    }
    
    // MARK: - Private Methods
    private func performTranslation(_ text: String, completion: @escaping (String) -> Void) {
        guard let translator = translator else {
            DispatchQueue.main.async {
                completion(text) // 如果翻译器不可用，返回原文
            }
            return
        }
        
        translator.translate(text) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.delegate?.translationDidFail(with: error, for: text)
                    completion(text) // 出错时返回原文
                }
                return
            }
            
            guard let translation = result else {
                DispatchQueue.main.async {
                    completion(text)
                }
                return
            }
            
            // 缓存翻译结果
            self?.cacheTranslation(original: text, translation: translation)
            
            DispatchQueue.main.async {
                self?.delegate?.translationDidComplete(translation, for: text)
                completion(translation)
            }
        }
    }
    
    private func cacheTranslation(original: String, translation: String) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 如果缓存已满，移除最旧的条目
            if self.translationCache.count >= self.maxCacheSize {
                let oldestKey = self.translationCache.keys.first
                if let key = oldestKey {
                    self.translationCache.removeValue(forKey: key)
                }
            }
            
            self.translationCache[original] = translation
        }
    }
    
    private func downloadModelIfNeeded() {
        let conditions = ModelDownloadConditions(
            allowsCellularAccess: false,
            allowsBackgroundDownloading: true
        )
        
        translator?.downloadModelIfNeeded(with: conditions) { error in
            if let error = error {
                print("Model download failed: \(error.localizedDescription)")
            } else {
                print("Translation model ready")
            }
        }
    }
    
    // MARK: - Cache Persistence
    private func loadCacheFromDisk() {
        cacheQueue.async { [weak self] in
            guard let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                              in: .userDomainMask).first else { return }
            
            let cacheURL = documentsPath.appendingPathComponent("translation_cache.plist")
            
            if let data = try? Data(contentsOf: cacheURL),
               let cache = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String] {
                self?.translationCache = cache
            }
        }
    }
    
    private func saveCacheToDisk() {
        cacheQueue.async { [weak self] in
            guard let self = self,
                  let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                              in: .userDomainMask).first else { return }
            
            let cacheURL = documentsPath.appendingPathComponent("translation_cache.plist")
            
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: self.translationCache, 
                                                             format: .xml, 
                                                             options: 0)
                try data.write(to: cacheURL)
            } catch {
                print("Failed to save cache: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Pre-loaded Common Translations
extension TranslationManager {
    func preloadCommonTranslations() {
        let commonPhrases = [
            "你好": "Hello",
            "谢谢": "Thank you",
            "不客气": "You're welcome",
            "再见": "Goodbye",
            "早安": "Good morning",
            "晚安": "Good night",
            "对不起": "Sorry",
            "没关系": "It's okay",
            "请": "Please",
            "是的": "Yes",
            "不是": "No",
            "可以": "Can",
            "不可以": "Cannot",
            "好的": "Okay",
            "明白": "Understand"
        ]
        
        cacheQueue.async { [weak self] in
            for (chinese, english) in commonPhrases {
                self?.translationCache[chinese] = english
            }
        }
    }
}
