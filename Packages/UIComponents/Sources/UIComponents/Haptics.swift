import UIKit

public enum Haptics {
    public static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
