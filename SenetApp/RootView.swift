import SwiftUI
import UIKit

struct RootView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ContentView(viewModel: viewModel)
            .onAppear {
                applyOrientation(for: viewModel.stage)
            }
            .onChange(of: viewModel.stage) { _, newStage in
                applyOrientation(for: newStage)
            }
    }

    private func applyOrientation(for stage: GameViewModel.Stage) {
        let supportedMask: UIInterfaceOrientationMask
        let requestedMask: UIInterfaceOrientationMask
        switch stage {
        case .game:
            supportedMask = .landscape
            requestedMask = .landscapeRight
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
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
