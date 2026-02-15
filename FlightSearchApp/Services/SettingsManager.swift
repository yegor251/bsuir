import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en
    case ru

    var id: String { rawValue }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
}

final class SettingsManager {
    static let shared = SettingsManager()

    private enum Keys {
        static let language = "FlightSearchApp.language"
        static let theme = "FlightSearchApp.theme"
    }

    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveLanguage(_ language: AppLanguage) {
        defaults.set(language.rawValue, forKey: Keys.language)
        defaults.synchronize()
    }

    func loadLanguage() -> AppLanguage {
        if let raw = defaults.string(forKey: Keys.language),
           let value = AppLanguage(rawValue: raw) {
            return value
        }
        return .en
    }

    func saveTheme(_ theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: Keys.theme)
    }

    func loadTheme() -> AppTheme {
        if let raw = defaults.string(forKey: Keys.theme),
           let value = AppTheme(rawValue: raw) {
            return value
        }
        return .system
    }
}

