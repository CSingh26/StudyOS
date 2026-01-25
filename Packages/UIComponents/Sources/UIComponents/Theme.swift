import SwiftUI
import UIKit

public enum ThemeMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public static let storageKey = "theme_mode"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .system:
            return "System default"
        case .light:
            return "Light · Chocolate truffle"
        case .dark:
            return "Dark · Chili spice"
        }
    }

    public var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    public static func resolve(_ rawValue: String) -> ThemeMode {
        ThemeMode(rawValue: rawValue) ?? .system
    }

    public static func load(from defaults: UserDefaults) -> ThemeMode {
        let raw = defaults.string(forKey: storageKey) ?? ThemeMode.system.rawValue
        return resolve(raw)
    }

    public static func store(_ mode: ThemeMode, in defaults: UserDefaults) {
        defaults.set(mode.rawValue, forKey: storageKey)
    }

    public static func store(rawValue: String, in defaults: UserDefaults) {
        defaults.set(rawValue, forKey: storageKey)
    }
}

public enum StudyColor {
    public static var background: Color { themedColor(\.background) }
    public static var surface: Color { themedColor(\.surface) }
    public static var surface2: Color { themedColor(\.surface2) }
    public static var primaryText: Color { themedColor(\.textPrimary) }
    public static var secondaryText: Color { themedColor(\.textSecondary) }
    public static var divider: Color { themedColor(\.separator) }
    public static var primary: Color { themedColor(\.primary) }
    public static var accent: Color { themedColor(\.accent) }
    public static var danger: Color { themedColor(\.danger) }
    public static var success: Color { themedColor(\.success) }
    public static var warning: Color { themedColor(\.warning) }
    public static var highlight: Color { themedColor(\.highlight) }

    public static var coolAccent: Color { accent }
    public static var warmAccent: Color { warning }

    private static func themedColor(_ keyPath: KeyPath<StudyTheme, Color>) -> Color {
        Color(uiColor: UIColor { traits in
            let mode = ThemeMode.load(from: .standard)
            let scheme: ColorScheme = traits.userInterfaceStyle == .dark ? .dark : .light
            let theme = StudyTheme.resolved(for: mode, systemScheme: scheme)
            return UIColor(theme[keyPath: keyPath])
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
    public var surface2: Color
    public var textPrimary: Color
    public var textSecondary: Color
    public var separator: Color
    public var primary: Color
    public var accent: Color
    public var danger: Color
    public var success: Color
    public var warning: Color
    public var highlight: Color

    public init(
        background: Color,
        surface: Color,
        surface2: Color,
        textPrimary: Color,
        textSecondary: Color,
        separator: Color,
        primary: Color,
        accent: Color,
        danger: Color,
        success: Color,
        warning: Color,
        highlight: Color
    ) {
        self.background = background
        self.surface = surface
        self.surface2 = surface2
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.separator = separator
        self.primary = primary
        self.accent = accent
        self.danger = danger
        self.success = success
        self.warning = warning
        self.highlight = highlight
    }

    public var primaryText: Color { textPrimary }
    public var secondaryText: Color { textSecondary }
    public var coolAccent: Color { accent }
    public var warmAccent: Color { warning }
    public var divider: Color { separator }

    public static let chocolateTruffle = StudyTheme(
        background: .studyHex(0xFDFBD4),
        surface: .studyHex(0xF7F2C6),
        surface2: .studyHex(0xF1E8BC),
        textPrimary: .studyHex(0x38240D),
        textSecondary: .studyHex(0x6A4C2E),
        separator: .studyHex(0x38240D, alpha: 0.18),
        primary: .studyHex(0x713600),
        accent: .studyHex(0xC05800),
        danger: .studyHex(0x8C2B00),
        success: .studyHex(0x3F6B2A),
        warning: .studyHex(0xC05800),
        highlight: .studyHex(0xF3C184)
    )

    public static let chiliSpice = StudyTheme(
        background: .studyHex(0x38000A),
        surface: .studyHex(0x4A0A14),
        surface2: .studyHex(0x5B1320),
        textPrimary: .studyHex(0xFFE5DE),
        textSecondary: .studyHex(0xF4BFB2),
        separator: .studyHex(0xFFA896, alpha: 0.2),
        primary: .studyHex(0xCD1C18),
        accent: .studyHex(0x9B1313),
        danger: .studyHex(0xCD1C18),
        success: .studyHex(0x6CCFA1),
        warning: .studyHex(0x9B1313),
        highlight: .studyHex(0xFFA896)
    )

    public static func resolved(for mode: ThemeMode, systemScheme: ColorScheme) -> StudyTheme {
        switch mode {
        case .system:
            return systemScheme == .dark ? .chiliSpice : .chocolateTruffle
        case .light:
            return .chocolateTruffle
        case .dark:
            return .chiliSpice
        }
    }
}

private struct StudyThemeKey: EnvironmentKey {
    static let defaultValue: StudyTheme = .chocolateTruffle
}

public extension EnvironmentValues {
    var studyTheme: StudyTheme {
        get { self[StudyThemeKey.self] }
        set { self[StudyThemeKey.self] = newValue }
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
    @Environment(\.studyTheme) private var theme
    private let color: Color?

    public init(_ text: String, style: Style = .body, color: Color? = nil) {
        self.text = text
        self.style = style
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(font(for: style))
            .foregroundColor(color ?? theme.textPrimary)
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

private extension Color {
    static func studyHex(_ hex: UInt32, alpha: Double = 1.0) -> Color {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
