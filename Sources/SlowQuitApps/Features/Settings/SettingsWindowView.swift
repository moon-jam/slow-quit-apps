import SwiftUI

/// Settings Window Main View
/// Uses Apple's recommended TabView settings pattern, automatically adapts to Liquid Glass effect
struct SettingsWindowView: View {
    @State private var i18n = I18n.shared
    
    var body: some View {
        // Access currentLanguage to ensure view refreshes when language changes
        let _ = i18n.currentLanguage
        
        settingsContent
            .scenePadding()
    }
    
    // MARK: - Version-adaptive TabView
    
    @ViewBuilder
    private var settingsContent: some View {
        if #available(macOS 15.0, *) {
            // macOS 15+ uses new Tab API
            TabView {
                Tab(t("settings.tabs.general"), systemImage: "gearshape") {
                    GeneralSettingsView()
                        .fixedSize()
                }
                
                Tab(t("settings.tabs.appList"), systemImage: "app.badge.checkmark") {
                    AppListSettingsView()
                        .frame(minWidth: 450, minHeight: 300)
                }
                
                Tab(t("settings.tabs.about"), systemImage: "info.circle") {
                    AboutView()
                        .fixedSize()
                }
            }
        } else {
            // macOS 14 uses legacy tabItem API
            TabView {
                GeneralSettingsView()
                    .fixedSize()
                    .tabItem {
                        Label(t("settings.tabs.general"), systemImage: "gearshape")
                    }
                
                AppListSettingsView()
                    .frame(minWidth: 450, minHeight: 300)
                    .tabItem {
                        Label(t("settings.tabs.appList"), systemImage: "app.badge.checkmark")
                    }
                
                AboutView()
                    .fixedSize()
                    .tabItem {
                        Label(t("settings.tabs.about"), systemImage: "info.circle")
                    }
            }
        }
    }
}

