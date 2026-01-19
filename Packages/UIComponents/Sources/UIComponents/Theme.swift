import SwiftUI

public enum StudyColor {
    public static var background: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1)
                : UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1)
        })
    }

    public static var surface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1)
                : UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1)
        })
    }

    public static var primaryText: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.92, green: 0.92, blue: 0.94, alpha: 1)
                : UIColor(red: 0.15, green: 0.15, blue: 0.16, alpha: 1)
        })
    }

    public static var secondaryText: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.70, green: 0.72, blue: 0.75, alpha: 1)
                : UIColor(red: 0.35, green: 0.36, blue: 0.39, alpha: 1)
        })
    }

    public static var coolAccent: Color {
        Color(uiColor: UIColor { _ in
            UIColor(red: 0.20, green: 0.55, blue: 0.70, alpha: 1)
        })
    }

    public static var warmAccent: Color {
        Color(uiColor: UIColor { _ in
            UIColor(red: 0.86, green: 0.55, blue: 0.20, alpha: 1)
        })
    }

    public static var divider: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.28, green: 0.28, blue: 0.30, alpha: 1)
                : UIColor(red: 0.85, green: 0.83, blue: 0.80, alpha: 1)
        })
    }
}

public enum StudyTypography {
    public static var title: Font {
        .system(.title2, design: .rounded).weight(.semibold)
    }

    public static var headline: Font {
        .system(.headline, design: .rounded)
    }

    public static var body: Font {
        .system(.body, design: .rounded)
    }

    public static var caption: Font {
        .system(.caption, design: .rounded)
    }
}

public struct StudyTheme: Sendable {
    public var background: Color
    public var surface: Color
    public var primaryText: Color
    public var secondaryText: Color
    public var coolAccent: Color
    public var warmAccent: Color

    public init(\n        background: Color = StudyColor.background,\n        surface: Color = StudyColor.surface,\n        primaryText: Color = StudyColor.primaryText,\n        secondaryText: Color = StudyColor.secondaryText,\n        coolAccent: Color = StudyColor.coolAccent,\n        warmAccent: Color = StudyColor.warmAccent\n    ) {\n        self.background = background\n        self.surface = surface\n        self.primaryText = primaryText\n        self.secondaryText = secondaryText\n        self.coolAccent = coolAccent\n        self.warmAccent = warmAccent\n    }\n}

public struct StudyText: View {
    public enum Style {\n        case title\n        case headline\n        case body\n        case caption\n    }\n\n    private let text: String\n    private let style: Style\n    private let color: Color\n\n    public init(_ text: String, style: Style = .body, color: Color = StudyColor.primaryText) {\n        self.text = text\n        self.style = style\n        self.color = color\n    }\n\n    public var body: some View {\n        Text(text)\n            .font(font(for: style))\n            .foregroundColor(color)\n    }\n\n    private func font(for style: Style) -> Font {\n        switch style {\n        case .title:\n            return StudyTypography.title\n        case .headline:\n            return StudyTypography.headline\n        case .body:\n            return StudyTypography.body\n        case .caption:\n            return StudyTypography.caption\n        }\n    }\n}
