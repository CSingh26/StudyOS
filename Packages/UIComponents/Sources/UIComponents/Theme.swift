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

    public init(
        background: Color = StudyColor.background,
        surface: Color = StudyColor.surface,
        primaryText: Color = StudyColor.primaryText,
        secondaryText: Color = StudyColor.secondaryText,
        coolAccent: Color = StudyColor.coolAccent,
        warmAccent: Color = StudyColor.warmAccent
    ) {
        self.background = background
        self.surface = surface
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.coolAccent = coolAccent
        self.warmAccent = warmAccent
    }
}

public struct StudyText: View {
    public enum Style {
        case title
        case headline
        case body
        case caption
    }

    private let text: String
    private let style: Style
    private let color: Color

    public init(_ text: String, style: Style = .body, color: Color = StudyColor.primaryText) {
        self.text = text
        self.style = style
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(font(for: style))
            .foregroundColor(color)
    }

    private func font(for style: Style) -> Font {
        switch style {
        case .title:
            return StudyTypography.title
        case .headline:
            return StudyTypography.headline
        case .body:
            return StudyTypography.body
        case .caption:
            return StudyTypography.caption
        }
    }
}
