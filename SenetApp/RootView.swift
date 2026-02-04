import SwiftUI
import UIKit

struct RootView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ContentView(viewModel: viewModel)
            .onAppear {
                applyOrientation(for: viewModel.stage)
            }
            .onChange(of: viewModel.stage) { newStage in
                applyOrientation(for: newStage)
            }
    }

    private func applyOrientation(for stage: GameViewModel.Stage) {
        let newMask: UIInterfaceOrientationMask
        switch stage {
        case .game:
            newMask = .landscape
        case .setup, .tutorial, .rules:
            newMask = .portrait
        }
        OrientationLock.shared.mask = newMask
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let root = window.rootViewController else { return }
        root.setNeedsUpdateOfSupportedInterfaceOrientations()
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
