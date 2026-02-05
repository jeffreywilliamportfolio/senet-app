import SwiftUI
import UIKit

struct RootView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            ContentView(viewModel: viewModel)
                .onAppear {
                    if !isShowingSplash {
                        applyOrientation(for: viewModel.stage)
                    }
                }
                .onChange(of: viewModel.stage) { _, newStage in
                    if !isShowingSplash {
                        applyOrientation(for: newStage)
                    }
                }

            if isShowingSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .onAppear {
                        applyOrientation(for: .setup)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            withAnimation(.easeOut(duration: 0.25)) {
                                isShowingSplash = false
                            }
                            applyOrientation(for: viewModel.stage)
                        }
                    }
            }
        }
    }

    private func applyOrientation(for stage: GameViewModel.Stage) {
        let supportedMask: UIInterfaceOrientationMask
        let requestedMask: UIInterfaceOrientationMask
        switch stage {
        case .game:
            // Gameplay is landscape-only. Allow both landscape orientations so the UI
            // stays "right-side up" regardless of how the user turns their phone.
            supportedMask = .landscape
            requestedMask = .landscape
        case .setup, .tutorial, .rules:
            supportedMask = .portrait
            requestedMask = .portrait
        }
        OrientationLock.shared.mask = supportedMask

        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

        guard let windowScene else { return }

        if #available(iOS 16.0, *) {
            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: requestedMask)
            windowScene.requestGeometryUpdate(preferences) { _ in }
        }

        guard let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let root = window.rootViewController else { return }
        root.setNeedsUpdateOfSupportedInterfaceOrientations()
        if #available(iOS 16.0, *) {
            // `setNeedsUpdateOfSupportedInterfaceOrientations()` is enough on iOS 16+.
        } else {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
