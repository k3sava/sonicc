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
                    showSaveDialog = true
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
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

    private func timeString(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        let ms = Int(t * 1000) % 1000 / 10
        return String(format: "%02d:%02d.%02d", mins, secs, ms)
    }
}
