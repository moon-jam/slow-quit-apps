import SwiftUI

/// Global Application State
/// Single source of truth, persistent using JSON file
@MainActor
@Observable
final class AppState {
    static let shared = AppState()
    
    // MARK: - Configuration Properties
    
    /// Enable require long press to quit function
    var isEnabled: Bool {
        didSet { saveConfig() }
    }
    
    /// Hold duration (seconds)
    var holdDuration: Double {
        didSet { saveConfig() }
    }
    
    /// Launch app at login
    var launchAtLogin: Bool {
        didSet {
            // Call system API to set launch at login
            LaunchAtLoginManager.setEnabled(launchAtLogin)
            saveConfig()
        }
    }
    
    /// Show progress bar animation
    var showProgressAnimation: Bool {
        didSet { saveConfig() }
    }
    
    /// Excluded apps list (can quit directly without long press)
    var excludedApps: [ManagedApp] {
        didSet { saveConfig() }
    }
    
    /// Current language
    var language: Language {
        didSet {
            I18n.shared.setLanguage(language)
            saveConfig()
        }
    }
    
    // MARK: - Runtime State (Not Persistent)
    
    /// Current quit progress (0.0 - 1.0)
    var quitProgress: Double = 0.0
    
    /// Is currently showing quit progress
    var isShowingQuitProgress: Bool = false
    
    /// Current target app's Bundle ID
    var targetAppBundleId: String?
    
    // MARK: - Initialization
    
    private init() {
        let config = ConfigManager.shared.load()
        self.isEnabled = config.isEnabled
        self.holdDuration = config.holdDuration
        // Read actual system state, instead of config file
        self.launchAtLogin = LaunchAtLoginManager.isEnabled
        self.showProgressAnimation = config.showProgressAnimation
        self.excludedApps = config.excludedApps
        self.language = config.language
        
        // Synchronize language to I18n engine upon init
        I18n.shared.setLanguage(config.language)
    }
    
    // MARK: - Persistence
    
    private func saveConfig() {
        let config = Config(
            isEnabled: isEnabled,
            holdDuration: holdDuration,
            launchAtLogin: launchAtLogin,
            showProgressAnimation: showProgressAnimation,
            excludedApps: excludedApps,
            language: language
        )
        ConfigManager.shared.save(config)
    }
    
    // MARK: - Actions
    
    func toggleEnabled() {
        isEnabled.toggle()
    }
    
    func setHoldDuration(_ duration: Double) {
        holdDuration = max(
            Constants.Progress.minHoldDuration,
            min(duration, Constants.Progress.maxHoldDuration)
        )
    }
    
    func addExcludedApp(_ app: ManagedApp) {
        guard !excludedApps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else {
            print("⚠️ App already exists in the list: \(app.bundleIdentifier)")
            return
        }
        excludedApps.append(app)
        print("✅ Added app: \(app.name)")
    }
    
    func removeExcludedApp(_ app: ManagedApp) {
        excludedApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
    }
    
    func isAppExcluded(_ bundleId: String) -> Bool {
        excludedApps.contains { $0.bundleIdentifier == bundleId && $0.isExcluded }
    }
    
    func startQuitProgress(for bundleId: String) {
        targetAppBundleId = bundleId
        quitProgress = 0.0
        isShowingQuitProgress = true
    }
    
    func updateQuitProgress(_ progress: Double) {
        quitProgress = min(1.0, max(0.0, progress))
    }
    
    func cancelQuitProgress() {
        quitProgress = 0.0
        isShowingQuitProgress = false
        targetAppBundleId = nil
    }
    
    func completeQuit() {
        quitProgress = 1.0
        isShowingQuitProgress = false
    }
    
    func resetToDefaults() {
        let config = ConfigManager.shared.reset()
        isEnabled = config.isEnabled
        holdDuration = config.holdDuration
        launchAtLogin = config.launchAtLogin
        showProgressAnimation = config.showProgressAnimation
        excludedApps = config.excludedApps
        language = config.language
    }
    
    // MARK: - Import/Export
    
    func exportConfig(to url: URL) throws {
        try ConfigManager.shared.exportConfig(to: url)
    }
    
    func importConfig(from url: URL) throws {
        let config = try ConfigManager.shared.importConfig(from: url)
        isEnabled = config.isEnabled
        // Clamp holdDuration to valid range to prevent malicious config files from setting extreme values
        holdDuration = max(Constants.Progress.minHoldDuration,
                           min(config.holdDuration, Constants.Progress.maxHoldDuration))
        launchAtLogin = config.launchAtLogin
        showProgressAnimation = config.showProgressAnimation
        excludedApps = config.excludedApps
        language = config.language
    }
}
