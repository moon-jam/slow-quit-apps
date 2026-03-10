import Foundation

/// Managed App Model
/// Represents an excluded (whitelisted) or specially handled app
struct ManagedApp: Codable, Identifiable, Hashable, Sendable {
    /// App Bundle Identifier
    let bundleIdentifier: String
    
    /// App display name
    let name: String
    
    /// App icon path (optional)
    let iconPath: String?
    
    /// Is excluded (does not require long press to quit)
    var isExcluded: Bool
    
    // MARK: - Identifiable
    
    var id: String { bundleIdentifier }
    
    // MARK: - Convenience Initialization
    
    /// Create from a running app
    init(bundleIdentifier: String, name: String, iconPath: String? = nil, isExcluded: Bool = true) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.iconPath = iconPath
        self.isExcluded = isExcluded
    }
}

// MARK: - Common App Presets

extension ManagedApp {
    /// System default excluded apps list
    static let systemDefaults: [ManagedApp] = [
        ManagedApp(bundleIdentifier: "com.apple.finder", name: "Finder"),
        ManagedApp(bundleIdentifier: "com.apple.Terminal", name: "Terminal"),
    ]
}
