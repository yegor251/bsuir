import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var localizationService: LocalizationService
    @EnvironmentObject private var themeService: ThemeService

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(localizationService.localizedString("settings_language"))) {
                    Picker(localizationService.localizedString("settings_language_picker"), selection: $settingsViewModel.selectedLanguage) {
                        Text("English").tag(AppLanguage.en)
                        Text("Русский").tag(AppLanguage.ru)
                    }
                    .onChange(of: settingsViewModel.selectedLanguage) { newValue in
                        settingsViewModel.updateLanguage(newValue)
                    }
                    .onAppear {
                        settingsViewModel.syncLanguageWithService()
                    }
                }

                Section(header: Text(localizationService.localizedString("settings_theme"))) {
                    Picker(localizationService.localizedString("settings_theme_picker"), selection: $settingsViewModel.selectedTheme) {
                        Text(localizationService.localizedString("theme_system")).tag(AppTheme.system)
                        Text(localizationService.localizedString("theme_light")).tag(AppTheme.light)
                        Text(localizationService.localizedString("theme_dark")).tag(AppTheme.dark)
                    }
                    .onChange(of: settingsViewModel.selectedTheme) { newValue in
                        settingsViewModel.updateTheme(newValue)
                    }
                }

                Section(header: Text(localizationService.localizedString("settings_about"))) {
                    HStack {
                        Text(localizationService.localizedString("settings_version"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(localizationService.localizedString("settings_title"))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(LocalizationService.shared)
        .environmentObject(ThemeService.shared)
}
