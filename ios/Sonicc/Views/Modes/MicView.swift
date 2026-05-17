import SwiftUI
import AVFoundation

/// Microphone mode — record, preview, save, send to sampler. Big level
/// meter, prominent record button, clear toast feedback after every
/// action so the player always knows what happened.
struct MicView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var mic: MicrophoneRecorder
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var library = RecordingLibrary.shared
    @State private var showSaveDialog: Bool = false
    @State private var saveName: String = ""
    @State private var showLibrary: Bool = false
    @State private var toast: PatternView.ToastMessage?

    var body: some View {
        VStack(spacing: DS.Space.lg) {
            Spacer(minLength: 0)
            levelMeter
                .frame(height: 18)
            timer
            actionButtons
            librarySummary
            if let toast {
                ToastView(message: toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DS.Space.lg)
        .animation(DS.ease(reduceMotion: reduceMotion), value: toast)
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
    }

    // MARK: - Level + timer

    private var levelMeter: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(app.theme.semantic.surface)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(app.theme.semantic.hairline))
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [app.theme.semantic.accent,
                                                  app.theme.semantic.destructive],
                                          startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(mic.level))
                    .animation(reduceMotion ? .linear(duration: 0.001) : .easeOut(duration: 0.05),
                               value: mic.level)
            }
        }
        .a11y("Input level", value: "\(Int(mic.level * 100)) percent")
    }

    private var timer: some View {
        Text(timeString(mic.elapsed))
            .font(.system(.largeTitle, design: .monospaced).weight(.semibold))
            .foregroundStyle(mic.isRecording ? app.theme.semantic.destructive : app.theme.semantic.ink)
            .contentTransition(.numericText())
            .a11y("Elapsed", value: timeString(mic.elapsed))
    }

    // MARK: - Actions

    private var actionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.sm) {
                recordButton
                actionButton("Preview", systemImage: "play.fill", action: mic.preview)
                    .disabled(mic.lastBuffer == nil)
                actionButton("Save", systemImage: "square.and.arrow.down") {
                    showSaveDialog = true
                    Haptics.select()
                }
                .disabled(mic.lastBuffer == nil)
                actionButton("To Sampler", systemImage: "scissors") {
                    mic.sendToSampler(app.sampler)
                    app.mode = .sampler
                    Haptics.notify(.success)
                    show(.success, "Loaded into sampler")
                }
                .disabled(mic.lastBuffer == nil)
                actionButton("Clear", systemImage: "trash", destructive: true) {
                    mic.clear()
                    Haptics.notify(.warning)
                }
                .disabled(mic.lastBuffer == nil)
            }
            .padding(.horizontal, DS.Space.xs)
        }
    }

    private var recordButton: some View {
        Button(action: toggleRecord) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: mic.isRecording ? "stop.fill" : "record.circle.fill")
                    .imageScale(.medium)
                Text(mic.isRecording ? "Stop" : "Record")
                    .font(DS.font(.label, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, DS.Space.lg)
            .frame(minHeight: DS.minTarget + 4)
            .background(Capsule().fill(mic.isRecording ? app.theme.semantic.destructive : app.theme.semantic.accent))
            .foregroundStyle(Color.white)
        }
        .buttonStyle(.plain)
        .a11y(mic.isRecording ? "Stop recording" : "Start recording")
    }

    @ViewBuilder
    private func actionButton(_ text: String, systemImage: String,
                              destructive: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: systemImage).imageScale(.small)
                Text(text)
                    .font(DS.font(.label, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, DS.Space.md)
            .frame(minHeight: DS.minTarget)
            .foregroundStyle(destructive ? app.theme.semantic.destructive : app.theme.semantic.ink)
            .background(Capsule().fill(app.theme.semantic.surface))
            .overlay(Capsule().stroke(destructive ? app.theme.semantic.destructive : app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y(text)
    }

    private var librarySummary: some View {
        Button { showLibrary = true; Haptics.select() } label: {
            Label("\(library.recordings.count) saved · open library",
                  systemImage: "tray.full")
                .font(DS.font(.caption, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
                .frame(minHeight: 32)
        }
        .buttonStyle(.plain)
        .a11y("Saved recordings", value: "\(library.recordings.count)",
              hint: "Opens your recording library.")
    }

    // MARK: - Actions

    private func toggleRecord() {
        if mic.isRecording { mic.stop(); Haptics.notify(.success) }
        else { mic.start(); Haptics.tap(.heavy) }
    }

    private func persistRecording() {
        let name = saveName
        saveName = ""
        do {
            let tmpURL = try mic.writeToDisk()
            if let rec = library.adopt(from: tmpURL, name: name) {
                show(.success, "Saved \"\(rec.name)\"")
                Haptics.notify(.success)
            }
        } catch {
            show(.warning, "Save failed")
            Haptics.notify(.error)
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
            show(.warning, "Playback failed")
        }
    }

    private func show(_ kind: PatternView.ToastMessage.Kind, _ text: String) {
        toast = PatternView.ToastMessage(text: text, kind: kind)
        let token = toast?.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if toast?.id == token { toast = nil }
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        let ms = Int(t * 1000) % 1000 / 10
        return String(format: "%02d:%02d.%02d", mins, secs, ms)
    }
}
