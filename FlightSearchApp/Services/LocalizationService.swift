import Foundation
import Combine

final class LocalizationService: ObservableObject {
    static let shared = LocalizationService()

    @Published private(set) var language: AppLanguage

    private let settingsManager = SettingsManager.shared

    var currentLocale: Locale {
        Locale(identifier: language.rawValue)
    }

    private init() {
        self.language = settingsManager.loadLanguage()
        updateAppleLanguages()
    }

    func setLanguage(_ newLanguage: AppLanguage) {
        guard language != newLanguage else { return }
        language = newLanguage
        settingsManager.saveLanguage(newLanguage)
        updateAppleLanguages()
        objectWillChange.send()
    }

    func localizedString(_ key: String) -> String {
        let lang = language.rawValue
        if let path = Bundle.main.path(forResource: "Localizable_\(lang)", ofType: "strings"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: String],
           let value = dict[key] {
            return value
        }
        if lang != "en",
           let pathEn = Bundle.main.path(forResource: "Localizable_en", ofType: "strings"),
           let dictEn = NSDictionary(contentsOfFile: pathEn) as? [String: String],
           let valueEn = dictEn[key] {
            return valueEn
        }
        return key
    }

    private func updateAppleLanguages() {
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}
