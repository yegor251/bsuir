//
//  bsuirApp.swift
//  bsuir
//
//  Created by macbook on 13.02.26.
//

import SwiftUI
import CoreData

@main
struct FlightSearchApp: App {
    private let persistenceController = PersistenceController.shared
    @StateObject private var settingsViewModel = SettingsViewModel()
    @ObservedObject private var localizationService = LocalizationService.shared
    @StateObject private var themeService = ThemeService.shared

    @State private var showSplash = true
    @State private var selectedTab = 0

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .environmentObject(localizationService)
                        .transition(.opacity)
                } else {
                    RootTabView(selectedTab: $selectedTab)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(settingsViewModel)
                        .environmentObject(localizationService)
                        .environmentObject(themeService)
                        .environment(\.locale, localizationService.currentLocale)
                        .preferredColorScheme(themeService.currentColorScheme)
                }
            }
            .onAppear {
                applySavedLanguageIfNeeded()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }

    private func applySavedLanguageIfNeeded() {
        let saved = SettingsManager.shared.loadLanguage()
        if LocalizationService.shared.language != saved {
            LocalizationService.shared.setLanguage(saved)
        }
    }
}
