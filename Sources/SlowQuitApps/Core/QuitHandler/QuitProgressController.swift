import Cocoa

/// Quit Progress Controller
/// Core logic: start timer on keyDown, stop timer on keyUp, trigger quit when duration is reached
@MainActor
final class QuitProgressController: KeyEventDelegate {
    static let shared = QuitProgressController()
    
    /// Progress Update Timer
    private var timer: Timer?
    
    /// Start Time for Key Press
    private var startTime: Date?
    
    /// Current Target App
    private var targetApp: NSRunningApplication?
    
    /// Whether the timer is currently running
    private var isRunning = false
    
    /// Safe timeout threshold (seconds) - prevents timer leak
    /// If no keyUp is received after holdDuration + this value, force stop
    private let safetyTimeout: TimeInterval = 1.0
    
    private let appState = AppState.shared
    private let overlayWindow = QuitOverlayWindow.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    func start() {
        KeyEventMonitor.shared.delegate = self
        KeyEventMonitor.shared.startMonitoring()
    }
    
    func stop() {
        KeyEventMonitor.shared.stopMonitoring()
        stopTimer()
    }
    
    // MARK: - KeyEventDelegate
    
    func keyEventMonitor(_ monitor: KeyEventMonitor, didReceiveKeyDown event: KeyEvent) {
        // Already timing, ignore duplicate keyDown (keyboard repeat)
        guard !isRunning else { return }
        
        guard appState.isEnabled else {
            // Quit immediately if disabled
            NSWorkspace.shared.frontmostApplication?.terminate()
            return
        }
        
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleId = app.bundleIdentifier else { return }
        
        // Debug: Print current app and exclusion status
        let isExcluded = appState.isAppExcluded(bundleId)
        print("🔍 Detected Cmd+Q: \(app.localizedName ?? "Unknown") [\(bundleId)] Excluded: \(isExcluded)")
        print("📋 Exclusion List: \(appState.excludedApps.map { "\($0.bundleIdentifier):\($0.isExcluded)" })")
        
        // Whitelisted apps quit directly
        if isExcluded {
            print("⚡ Direct quit (Excluded)")
            app.terminate()
            return
        }
        
        print("⏱️ Starting timer...")
        // Start timing
        startTimer(for: app)
    }
    
    func keyEventMonitor(_ monitor: KeyEventMonitor, didReceiveKeyUp event: KeyEvent) {
        // Stop immediately on keyUp
        stopTimer()
    }
    
    // MARK: - Timer
    
    private func startTimer(for app: NSRunningApplication) {
        // Clean up any remaining timer first
        stopTimer()
        
        isRunning = true
        startTime = Date()
        targetApp = app
        
        let appName = app.localizedName ?? "Unknown App"
        overlayWindow.show(appName: appName)
        appState.startQuitProgress(for: app.bundleIdentifier ?? "")
        
        // Update progress at 60fps
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }
    
    private func tick() {
        // Safety check: if state is inconsistent, stop immediately
        guard isRunning,
              let start = startTime,
              let app = targetApp else {
            stopTimer()
            return
        }
        
        // Check if target app is still running
        guard !app.isTerminated else {
            stopTimer()
            return
        }
        
        let elapsed = Date().timeIntervalSince(start)
        
        // Safety timeout check: prevent timer from leaking
        let maxDuration = appState.holdDuration + safetyTimeout
        if elapsed > maxDuration {
            print("⚠️ Safety timeout, forcing timer to stop")
            stopTimer()
            return
        }
        
        let progress = min(1.0, elapsed / appState.holdDuration)
        
        appState.updateQuitProgress(progress)
        overlayWindow.updateProgress(progress)
        
        if progress >= 1.0 {
            // Reached target duration, trigger quit
            let appToQuit = app
            stopTimer()
            appState.completeQuit()
            appToQuit.terminate()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        startTime = nil
        targetApp = nil
        isRunning = false
        
        appState.cancelQuitProgress()
        overlayWindow.hide()
    }
}
