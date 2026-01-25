import CoreHaptics
import UIKit

public enum Haptics {
    private static var isHapticsAvailable: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        if #available(iOS 13.0, *) {
            return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        }
        return true
        #endif
    }

    public static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard !UIAccessibility.isReduceMotionEnabled, isHapticsAvailable else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard !UIAccessibility.isReduceMotionEnabled, isHapticsAvailable else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
