import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject private var localizationService: LocalizationService
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "airplane.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .shadow(radius: 10)

                Text(localizationService.localizedString("app_name"))
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text(localizationService.localizedString("splash_tagline"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
        .environmentObject(LocalizationService.shared)
}
