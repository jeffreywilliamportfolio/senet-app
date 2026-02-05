import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Keep the splash visually consistent with the app's parchment theme
            // even if the image doesn't cover the full display on some devices.
            SenetTheme.background
                .ignoresSafeArea()

            Image("LaunchScreenImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .accessibilityHidden(true)
    }
}
