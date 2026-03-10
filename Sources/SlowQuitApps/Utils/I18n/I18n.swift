import Foundation

/// Internationalization translation engine
/// Uses JSON resource files, supports dot-notation path access
@MainActor
@Observable
final class I18n {
    static let shared = I18n()
    
    /// Current language (used to trigger view refresh)
    private(set) var currentLanguage: Language = .en
    
    /// Translation dictionary cache
    private var translations: [String: Any] = [:]
    
    private init() {
        // Initial load of default language
        loadTranslations(for: .en)
    }
    
    // MARK: - Public API
    
    /// Core translation function
    /// Supports dot-notation path: t("settings.general.title")
    func t(_ key: String) -> String {
        let components = key.split(separator: ".")
        var current: Any = translations
        
        // Parse path level by level
        for component in components {
            guard let dict = current as? [String: Any],
                  let next = dict[String(component)] else {
                // Return key itself when translation not found, for easier debugging
                return key
            }
            current = next
        }
        
        return (current as? String) ?? key
    }
    
    /// Switch language
    func setLanguage(_ language: Language) {
        guard language != currentLanguage else { return }
        loadTranslations(for: language)
        currentLanguage = language
    }
    
    // MARK: - Internal Implementation
    
    /// Load JSON translation file from Bundle
    private func loadTranslations(for language: Language) {
        // SPM resources use Bundle.module
        guard let url = Bundle.module.url(
            forResource: language.fileName,
            withExtension: "json",
            subdirectory: "Locales"
        ) else {
            print("⚠️ Translation file not found: \(language.fileName).json")
            // If non-English language fail to load, fallback to English
            if language != .en {
                loadTranslations(for: .en)
            }
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ Translation file format error: \(language.fileName).json")
                return
            }
            translations = json
        } catch {
            print("❌ Failed to load translation file: \(error)")
        }
    }
}

// MARK: - Global Convenience Functions

/// Global translation function, similar to React i18n's t()
/// Usage: Text(t("settings.general.title"))
@MainActor
func t(_ key: String) -> String {
    I18n.shared.t(key)
}
