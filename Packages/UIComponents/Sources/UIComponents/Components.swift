import SwiftUI

public struct StudyCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(StudyColor.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(StudyColor.divider, lineWidth: 1)
            )
            .accessibilityElement(children: .contain)
    }
}

public struct StudyChip: View {
    private let text: String
    private let color: Color

    public init(text: String, color: Color = StudyColor.coolAccent) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(StudyTypography.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
            .accessibilityLabel(text)
    }
}

public struct StudyButton: View {
    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(StudyTypography.headline)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(StudyPrimaryButtonStyle())
        .accessibilityLabel(title)
    }
}

public struct StudyPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(StudyColor.coolAccent)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

public struct EmptyStateView: View {
    private let title: String
    private let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(StudyTypography.title)
                .foregroundColor(StudyColor.primaryText)
            Text(message)
                .font(StudyTypography.body)
                .foregroundColor(StudyColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

public struct SectionHeader: View {
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        HStack {
            Text(title)
                .font(StudyTypography.headline)
                .foregroundColor(StudyColor.primaryText)
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityAddTraits(.isHeader)
    }
}
