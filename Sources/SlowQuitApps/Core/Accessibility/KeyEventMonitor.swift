import Cocoa
import Carbon.HIToolbox

/// Keyboard event type
enum KeyEventType: Sendable {
    case keyDown
    case keyUp
    case flagsChanged  // Modifier keys changed
}

/// Keyboard event information
struct KeyEvent: Sendable {
    let keyCode: UInt16
    let modifiers: UInt
    let type: KeyEventType
    let timestamp: Date
    
    /// Whether Command key is held down
    var hasCommandModifier: Bool {
        (modifiers & NSEvent.ModifierFlags.command.rawValue) != 0
    }
    
    /// Whether it is the Q key
    var isQKey: Bool {
        keyCode == Constants.Keyboard.qKeyCode
    }
    
    /// Whether Command + Q combination is pressed down
    var isCmdQDown: Bool {
        type == .keyDown && isQKey && hasCommandModifier
    }
}

/// Keyboard event callback protocol
@MainActor
protocol KeyEventDelegate: AnyObject {
    /// Key down event
    func keyEventMonitor(_ monitor: KeyEventMonitor, didReceiveKeyDown event: KeyEvent)
    /// Key up event
    func keyEventMonitor(_ monitor: KeyEventMonitor, didReceiveKeyUp event: KeyEvent)
}

/// Global keyboard event monitor
/// Uses CGEvent Tap to monitor global keyboard events
@MainActor
final class KeyEventMonitor {
    /// Singleton instance
    static let shared = KeyEventMonitor()
    
    /// Event delegate
    weak var delegate: KeyEventDelegate?
    
    /// Event tap reference
    private var eventTap: CFMachPort?
    
    /// Run loop source
    private var runLoopSource: CFRunLoopSource?
    
    /// Is monitoring
    private(set) var isMonitoring: Bool = false
    
    /// Is Cmd+Q being held down (Q key pressed and Cmd held)
    private var isCmdQPressed: Bool = false
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start monitoring keyboard events
    func startMonitoring() {
        guard !isMonitoring else {
            print("⚠️ Event monitoring is already running")
            return
        }
        
        // Create event mask: monitor key down, key up, and modifier keys changed
        let eventMask = (1 << CGEventType.keyDown.rawValue) 
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        
        // Create monitor wrapper
        let wrapper = KeyEventMonitorWrapper.shared
        wrapper.monitor = self
        
        print("🔧 Creating event monitor...")
        
        // Create event tap
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: keyEventCallback,
            userInfo: Unmanaged.passUnretained(wrapper).toOpaque()
        ) else {
            print("❌ Cannot create event monitor, please check accessibility permission")
            return
        }
        
        eventTap = tap
        
        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        guard let source = runLoopSource else {
            print("❌ Cannot create run loop source")
            return
        }
        
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        isMonitoring = true
        print("✅ Keyboard event monitoring started, intercepting Cmd+Q")
    }
    
    /// Stop monitoring keyboard events
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
        isCmdQPressed = false
        
        print("🛑 Keyboard event monitoring stopped")
    }
    
    /// Re-enable event monitoring
    func reenableTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }
    
    /// Handle keyboard events
    func handleKeyEvent(_ keyEvent: KeyEvent) {
        switch keyEvent.type {
        case .keyDown:
            // Cmd+Q down
            if keyEvent.isCmdQDown {
                isCmdQPressed = true
                delegate?.keyEventMonitor(self, didReceiveKeyDown: keyEvent)
            }
            
        case .keyUp:
            // Q key released
            if keyEvent.isQKey && isCmdQPressed {
                isCmdQPressed = false
                delegate?.keyEventMonitor(self, didReceiveKeyUp: keyEvent)
            }
            
        case .flagsChanged:
            // Cmd key released (modifier changed)
            if !keyEvent.hasCommandModifier && isCmdQPressed {
                isCmdQPressed = false
                delegate?.keyEventMonitor(self, didReceiveKeyUp: keyEvent)
            }
        }
    }
}

// MARK: - Monitor Wrapper (for C callbacks)

/// Wrapper to access KeyEventMonitor in C callbacks
final class KeyEventMonitorWrapper: @unchecked Sendable {
    static let shared = KeyEventMonitorWrapper()
    
    weak var monitor: KeyEventMonitor?
    
    private init() {}
}

// MARK: - C Callback Functions

/// CGEvent callback function
private func keyEventCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let info = userInfo else {
        return Unmanaged.passRetained(event)
    }
    
    let wrapper = Unmanaged<KeyEventMonitorWrapper>.fromOpaque(info).takeUnretainedValue()
    
    // Handle event tap disabled notification
    guard type == .keyDown || type == .keyUp || type == .flagsChanged else {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            DispatchQueue.main.async {
                wrapper.monitor?.reenableTap()
            }
        }
        return Unmanaged.passRetained(event)
    }
    
    // Get key code
    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    let modifiers = UInt(event.flags.rawValue)
    
    // Determine event type
    let eventType: KeyEventType
    switch type {
    case .keyDown: eventType = .keyDown
    case .keyUp: eventType = .keyUp
    case .flagsChanged: eventType = .flagsChanged
    default: return Unmanaged.passRetained(event)
    }
    
    let keyEvent = KeyEvent(
        keyCode: keyCode,
        modifiers: modifiers,
        type: eventType,
        timestamp: Date()
    )
    
    // Decide whether to intercept
    // 1. Cmd+Q keyDown needs interception
    // 2. If Cmd+Q is pressed, Q keyUp needs interception
    // 3. flagsChanged is not intercepted (let other apps handle it normally)
    
    let shouldIntercept: Bool
    switch eventType {
    case .keyDown:
        shouldIntercept = keyEvent.isCmdQDown
    case .keyUp:
        // When Q key is released, if in Cmd+Q state, intercept it
        shouldIntercept = keyEvent.isQKey && keyEvent.hasCommandModifier
    case .flagsChanged:
        // Do not intercept modifier changes, but we still handle them
        shouldIntercept = false
    }
    
    // Notify delegate on main thread
    DispatchQueue.main.async {
        wrapper.monitor?.handleKeyEvent(keyEvent)
    }
    
    // Return nil to intercept event, otherwise pass it on
    return shouldIntercept ? nil : Unmanaged.passRetained(event)
}
