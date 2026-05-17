import SwiftUI

struct ControlBar: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sequencer: Sequencer

    var body: some View {
        HStack(spacing: 8) {
            // Mode chips (small label list)
            HStack(spacing: 4) {
                ForEach(AppState.Mode.allCases) { m in
                    ModeChip(mode: m)
                }
            }

            Divider().frame(height: 24)

            // Presets carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(app.presets.presets) { p in
                        PresetPill(preset: p)
                    }
                }
            }

            Divider().frame(height: 24)

            // Transport
            TransportControls(sequencer: sequencer)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
        .background(app.theme.surface)
        .overlay(Divider(), alignment: .bottom)
    }
}

struct ModeChip: View {
    @EnvironmentObject var app: AppState
    let mode: AppState.Mode

    var body: some View {
        let isActive = app.mode == mode
        Button { app.mode = mode } label: {
            HStack(spacing: 5) {
                Image(systemName: mode.sfSymbol)
                    .font(.system(size: 11))
                Text(mode.title.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .fixedSize(horizontal: true, vertical: false)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isActive ? app.theme.accent : app.theme.textMuted)
            .background(isActive ? app.theme.accentSoft : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? app.theme.accent : app.theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct PresetPill: View {
    @EnvironmentObject var app: AppState
    let preset: Preset

    var body: some View {
        let isActive = app.currentPresetID == preset.id
        Button { app.applyPreset(id: preset.id) } label: {
            Text(preset.displayName)
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(isActive ? .white : app.theme.textMuted)
                .background(isActive ? app.theme.accent : app.theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? app.theme.accent : app.theme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct TransportControls: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sequencer: Sequencer
    @State private var tapTimestamps: [Date] = []

    var body: some View {
        HStack(spacing: 6) {
            Button {
                sequencer.isPlaying ? sequencer.stop() : sequencer.play()
            } label: {
                Image(systemName: sequencer.isPlaying ? "stop.fill" : "play.fill")
                    .frame(width: 32, height: 32)
                    .background(sequencer.isPlaying ? app.theme.accent : app.theme.accentSoft)
                    .foregroundStyle(sequencer.isPlaying ? .white : app.theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Button { sequencer.toggleRecord() } label: {
                Image(systemName: "record.circle.fill")
                    .frame(width: 32, height: 32)
                    .foregroundStyle(sequencer.isRecording ? .red : app.theme.textMuted)
            }
            .buttonStyle(.plain)

            HStack(spacing: 2) {
                Button {
                    sequencer.bpm = max(40, sequencer.bpm - 1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10))
                        .frame(width: 24, height: 24)
                }
                Text("\(Int(sequencer.bpm))")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .frame(minWidth: 40)
                Text("BPM")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted)
                Button {
                    sequencer.bpm = min(300, sequencer.bpm + 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 6)
            .background(app.theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(app.theme.border))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                tapTempo()
            } label: {
                Text("TAP")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .foregroundStyle(app.theme.text)
                    .background(app.theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(app.theme.border))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                Text("SWING")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted)
                Slider(value: $sequencer.swing, in: 0...0.5)
                    .frame(width: 80)
                Text("\(Int(sequencer.swing * 100))%")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted)
                    .frame(minWidth: 28, alignment: .trailing)
            }
        }
    }

    /// Tap tempo: average the interval between the last 4 taps to derive a BPM.
    /// Taps older than 2 seconds are discarded so a fresh count starts cleanly.
    private func tapTempo() {
        let now = Date()
        tapTimestamps.append(now)
        tapTimestamps = tapTimestamps.filter { now.timeIntervalSince($0) < 2.0 }
        if tapTimestamps.count >= 2 {
            var diffs: [TimeInterval] = []
            for i in 1..<tapTimestamps.count {
                diffs.append(tapTimestamps[i].timeIntervalSince(tapTimestamps[i - 1]))
            }
            let avg = diffs.reduce(0, +) / Double(diffs.count)
            let bpm = 60.0 / avg
            sequencer.bpm = min(300, max(40, bpm))
        }
    }
}
