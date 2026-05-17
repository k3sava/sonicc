import SwiftUI

/// Thumb-zone play + record cluster. Lives above the bottom tab bar on
/// iPhone so a one-handed user can always reach the most-used controls.
/// Two pill buttons stacked vertically. Fades down while a key is being
/// held so it never obstructs your playing fingers.
struct FloatingTransport: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sequencer: Sequencer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size: CGFloat = 48

    var body: some View {
        // Dim while keys are held so the cluster doesn't fight the player's
        // fingers; fully opaque otherwise so it's discoverable.
        let isTouching = !app.heldNotes.isEmpty
        VStack(spacing: 8) {
            recordButton
            playButton
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: size / 2 + 7)
                .fill(app.theme.semantic.surface)
                .shadow(color: .black.opacity(0.10), radius: 12, y: 5)
                .shadow(color: .black.opacity(0.05), radius: 2,  y: 1)
        )
        .opacity(isTouching ? 0.32 : 1)
        .animation(reduceMotion ? .linear(duration: 0.001) : .easeInOut(duration: 0.18),
                   value: isTouching)
    }

    private var playButton: some View {
        Button {
            if sequencer.isPlaying { sequencer.stop() } else { sequencer.play() }
            Haptics.tap(.medium)
        } label: {
            Image(systemName: sequencer.isPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(sequencer.isPlaying ? Color.white : app.theme.semantic.accent)
                .frame(width: size, height: size)
                .background(
                    Circle().fill(sequencer.isPlaying ? app.theme.semantic.accent : app.theme.semantic.accentSoft)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .a11y(sequencer.isPlaying ? "Stop sequencer" : "Play sequencer",
              hint: "Starts or stops the step sequencer.")
    }

    private var recordButton: some View {
        Button {
            sequencer.toggleRecord()
            Haptics.notify(sequencer.isRecording ? .warning : .success)
        } label: {
            ZStack {
                Circle()
                    .stroke(sequencer.isRecording ? app.theme.semantic.destructive : app.theme.semantic.inkSoft.opacity(0.6),
                            lineWidth: 2.5)
                    .frame(width: size - 12, height: size - 12)
                Circle()
                    .fill(sequencer.isRecording ? app.theme.semantic.destructive : app.theme.semantic.inkSoft.opacity(0.6))
                    .frame(width: sequencer.isRecording ? size - 22 : 16,
                           height: sequencer.isRecording ? size - 22 : 16)
                    .animation(reduceMotion ? .linear(duration: 0.001) : .spring(response: 0.28, dampingFraction: 0.7),
                               value: sequencer.isRecording)
            }
            .frame(width: size, height: size)
            .background(Circle().fill(app.theme.semantic.canvas))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .a11y("Record into sequencer",
              value: sequencer.isRecording ? "recording" : "armed",
              hint: "Tap notes on the keyboard while record is on to lay them into the pattern.")
    }
}
