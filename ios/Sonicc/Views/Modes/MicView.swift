import SwiftUI
import AVFoundation

struct MicView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var mic: MicrophoneRecorder
    @StateObject private var library = RecordingLibrary.shared
    @State private var showSaveDialog: Bool = false
    @State private var saveName: String = ""
    @State private var showLibrary: Bool = false
    @State private var toast: String?

    var body: some View {
        VStack(spacing: 20) {
            levelMeter
                .frame(height: 16)
            Text(timeString(mic.elapsed))
                .font(.system(size: 32, weight: .semibold, design: .monospaced))
                .foregroundStyle(app.theme.text)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button(action: toggleRecord) {
                        actionLabel(
                            mic.isRecording ? "Stop" : "Record",
                            symbol: mic.isRecording ? "stop.fill" : "record.circle.fill",
                            background: mic.isRecording ? Color.red : app.theme.accent,
                            foreground: .white
                        )
                    }
                    .buttonStyle(.plain)

                    actionButton("Preview", symbol: "play.fill", action: mic.preview)
                        .disabled(mic.lastBuffer == nil)

                    actionButton("Save", symbol: "square.and.arrow.down") {
                        showSaveDialog = true
                    }
                    .disabled(mic.lastBuffer == nil)

                    actionButton("To sampler", symbol: "scissors") {
                        mic.sendToSampler(app.sampler)
                        app.mode = .sampler
                    }
                    .disabled(mic.lastBuffer == nil)

                    actionButton("Clear", symbol: "trash") {
                        mic.clear()
                    }
                    .disabled(mic.lastBuffer == nil)
                }
                .padding(.horizontal, 4)
            }

            HStack {
                Button { showLibrary = true } label: {
                    Label("\(library.recordings.count) saved", systemImage: "tray.full")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(app.theme.textMuted)
                }
                .buttonStyle(.plain)
                if let toast {
                    Text(toast)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(app.theme.accent)
                        .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .alert("Save recording", isPresented: $showSaveDialog) {
            TextField("Name", text: $saveName)
            Button("Save", action: persistRecording)
            Button("Cancel", role: .cancel) { saveName = "" }
        } message: {
            Text(timeString(mic.elapsed) + " captured")
        }
        .sheet(isPresented: $showLibrary) {
            RecordingLibrarySheet(library: library, onPlay: playRecording)
        }
        .animation(.easeInOut, value: toast)
    }

    private func persistRecording() {
        let name = saveName
        saveName = ""
        do {
            let tmpURL = try mic.writeToDisk()
            if let rec = library.adopt(from: tmpURL, name: name) {
                toast = "Saved \"\(rec.name)\""
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if toast?.contains(rec.name) == true { toast = nil }
                }
            }
        } catch {
            toast = "Save failed"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { toast = nil }
        }
    }

    private func playRecording(_ rec: SavedRecording) {
        guard let file = try? AVAudioFile(forReading: rec.url) else { return }
        let format = file.processingFormat
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                             frameCapacity: AVAudioFrameCount(file.length))
        else { return }
        do {
            try file.read(into: buffer)
            app.audio.playSample(buffer)
        } catch {
            toast = "Playback failed"
        }
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

    @ViewBuilder
    private func actionButton(_ text: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionLabel(text, symbol: symbol, background: app.theme.surface, foreground: app.theme.text)
        }
        .buttonStyle(.plain)
    }

    private func actionLabel(_ text: String, symbol: String, background: Color, foreground: Color) -> some View {
        Label(text, systemImage: symbol)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(background)
            .foregroundStyle(foreground)
            .overlay(Capsule().stroke(background == app.theme.surface ? app.theme.border : .clear))
            .clipShape(Capsule())
    }

    private func timeString(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        let ms = Int(t * 1000) % 1000 / 10
        return String(format: "%02d:%02d.%02d", mins, secs, ms)
    }
}
