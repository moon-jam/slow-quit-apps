import Foundation

/// Application Constants Definition
enum Constants {
    /// App Information
    enum App {
        static let name = "Slow Quit Apps"
        static let bundleIdentifier = "com.slowquitapps.app"
        static let version = "1.0.0"
    }
    
    /// Keyboard Shortcut Related
    enum Keyboard {
        /// Key code for Command + Q
        static let qKeyCode: UInt16 = 12
        /// Command modifier key
        static let commandModifier: UInt = 1 << 20
    }
    
    /// Progress Bar Configuration
    enum Progress {
        /// Default hold duration (seconds)
        static let defaultHoldDuration: Double = 1.0
        /// Minimum hold duration
        static let minHoldDuration: Double = 0.3
        /// Maximum hold duration
        static let maxHoldDuration: Double = 3.0
        /// Progress update frequency (seconds)
        static let updateInterval: Double = 1.0 / 60.0
    }
    
    /// Window Dimensions
    enum Window {
        /// Progress bar window width
        static let overlayWidth: CGFloat = 200
        /// Progress bar window height
        static let overlayHeight: CGFloat = 60
        /// Settings window width
        static let settingsWidth: CGFloat = 500
        /// Settings window height
        static let settingsHeight: CGFloat = 350
    }
}
