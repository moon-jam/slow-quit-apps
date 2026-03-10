import Cocoa
import ApplicationServices

/// Accessibility Permission Manager
/// Responsible for checking and requesting accessibility permissions
@MainActor
final class AccessibilityManager {
    /// Singleton Instance
    static let shared = AccessibilityManager()
    
    private init() {}
    
    // MARK: - Permission Check
    
    /// Check if accessibility permission is granted
    var isAccessibilityEnabled: Bool {
        AXIsProcessTrusted()
    }
    
    /// Request accessibility permission
    /// Will pop up system dialog to guide user to authorize
    nonisolated func requestAccessibility() {
        // Use string literal to avoid concurrency safety issues
        // The value of kAXTrustedCheckOptionPrompt is "AXTrustedCheckOptionPrompt"
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Open accessibility settings in System Preferences
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        guard let settingsUrl = url else { return }
        NSWorkspace.shared.open(settingsUrl)
    }
    
    /// Check permission and request if needed
    /// - Returns: Current permission status
    @discardableResult
    func checkAndRequestIfNeeded() -> Bool {
        if isAccessibilityEnabled {
            return true
        }
        requestAccessibility()
        return false
    }
}
