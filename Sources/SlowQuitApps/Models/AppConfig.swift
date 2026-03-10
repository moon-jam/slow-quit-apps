import Foundation

/// App Configuration Model
/// Stores all user preferences
struct AppConfig: Codable, Sendable {
    /// Enable require long press to quit function
    var isEnabled: Bool
    
    /// Hold duration (seconds)
    var holdDuration: Double
    
    /// Show menu bar icon
    var showMenuBarIcon: Bool
    
    /// Launch app at login
    var launchAtLogin: Bool
    
    /// Show progress bar animation
    var showProgressAnimation: Bool
    
    /// Default configuration
    static let `default` = AppConfig(
        isEnabled: true,
        holdDuration: 1.0,
        showMenuBarIcon: true,
        launchAtLogin: false,
        showProgressAnimation: true
    )
}
