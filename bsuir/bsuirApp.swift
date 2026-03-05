//
//  bsuirApp.swift
//  bsuir
//
//  Created by macbook on 13.02.26.
//

import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAuth
import ImageKitIO
import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct FlightSearchApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let persistenceController = PersistenceController.shared
    @StateObject private var settingsViewModel = SettingsViewModel()
    @ObservedObject private var localizationService = LocalizationService.shared
    @StateObject private var themeService = ThemeService.shared
    @StateObject private var authService = AuthService()

    @State private var showSplash = true
    @State private var selectedTab = 0
    @StateObject private var networkMonitor = NetworkMonitor.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .environmentObject(localizationService)
                        .transition(.opacity)
                } else {
                    if authService.user == nil {
                        AuthView()
                            .environmentObject(authService)
                            .environmentObject(localizationService)
                            .environmentObject(themeService)
                            .environment(\.locale, localizationService.currentLocale)
                            .preferredColorScheme(themeService.currentColorScheme)
                    } else {
                        RootTabView(selectedTab: $selectedTab)
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)
                            .environmentObject(authService)
                            .environmentObject(settingsViewModel)
                            .environmentObject(localizationService)
                            .environmentObject(themeService)
                            .environment(\.locale, localizationService.currentLocale)
                            .preferredColorScheme(themeService.currentColorScheme)
                    }
                }

                if !networkMonitor.isConnected {
                    VStack(spacing: 0) {
                        ConnectionBanner()
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
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

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var user: FirebaseAuth.User?

    private var listener: AuthStateDidChangeListenerHandle?

    init() {
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                self.user = user
            }
        }
    }

    deinit {
        if let listener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var localizationService: LocalizationService

    @State private var isSignUpMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(localizationService.localizedString("auth_title"))
                    .font(.largeTitle.bold())

                VStack(spacing: 12) {
                    TextField(localizationService.localizedString("auth_email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.next)
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(12)

                    SecureField(localizationService.localizedString("auth_password"), text: $password)
                        .textContentType(isSignUpMode ? .newPassword : .password)
                        .submitLabel(.go)
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(12)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Text(localizationService.localizedString(isSignUpMode ? "auth_sign_up" : "auth_sign_in"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSignUpMode.toggle()
                    }
                } label: {
                    Text(localizationService.localizedString(isSignUpMode ? "auth_switch_to_sign_in" : "auth_switch_to_sign_up"))
                        .font(.callout)
                }
                .disabled(isLoading)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .alert(localizationService.localizedString("auth_error_title"), isPresented: $showErrorAlert) {
                Button(localizationService.localizedString("auth_error_ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? localizationService.localizedString("error_generic"))
            }
        }
    }

    @MainActor
    private func submit() async {
        isLoading = true
        defer { isLoading = false }

        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            if isSignUpMode {
                try await authService.signUp(email: emailTrimmed, password: password)
            } else {
                try await authService.signIn(email: emailTrimmed, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
