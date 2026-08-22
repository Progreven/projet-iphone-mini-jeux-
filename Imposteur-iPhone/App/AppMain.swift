import SwiftUI
import UIKit

final class JeuxSoireeAppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .allButUpsideDown

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        Self.orientationLock
    }
}

@MainActor
enum AppOrientationController {
    static func lockToCurrentOrientation() {
        guard let scene = activeWindowScene else {
            JeuxSoireeAppDelegate.orientationLock = .portrait
            return
        }

        let mask = mask(for: scene.interfaceOrientation)
        JeuxSoireeAppDelegate.orientationLock = mask
        refresh(scene, mask: mask)
    }

    static func unlock() {
        let mask: UIInterfaceOrientationMask = .allButUpsideDown
        JeuxSoireeAppDelegate.orientationLock = mask
        guard let scene = activeWindowScene else { return }
        refresh(scene, mask: mask)
    }

    private static var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    }

    private static func mask(for orientation: UIInterfaceOrientation) -> UIInterfaceOrientationMask {
        switch orientation {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        case .unknown: return .portrait
        @unknown default: return .portrait
        }
    }

    private static func refresh(_ scene: UIWindowScene, mask: UIInterfaceOrientationMask) {
        scene.windows.first(where: { $0.isKeyWindow })?
            .rootViewController?
            .setNeedsUpdateOfSupportedInterfaceOrientations()

        if #available(iOS 16.0, *) {
            let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
            scene.requestGeometryUpdate(preferences) { _ in }
        }
    }
}

@main
struct JeuxSoireeApp: App {
    @UIApplicationDelegateAdaptor(JeuxSoireeAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootHubView()
        }
    }
}
