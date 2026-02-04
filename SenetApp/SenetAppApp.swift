import SwiftUI
import UIKit

@main
struct SenetAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.shared.mask
    }
}

final class OrientationLock {
    static let shared = OrientationLock()
    var mask: UIInterfaceOrientationMask = .portrait

    private init() {}
}
