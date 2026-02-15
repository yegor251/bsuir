import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var localizationService: LocalizationService
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text(localizationService.localizedString("tab_search"))
                }
                .tag(0)

            SavedFlightsView()
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text(localizationService.localizedString("tab_saved"))
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(localizationService.localizedString("tab_settings"))
                }
                .tag(2)
        }
    }
}

#Preview {
    RootTabView(selectedTab: .constant(0))
        .environmentObject(LocalizationService.shared)
        .environmentObject(ThemeService.shared)
        .environmentObject(SettingsViewModel())
}
