import ServiceManagement

/// Launch At Login Manager
/// Uses SMAppService (macOS 13+) to manage login items
/// Note: Only works inside a signed .app bundle, won't work in swift run dev mode
enum LaunchAtLoginManager {
    
    /// Whether it is running in a valid app bundle environment
    private static var isValidAppBundle: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundleURL.pathExtension == "app"
    }
    
    /// Whether launch at login is currently enabled
    static var isEnabled: Bool {
        guard isValidAppBundle else { return false }
        return SMAppService.mainApp.status == .enabled
    }
    
    /// Set launch at login status
    /// - Parameter enabled: Whether to enable
    /// - Returns: Whether the operation succeeded
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        guard isValidAppBundle else {
            print("⚠️ Not a valid app bundle environment, skipping launch at login settings (Dev Mode)")
            return false
        }
        
        do {
            if enabled {
                // Register launch at login
                if SMAppService.mainApp.status == .enabled {
                    print("✅ Launch at login already set")
                    return true
                }
                try SMAppService.mainApp.register()
                print("✅ Launch at login enabled")
            } else {
                // Unregister launch at login
                if SMAppService.mainApp.status != .enabled {
                    print("✅ Launch at login not enabled")
                    return true
                }
                try SMAppService.mainApp.unregister()
                print("✅ Launch at login disabled")
            }
            return true
        } catch {
            print("❌ Failed to set launch at login: \(error)")
            return false
        }
    }
    
    /// Get current status description
    static var statusDescription: String {
        guard isValidAppBundle else {
            return "Dev Mode (Unavailable)"
        }
        switch SMAppService.mainApp.status {
        case .notRegistered:
            return "Not Registered"
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Requires Approval"
        case .notFound:
            return "App Not Found"
        @unknown default:
            return "Unknown Status"
        }
    }
}
