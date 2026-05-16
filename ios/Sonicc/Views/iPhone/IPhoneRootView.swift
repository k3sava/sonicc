import SwiftUI

/// iPhone shell. Bottom mode tab, top header + transport. The inspector
/// is a presented sheet because the performance surface needs all the
/// vertical space we can give it on a phone.
struct IPhoneRootView: View {
    @EnvironmentObject var app: AppState
    @State private var showInspector = false
    @State private var showPresets = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar()
            // Minimal transport row above the playable area.
            HStack(spacing: 8) {
                Button { app.sequencer.isPlaying ? app.sequencer.stop() : app.sequencer.play() } label: {
                    Image(systemName: app.sequencer.isPlaying ? "stop.fill" : "play.fill")
                        .frame(width: 36, height: 32)
                        .background(app.sequencer.isPlaying ? app.theme.accent : app.theme.accentSoft)
                        .foregroundStyle(app.sequencer.isPlaying ? .white : app.theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button { app.sequencer.toggleRecord() } label: {
                    Image(systemName: "record.circle.fill")
                        .frame(width: 36, height: 32)
                        .foregroundStyle(app.sequencer.isRecording ? .red : app.theme.textMuted)
                }
                .buttonStyle(.plain)

                Text("\(Int(app.sequencer.bpm)) BPM")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))

                Spacer()

                Button { showPresets.toggle() } label: {
                    Label(app.presets.preset(id: app.currentPresetID)?.displayName ?? "preset", systemImage: "music.note.list")
                        .font(.system(size: 11, design: .monospaced))
                }
                .buttonStyle(.bordered)

                Button { showInspector.toggle() } label: {
                    Image(systemName: "slider.horizontal.3")
                        .frame(width: 36, height: 32)
                        .foregroundStyle(app.theme.text)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(app.theme.surface)
            .overlay(Divider(), alignment: .bottom)

            currentMode
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(app.theme.bg)

            // Mode tab strip
            HStack {
                ForEach(AppState.Mode.allCases) { m in
                    Button { app.mode = m } label: {
                        VStack(spacing: 2) {
                            Image(systemName: m.sfSymbol)
                                .font(.system(size: 16))
                            Text(m.title)
                                .font(.system(size: 9, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(app.mode == m ? app.theme.accent : app.theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(app.theme.surface)
            .overlay(Divider(), alignment: .top)
        }
        .sheet(isPresented: $showInspector) {
            InspectorPanel()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPresets) {
            PresetSheet()
                .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private var currentMode: some View {
        switch app.mode {
        case .keys: KeyboardView()
        case .drums: DrumsView()
        case .pattern: PatternView(sequencer: app.sequencer)
        case .sampler: SamplerView(sampler: app.sampler)
        case .mic: MicView(mic: app.mic)
        }
    }
}

private struct PresetSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(app.presets.presets) { p in
                    Button {
                        app.applyPreset(id: p.id)
                        dismiss()
                    } label: {
                        HStack {
                            Text(p.displayName)
                                .font(.system(size: 13, design: .monospaced))
                            Spacer()
                            if app.currentPresetID == p.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(app.theme.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Presets")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
