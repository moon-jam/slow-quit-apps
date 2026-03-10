import Cocoa
import SwiftUI

/// App Delegate
/// Manages app lifecycle and menu bar icon
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Status bar icon
    private var statusItem: NSStatusItem?
    
    /// Settings window
    private var settingsWindow: NSWindow?
    
    /// App State
    private let appState = AppState.shared
    
    /// Accessibility permission check timer
    private var accessibilityCheckTimer: Timer?
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar icon
        setupStatusItem()
        
        // Hide Dock icon (run as menu bar app)
        NSApp.setActivationPolicy(.accessory)
        
        // Check accessibility permissions and start monitoring
        startMonitoringWithAccessibilityCheck()
        
        print("✅ \(Constants.App.name) started")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        accessibilityCheckTimer?.invalidate()
        QuitProgressController.shared.stop()
        print("🛑 \(Constants.App.name) terminated")
    }
    
    // MARK: - Accessibility Permission Check
    
    /// Start monitoring and check permissions
    private func startMonitoringWithAccessibilityCheck() {
        if AccessibilityManager.shared.isAccessibilityEnabled {
            // Permission granted, start directly
            print("✅ Accessibility permission granted")
            QuitProgressController.shared.start()
        } else {
            // Request permission and start polling check
            print("⚠️ Please grant accessibility permission, waiting...")
            AccessibilityManager.shared.requestAccessibility()
            startAccessibilityPolling()
        }
    }
    
    /// Start polling check for permission status
    private func startAccessibilityPolling() {
        accessibilityCheckTimer?.invalidate()
        accessibilityCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if AccessibilityManager.shared.isAccessibilityEnabled {
                    self.accessibilityCheckTimer?.invalidate()
                    self.accessibilityCheckTimer = nil
                    print("✅ Accessibility permission granted, starting monitoring...")
                    QuitProgressController.shared.start()
                }
            }
        }
    }
    
    // MARK: - Menu Bar Icon
    
    /// Setup status bar icon
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        // Setup icon
        button.image = NSImage(systemSymbolName: "hand.raised.fill", accessibilityDescription: "Slow Quit Apps")
        button.image?.size = NSSize(width: 18, height: 18)
        
        // Create menu
        let menu = NSMenu()
        
        // Enable / Disable
        let enableItem = NSMenuItem(
            title: appState.isEnabled ? "Disable" : "Enable",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enableItem.target = self
        menu.addItem(enableItem)
        
        menu.addItem(.separator())
        
        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit \(Constants.App.name)",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    // MARK: - Menu Actions
    
    /// Toggle enable status
    @objc private func toggleEnabled() {
        appState.toggleEnabled()
        // Update menu title
        if let menu = statusItem?.menu,
           let enableItem = menu.items.first {
            enableItem.title = appState.isEnabled ? "Disable" : "Enable"
        }
    }
    
    /// Open settings window
    @objc private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create settings window
        let contentView = SettingsWindowView()
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "\(Constants.App.name) Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(
            width: Constants.Window.settingsWidth,
            height: Constants.Window.settingsHeight
        ))
        window.center()
        
        // Clean up reference when window closes
        window.isReleasedWhenClosed = false
        
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Quit app
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
