import Foundation
import CoreMotion
import Combine

final class HeadsUpMotionManager: ObservableObject {
    @Published private(set) var isAvailable = true

    private let manager = CMMotionManager()
    private var detector = HeadsUpTiltDetector()
    private var callback: ((HeadsUpTiltAction) -> Void)?

    func start(onAction: @escaping (HeadsUpTiltAction) -> Void) {
        stop()
        callback = onAction
        isAvailable = manager.isDeviceMotionAvailable
        guard manager.isDeviceMotionAvailable else { return }

        detector.reset()
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            if let action = self.detector.consume(z: motion.gravity.z) {
                self.callback?(action)
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        detector.reset()
        callback = nil
    }
}
