import SwiftUI
import UniformTypeIdentifiers

/// General Settings View
struct GeneralSettingsView: View {
    @Bindable var appState = AppState.shared
    
    /// Used to respond to language changes and trigger UI refresh
    @State private var i18n = I18n.shared
    
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var importError: String?
    
    /// Whether running in a valid app bundle environment
    private var isValidAppBundle: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundleURL.pathExtension == "app"
    }
    
    var body: some View {
        // Access currentLanguage to ensure view refreshes when language changes
        let _ = i18n.currentLanguage
        
        Form {
            // Accessibility Status (Pinned)
            Section {
                AccessibilityStatusRow()
            }
            
            // Language Settings
            Section {
                Picker(t("settings.language.title"), selection: $appState.language) {
                    ForEach(Language.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            }
            
            // Feature Toggles
            Section {
                Toggle(t("settings.general.enableLongPress"), isOn: $appState.isEnabled)
                
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(t("settings.general.launchAtLogin"), isOn: $appState.launchAtLogin)
                        .disabled(!isValidAppBundle)
                    
                    if !isValidAppBundle {
                        Text(t("settings.general.launchAtLoginDisabled"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Toggle(t("settings.general.showProgressAnimation"), isOn: $appState.showProgressAnimation)
            }
            
            // Hold Duration
            Section {
                LabeledContent(t("settings.general.holdDuration")) {
                    Text(String(format: "%.1f \(t("settings.general.seconds"))", appState.holdDuration))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                
                Slider(
                    value: $appState.holdDuration,
                    in: Constants.Progress.minHoldDuration...Constants.Progress.maxHoldDuration,
                    step: 0.1
                )
            }
            
            // Configuration Management
            Section(t("settings.general.configManagement")) {
                HStack {
                    Button(t("settings.general.export")) { showingExporter = true }
                    Divider().frame(height: 16)
                    Button(t("settings.general.import")) { showingImporter = true }
                }
                
                Button(t("settings.general.resetDefaults"), role: .destructive) {
                    appState.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .fileExporter(
            isPresented: $showingExporter,
            document: ConfigDocument(),
            contentType: .json,
            defaultFilename: "slow-quit-apps-config"
        ) { result in
            if case .failure(let error) = result {
                print("Export failed: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    _ = url.startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                    try appState.importConfig(from: url)
                } catch {
                    importError = error.localizedDescription
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .alert(t("settings.general.importFailed"), isPresented: .constant(importError != nil)) {
            Button(t("settings.general.ok")) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }
}

// MARK: - Config Document (used for export)

struct ConfigDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    init() {}
    
    init(configuration: ReadConfiguration) throws {
        // No need to read from file
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let config = ConfigManager.shared.load()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Accessibility Permission Status

struct AccessibilityStatusRow: View {
    @State private var isEnabled = AccessibilityManager.shared.isAccessibilityEnabled
    @State private var i18n = I18n.shared
    
    var body: some View {
        let _ = i18n.currentLanguage
        
        LabeledContent {
            if isEnabled {
                Text(t("accessibility.granted"))
                    .foregroundStyle(.green)
            } else {
                HStack(spacing: 8) {
                    Button(t("accessibility.openSettings")) {
                        AccessibilityManager.shared.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button(t("accessibility.restartApp")) {
                        restartApplication()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        } label: {
            Label(
                t("settings.general.accessibilityStatus"),
                systemImage: isEnabled ? "checkmark.shield.fill" : "exclamationmark.shield"
            )
        }
        .foregroundStyle(isEnabled ? Color.primary : Color.orange)
        .onAppear {
            isEnabled = AccessibilityManager.shared.isAccessibilityEnabled
        }
    }
    
    /// Restart application
    private func restartApplication() {
        guard let bundleURL = Bundle.main.bundleURL as URL? else { return }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", bundleURL.path]
        
        try? task.run()
        
        // Delay quitting current instance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
}
