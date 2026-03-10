import Foundation

/// UserDefaults Key Definition
enum DefaultsKey: String {
    case isEnabled = "isEnabled"
    case holdDuration = "holdDuration"
    case showMenuBarIcon = "showMenuBarIcon"
    case launchAtLogin = "launchAtLogin"
    case showProgressAnimation = "showProgressAnimation"
    case excludedApps = "excludedApps"
}

/// UserDefaults Storage Manager
/// Provides type-safe configuration reading and writing
@MainActor
final class Defaults {
    /// Singleton Instance
    static let shared = Defaults()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    // MARK: - Basic Type Read/Write
    
    /// Read Boolean value
    func bool(for key: DefaultsKey, default defaultValue: Bool = false) -> Bool {
        guard defaults.object(forKey: key.rawValue) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key.rawValue)
    }
    
    /// Write Boolean value
    func set(_ value: Bool, for key: DefaultsKey) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    /// Read Double value
    func double(for key: DefaultsKey, default defaultValue: Double = 0) -> Double {
        guard defaults.object(forKey: key.rawValue) != nil else {
            return defaultValue
        }
        return defaults.double(forKey: key.rawValue)
    }
    
    /// Write Double value
    func set(_ value: Double, for key: DefaultsKey) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    // MARK: - Codable Object Read/Write
    
    /// Read Encodable object
    func object<T: Decodable>(for key: DefaultsKey, type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }
        return try? decoder.decode(type, from: data)
    }
    
    /// Write Encodable object
    func set<T: Encodable>(_ value: T, for key: DefaultsKey) {
        guard let data = try? encoder.encode(value) else {
            return
        }
        defaults.set(data, forKey: key.rawValue)
    }
    
    // MARK: - Convenience Methods
    
    /// Load full configuration
    func loadConfig() -> AppConfig {
        AppConfig(
            isEnabled: bool(for: .isEnabled, default: true),
            holdDuration: double(for: .holdDuration, default: Constants.Progress.defaultHoldDuration),
            showMenuBarIcon: bool(for: .showMenuBarIcon, default: true),
            launchAtLogin: bool(for: .launchAtLogin, default: false),
            showProgressAnimation: bool(for: .showProgressAnimation, default: true)
        )
    }
    
    /// Save full configuration
    func saveConfig(_ config: AppConfig) {
        set(config.isEnabled, for: .isEnabled)
        set(config.holdDuration, for: .holdDuration)
        set(config.showMenuBarIcon, for: .showMenuBarIcon)
        set(config.launchAtLogin, for: .launchAtLogin)
        set(config.showProgressAnimation, for: .showProgressAnimation)
    }
    
    /// Load excluded apps list
    func loadExcludedApps() -> [ManagedApp] {
        object(for: .excludedApps, type: [ManagedApp].self) ?? ManagedApp.systemDefaults
    }
    
    /// Save excluded apps list
    func saveExcludedApps(_ apps: [ManagedApp]) {
        set(apps, for: .excludedApps)
    }
}
