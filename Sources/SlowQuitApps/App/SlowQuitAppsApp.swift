import SwiftUI

/// Slow Quit Apps Main Entry
/// A macOS tool to prevent accidental Cmd+Q touches
@main
struct SlowQuitAppsApp: App {
    /// App Delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar app, no main window needed
        Settings {
            SettingsWindowView()
        }
    }
}
