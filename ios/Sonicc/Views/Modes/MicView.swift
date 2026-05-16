import SwiftUI

struct MicView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var mic: MicrophoneRecorder

    var body: some View {
        VStack(spacing: 20) {
            levelMeter
                .frame(height: 16)
            Text(timeString(mic.elapsed))
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .foregroundStyle(app.theme.text)

            HStack(spacing: 12) {
                Button(action: toggleRecord) {
                    Label(
                        mic.isRecording ? "Stop" : "Record",
                        systemImage: mic.isRecording ? "stop.fill" : "record.circle.fill"
                    )
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(mic.isRecording ? .red : app.theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    mic.preview()
                } label: {
                    Label("Preview", systemImage: "play.fill")
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(app.theme.surface)
                        .overlay(Capsule().stroke(app.theme.border))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(mic.lastBuffer == nil)

                Button {
                    mic.sendToSampler(app.sampler)
                    app.mode = .sampler
                } label: {
                    Label("To sampler", systemImage: "scissors")
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(app.theme.surface)
                        .overlay(Capsule().stroke(app.theme.border))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(mic.lastBuffer == nil)

                Button {
                    mic.clear()
                } label: {
                    Label("Clear", systemImage: "trash")
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(app.theme.surface)
                        .overlay(Capsule().stroke(app.theme.border))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(mic.lastBuffer == nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

    private var levelMeter: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(app.theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(app.theme.border))
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [app.theme.accent, .red], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(mic.level))
                    .animation(.easeOut(duration: 0.05), value: mic.level)
            }
        }
    }

    private func toggleRecord() {
        if mic.isRecording { mic.stop() } else { mic.start() }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        let ms = Int(t * 1000) % 1000 / 10
        return String(format: "%02d:%02d.%02d", mins, secs, ms)
    }
}
