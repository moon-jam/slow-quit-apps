import Foundation

/// Supported language types
/// Uses ISO 639-1 standard language codes
enum Language: String, Codable, CaseIterable, Sendable {
    case en = "en"
    case zhTW = "zh-TW"
    case zhCN = "zh-CN"
    case ja = "ja"
    case ru = "ru"
    
    /// Localized display name of the language
    var displayName: String {
        switch self {
        case .en: "English"
        case .zhTW: "繁體中文"
        case .zhCN: "简体中文"
        case .ja: "日本語"
        case .ru: "Русский"
        }
    }
    
    /// Corresponding JSON file name
    var fileName: String {
        rawValue
    }
}
