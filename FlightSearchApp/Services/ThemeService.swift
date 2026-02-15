import SwiftUI
import Combine

final class ThemeService: ObservableObject {
    static let shared = ThemeService()

    @Published private(set) var theme: AppTheme

    private let settingsManager = SettingsManager.shared

    var currentColorScheme: ColorScheme? {
        switch theme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private init() {
        self.theme = settingsManager.loadTheme()
    }

    func setTheme(_ newTheme: AppTheme) {
        guard theme != newTheme else { return }
        theme = newTheme
        settingsManager.saveTheme(newTheme)
        objectWillChange.send()
    }
}

