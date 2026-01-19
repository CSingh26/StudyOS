import SwiftUI

public enum StudyColor {
    public static var background: Color {
        Color(red: 0.98, green: 0.97, blue: 0.94)
    }

    public static var surface: Color {
        Color(red: 0.96, green: 0.95, blue: 0.92)
    }

    public static var primaryText: Color {
        Color(red: 0.15, green: 0.15, blue: 0.16)
    }

    public static var secondaryText: Color {
        Color(red: 0.35, green: 0.36, blue: 0.39)
    }

    public static var coolAccent: Color {
        Color(red: 0.20, green: 0.55, blue: 0.70)
    }

    public static var warmAccent: Color {
        Color(red: 0.86, green: 0.55, blue: 0.20)
    }

    public static var divider: Color {
        Color(red: 0.85, green: 0.83, blue: 0.80)
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
