import Storage
import SwiftUI
import UIComponents

struct FocusSessionSheet: View {
    enum Mode: String, CaseIterable {
        case pomodoro = "Pomodoro"
        case custom = "Custom"
    }

    let assignment: Assignment
    let onComplete: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .pomodoro
    @State private var customMinutes: Int = 45
    @State private var remainingSeconds: Int = 25 * 60
    @State private var isRunning = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            StudyText("Focus Session", style: .headline)
            StudyText(assignment.title, style: .body, color: StudyColor.secondaryText)

            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _ in
                resetTimer()
            }

            if mode == .custom {
                Stepper("Minutes: \(customMinutes)", value: $customMinutes, in: 10...120, step: 5)
                    .onChange(of: customMinutes) { _ in
                        resetTimer()
                    }
            }

            Text(timeString)
                .font(.system(size: 48, weight: .semibold, design: .rounded))

            HStack(spacing: 12) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning.toggle()
                    Haptics.impact(style: .medium)
                }
                .buttonStyle(.borderedProminent)

                Button("Finish") {
                    finish()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                finish()
            }
        }
    }

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func resetTimer() {
        let minutes = mode == .pomodoro ? 25 : customMinutes
        remainingSeconds = minutes * 60
        isRunning = false
    }

    private func finish() {
        let minutes = mode == .pomodoro ? 25 : customMinutes
        onComplete(minutes)
        Haptics.notification(.success)
        dismiss()
    }
}
