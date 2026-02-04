import SwiftUI
import UIKit

struct OrientationLockView<Content: View>: UIViewControllerRepresentable {
    var orientationMask: UIInterfaceOrientationMask
    var content: Content

    init(orientationMask: UIInterfaceOrientationMask, @ViewBuilder content: () -> Content) {
        self.orientationMask = orientationMask
        self.content = content()
    }

    func makeUIViewController(context: Context) -> HostingController<Content> {
        let controller = HostingController(rootView: content)
        controller.orientationMask = orientationMask
        return controller
    }

    func updateUIViewController(_ uiViewController: HostingController<Content>, context: Context) {
        uiViewController.orientationMask = orientationMask
        uiViewController.rootView = content
        uiViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
        UIViewController.attemptRotationToDeviceOrientation()
    }

    final class HostingController<Content: View>: UIHostingController<Content> {
        var orientationMask: UIInterfaceOrientationMask = .all

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            orientationMask
        }
    }
}
