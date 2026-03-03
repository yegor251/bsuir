import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var selectedLanguage: AppLanguage
    @Published var selectedTheme: AppTheme

    private let settingsManager = SettingsManager.shared

    init() {
        self.selectedLanguage = LocalizationService.shared.language
        self.selectedTheme = settingsManager.loadTheme()
    }

    func updateLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        settingsManager.saveLanguage(language)
        LocalizationService.shared.setLanguage(language)
    }

    func updateTheme(_ theme: AppTheme) {
        guard ThemeService.shared.theme != theme else { return }
        selectedTheme = theme
        settingsManager.saveTheme(theme)
        ThemeService.shared.setTheme(theme)
    }

    func syncLanguageWithService() {
        let current = LocalizationService.shared.language
        if selectedLanguage != current {
            selectedLanguage = current
        }
    }
}
