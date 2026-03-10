import Cocoa
import SwiftUI

/// Quit Progress Overlay Window
/// Floats in the center of the screen to show quit progress
@MainActor
final class QuitOverlayWindow {
    /// Singleton Instance
    static let shared = QuitOverlayWindow()
    
    /// Window Instance
    private var window: NSPanel?
    
    /// Hosting View Controller
    private var hostingController: NSHostingController<QuitOverlayView>?
    
    /// Current Progress
    private var currentProgress: Double = 0
    
    /// Current App Name
    private var currentAppName: String = ""
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Show Progress Window
    func show(appName: String) {
        currentAppName = appName
        currentProgress = 0
        
        // Create or Update Window
        if window == nil {
            createWindow()
        }
        
        updateView()
        
        guard let window = window else { return }
        
        // Center on screen
        centerWindow(window)
        
        // Show window
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }
    
    /// Update Progress
    func updateProgress(_ progress: Double) {
        currentProgress = progress
        updateView()
    }
    
    /// Hide Window
    func hide() {
        window?.orderOut(nil)
        currentProgress = 0
    }
    
    // MARK: - Private Methods
    
    /// Create Window
    private func createWindow() {
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Constants.Window.overlayWidth,
                height: Constants.Window.overlayHeight + 40
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        
        // Create SwiftUI view
        let view = QuitOverlayView(
            progress: currentProgress,
            appName: currentAppName,
            animated: AppState.shared.showProgressAnimation
        )
        
        let hostingController = NSHostingController(rootView: view)
        panel.contentViewController = hostingController
        
        self.window = panel
        self.hostingController = hostingController
    }
    
    /// Update View
    private func updateView() {
        let view = QuitOverlayView(
            progress: currentProgress,
            appName: currentAppName,
            animated: AppState.shared.showProgressAnimation
        )
        hostingController?.rootView = view
    }
    
    /// Center window to screen
    private func centerWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let windowFrame = window.frame
        
        let x = screenFrame.midX - windowFrame.width / 2
        let y = screenFrame.midY - windowFrame.height / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
