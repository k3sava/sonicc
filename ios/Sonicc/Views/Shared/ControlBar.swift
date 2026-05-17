import SwiftUI

/// Top transport + chrome bar. Mode chips, preset carousel, transport
/// (play/record/BPM/tap/swing). Every control hits Apple's 44pt minimum.
/// BPM is tappable to open a numeric editor.
struct ControlBar: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sequencer: Sequencer

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            modeChips
            Divider().frame(height: 28)
            presetScroll
            Divider().frame(height: 28)
            TransportControls(sequencer: sequencer)
        }
        .padding(.horizontal, DS.Space.lg)
        .frame(minHeight: 56)
        .background(app.theme.semantic.surface)
        .overlay(Divider(), alignment: .bottom)
    }

    private var modeChips: some View {
        HStack(spacing: DS.Space.xs) {
            ForEach(AppState.Mode.allCases) { m in
                ModeChip(mode: m)
            }
        }
    }

    private var presetScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.xs) {
                ForEach(app.presets.presets) { p in
                    PresetPill(preset: p)
                }
            }
        }
    }
}

struct ModeChip: View {
    @EnvironmentObject var app: AppState
    let mode: AppState.Mode

    var body: some View {
        let isActive = app.mode == mode
        Button {
            app.mode = mode
            Haptics.select()
        } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: mode.sfSymbol)
                    .imageScale(.small)
                Text(mode.title.uppercased())
                    .font(DS.font(.caption, weight: .semibold, monospaced: true))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, DS.Space.md)
            .frame(height: DS.minTarget)
            .foregroundStyle(isActive ? app.theme.semantic.accent : app.theme.semantic.inkSoft)
            .background(Capsule().fill(isActive ? app.theme.semantic.accentSoft : Color.clear))
            .overlay(Capsule().stroke(isActive ? app.theme.semantic.accent : app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y(mode.title, value: isActive ? "selected" : "", hint: "Switches the performance surface.")
    }
}

struct PresetPill: View {
    @EnvironmentObject var app: AppState
    let preset: Preset

    var body: some View {
        let isActive = app.currentPresetID == preset.id
        Button {
            app.applyPreset(id: preset.id)
            Haptics.select()
            app.previewCurrentTimbre()
        } label: {
            Text(preset.displayName)
                .font(DS.font(.caption, weight: isActive ? .semibold : .regular, monospaced: true))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, DS.Space.md)
                .frame(height: DS.minTarget)
                .foregroundStyle(isActive ? Color.white : app.theme.semantic.inkSoft)
                .background(Capsule().fill(isActive ? app.theme.semantic.accent : app.theme.semantic.surface))
                .overlay(Capsule().stroke(isActive ? app.theme.semantic.accent : app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y("Preset \(preset.displayName)", value: isActive ? "selected" : "",
              hint: "Loads the preset and previews its sound.")
    }
}

struct TransportControls: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sequencer: Sequencer
    @State private var tapTimestamps: [Date] = []
    @State private var showBPMEditor = false

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            playButton
            recordButton
            bpmDisplay
            tapButton
            swingControl
        }
        .alert("Tempo", isPresented: $showBPMEditor) {
            TextField("BPM", value: $sequencer.bpm, format: .number)
                .keyboardType(.decimalPad)
            Button("OK") { Haptics.notify(.success) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Range 40 – 300 BPM")
        }
    }

    private var playButton: some View {
        Button {
            if sequencer.isPlaying { sequencer.stop() } else { sequencer.play() }
            Haptics.tap(.medium)
        } label: {
            Image(systemName: sequencer.isPlaying ? "stop.fill" : "play.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(sequencer.isPlaying ? Color.white : app.theme.semantic.accent)
                .frame(width: DS.minTarget, height: DS.minTarget)
                .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .fill(sequencer.isPlaying ? app.theme.semantic.accent : app.theme.semantic.accentSoft))
        }
        .buttonStyle(.plain)
        .a11y(sequencer.isPlaying ? "Stop" : "Play")
    }

    private var recordButton: some View {
        Button {
            sequencer.toggleRecord()
            Haptics.notify(sequencer.isRecording ? .warning : .success)
        } label: {
            ZStack {
                Circle()
                    .stroke(sequencer.isRecording ? app.theme.semantic.destructive : app.theme.semantic.inkSoft, lineWidth: 2)
                    .frame(width: 26, height: 26)
                Circle()
                    .fill(sequencer.isRecording ? app.theme.semantic.destructive : app.theme.semantic.inkSoft)
                    .frame(width: sequencer.isRecording ? 20 : 16,
                           height: sequencer.isRecording ? 20 : 16)
            }
            .frame(width: DS.minTarget, height: DS.minTarget)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .a11y("Record", value: sequencer.isRecording ? "on" : "off",
              hint: "Captures notes you play into the sequencer.")
    }

    private var bpmDisplay: some View {
        Button {
            showBPMEditor = true
            Haptics.select()
        } label: {
            HStack(spacing: 4) {
                Text("\(Int(sequencer.bpm))")
                    .font(DS.font(.body, weight: .semibold, monospaced: true))
                Text("BPM")
                    .font(DS.font(.micro, weight: .semibold, monospaced: true))
                    .foregroundStyle(app.theme.semantic.inkMuted)
            }
            .padding(.horizontal, DS.Space.md)
            .frame(minHeight: DS.minTarget)
            .background(RoundedRectangle(cornerRadius: DS.Radius.chip).fill(app.theme.semantic.surface))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip).stroke(app.theme.semantic.hairline))
            .foregroundStyle(app.theme.semantic.ink)
        }
        .buttonStyle(.plain)
        .a11y("Tempo", value: "\(Int(sequencer.bpm)) BPM", hint: "Tap to type a value.")
    }

    private var tapButton: some View {
        Button(action: tapTempo) {
            Text("TAP")
                .font(DS.font(.caption, weight: .semibold, monospaced: true))
                .padding(.horizontal, DS.Space.md)
                .frame(minHeight: DS.minTarget)
                .foregroundStyle(app.theme.semantic.ink)
                .background(RoundedRectangle(cornerRadius: DS.Radius.chip).fill(app.theme.semantic.surface))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip).stroke(app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y("Tap tempo", hint: "Tap repeatedly to set BPM from your rhythm.")
    }

    private var swingControl: some View {
        HStack(spacing: 4) {
            Text("SWING")
                .font(DS.font(.micro, weight: .semibold, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
            Slider(value: $sequencer.swing, in: 0...0.5)
                .tint(app.theme.semantic.accent)
                .frame(width: 88)
            Text("\(Int(sequencer.swing * 100))%")
                .font(DS.font(.micro, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
                .frame(minWidth: 32, alignment: .trailing)
        }
        .a11y("Swing", value: "\(Int(sequencer.swing * 100))%",
              hint: "Adds groove by delaying every other step.")
    }

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
            Haptics.tap(.soft)
        } else {
            Haptics.select()
        }
    }
}
