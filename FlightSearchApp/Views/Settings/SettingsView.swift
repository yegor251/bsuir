import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var localizationService: LocalizationService
    @EnvironmentObject private var themeService: ThemeService
    @ObservedObject private var notificationService = NotificationService.shared

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(localizationService.localizedString("settings_notifications_section"))) {
                    Toggle(localizationService.localizedString("settings_notifications_flight_reminders"), isOn: $notificationService.isEnabled)
                        .onChange(of: notificationService.isEnabled) { _, enabled in
                            if enabled {
                                if notificationService.isAuthorized {
                                    notificationService.loadFlightsAndStart()
                                } else {
                                    notificationService.isEnabled = false
                                }
                            } else {
                                notificationService.stopAllNotifications()
                            }
                        }
                    Text(localizationService.localizedString("settings_notifications_flight_reminders_description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text(localizationService.localizedString("settings_language"))) {
                    Picker(localizationService.localizedString("settings_language_picker"), selection: $settingsViewModel.selectedLanguage) {
                        Text("English").tag(AppLanguage.en)
                        Text("Русский").tag(AppLanguage.ru)
                    }
                    .onChange(of: settingsViewModel.selectedLanguage) { oldValue, newValue in
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
                    .onChange(of: settingsViewModel.selectedTheme) { oldValue, newValue in
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
            .onAppear {
                if notificationService.isEnabled {
                    let flights = (try? DatabaseService.shared.fetchSavedFlights()) ?? []
                    if !flights.isEmpty {
                        notificationService.startRepeatingNotification(from: flights)
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(LocalizationService.shared)
        .environmentObject(ThemeService.shared)
}
