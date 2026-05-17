import SwiftUI

/// iPhone shell. Header bar on top, compact transport row, the active
/// performance surface in the middle, and a 5-tab mode strip at the
/// bottom. The inspector lives in a presented sheet — phone real estate
/// goes to the instrument, not the sound design panel.
struct IPhoneRootView: View {
    @EnvironmentObject var app: AppState
    @State private var showInspector = false
    @State private var showPresets = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(onSettings: { showSettings = true })
            transport
            currentMode
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(app.theme.semantic.canvas)
            modeTabs
        }
        .sheet(isPresented: Binding(
            get: { !app.hasOnboarded },
            set: { _ in }
        )) {
            WelcomeSheet()
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showInspector) {
            NavigationStack {
                InspectorPanel()
                    .navigationTitle("Sound")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showInspector = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPresets) {
            PresetSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Transport

    private var transport: some View {
        HStack(spacing: DS.Space.sm) {
            playButton
            recordButton
            bpmDisplay
            Spacer(minLength: 0)
            Button {
                showPresets = true
                Haptics.select()
            } label: {
                Label(app.presets.preset(id: app.currentPresetID)?.displayName ?? "preset",
                      systemImage: "music.note.list")
                    .font(DS.font(.caption, weight: .medium, monospaced: true))
                    .padding(.horizontal, DS.Space.md)
                    .frame(minHeight: DS.minTarget)
                    .foregroundStyle(app.theme.semantic.ink)
                    .background(Capsule().fill(app.theme.semantic.surface))
                    .overlay(Capsule().stroke(app.theme.semantic.hairline))
            }
            .buttonStyle(.plain)
            .a11y("Preset \(app.presets.preset(id: app.currentPresetID)?.displayName ?? "")",
                  hint: "Opens the preset picker.")

            Button {
                showInspector = true
                Haptics.select()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .imageScale(.large)
                    .frame(width: DS.minTarget, height: DS.minTarget)
                    .foregroundStyle(app.theme.semantic.ink)
                    .contentShape(Rectangle())
            }
            .a11y("Sound design", hint: "Opens waveform, envelope, filter and effects.")
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.xs)
        .frame(minHeight: 56)
        .background(app.theme.semantic.surface)
        .overlay(Divider(), alignment: .bottom)
    }

    private var playButton: some View {
        Button {
            if app.sequencer.isPlaying { app.sequencer.stop() } else { app.sequencer.play() }
            Haptics.tap(.medium)
        } label: {
            Image(systemName: app.sequencer.isPlaying ? "stop.fill" : "play.fill")
                .font(.body.weight(.semibold))
                .frame(width: DS.minTarget, height: DS.minTarget)
                .foregroundStyle(app.sequencer.isPlaying ? Color.white : app.theme.semantic.accent)
                .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .fill(app.sequencer.isPlaying ? app.theme.semantic.accent : app.theme.semantic.accentSoft))
        }
        .buttonStyle(.plain)
        .a11y(app.sequencer.isPlaying ? "Stop" : "Play")
    }

    private var recordButton: some View {
        Button {
            app.sequencer.toggleRecord()
            Haptics.notify(app.sequencer.isRecording ? .warning : .success)
        } label: {
            ZStack {
                Circle()
                    .stroke(app.sequencer.isRecording ? app.theme.semantic.destructive : app.theme.semantic.inkSoft,
                            lineWidth: 2)
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(app.sequencer.isRecording ? app.theme.semantic.destructive : app.theme.semantic.inkSoft)
                    .frame(width: app.sequencer.isRecording ? 18 : 14,
                           height: app.sequencer.isRecording ? 18 : 14)
            }
            .frame(width: DS.minTarget, height: DS.minTarget)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .a11y("Record", value: app.sequencer.isRecording ? "on" : "off")
    }

    private var bpmDisplay: some View {
        Text("\(Int(app.sequencer.bpm)) BPM")
            .font(DS.font(.caption, weight: .semibold, monospaced: true))
            .foregroundStyle(app.theme.semantic.ink)
            .padding(.horizontal, DS.Space.sm)
    }

    // MARK: - Mode tabs

    private var modeTabs: some View {
        HStack(spacing: 0) {
            ForEach(AppState.Mode.allCases) { m in
                modeTab(m)
            }
        }
        .padding(.vertical, DS.Space.xs)
        .background(app.theme.semantic.surface)
        .overlay(Divider(), alignment: .top)
    }

    private func modeTab(_ m: AppState.Mode) -> some View {
        let isActive = app.mode == m
        return Button {
            app.mode = m
            Haptics.select()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: m.sfSymbol)
                    .font(.system(size: 18))
                Text(m.title)
                    .font(DS.font(.micro, weight: isActive ? .semibold : .regular, monospaced: true))
            }
            .frame(maxWidth: .infinity, minHeight: DS.minTarget)
            .foregroundStyle(isActive ? app.theme.semantic.accent : app.theme.semantic.inkMuted)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .a11y(m.title, value: isActive ? "selected" : "")
    }

    // MARK: - Current mode

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
                        app.previewCurrentTimbre()
                        Haptics.select()
                        dismiss()
                    } label: {
                        HStack {
                            Text(p.displayName)
                                .font(DS.font(.body, monospaced: true))
                            Spacer()
                            if app.currentPresetID == p.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(app.theme.semantic.accent)
                            }
                        }
                        .frame(minHeight: DS.minTarget)
                    }
                }
            }
            .navigationTitle("Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
