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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                HeaderBar(onSettings: { showSettings = true })
                topBar
                currentMode
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(app.theme.semantic.canvas)
                modeTabs
            }
            // Floating thumb-zone cluster — play + record live where the
            // thumb can reach them on a phone held in one hand.
            FloatingTransport(sequencer: app.sequencer)
                .padding(.trailing, DS.Space.md)
                .padding(.bottom, 60)   // sits above the tab bar
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

    // MARK: - Top bar (chrome — play/record live in the floating cluster)

    private var topBar: some View {
        HStack(spacing: DS.Space.sm) {
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

    @State private var showBPMEditor = false

    private var bpmDisplay: some View {
        Button {
            showBPMEditor = true
            Haptics.select()
        } label: {
            HStack(spacing: 4) {
                Text("\(Int(app.sequencer.bpm))")
                    .font(DS.font(.body, weight: .semibold, monospaced: true))
                Text("BPM")
                    .font(DS.font(.micro, weight: .semibold, monospaced: true))
                    .foregroundStyle(app.theme.semantic.inkMuted)
            }
            .padding(.horizontal, DS.Space.md)
            .frame(minHeight: DS.minTarget)
            .background(Capsule().fill(app.theme.semantic.surface))
            .overlay(Capsule().stroke(app.theme.semantic.hairline))
            .foregroundStyle(app.theme.semantic.ink)
        }
        .buttonStyle(.plain)
        .alert("Tempo", isPresented: $showBPMEditor) {
            TextField("BPM", value: Binding(
                get: { app.sequencer.bpm },
                set: { app.sequencer.bpm = max(40, min(300, $0)) }
            ), format: .number)
                .keyboardType(.decimalPad)
            Button("OK") { Haptics.notify(.success) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Range 40 – 300 BPM")
        }
        .a11y("Tempo", value: "\(Int(app.sequencer.bpm)) BPM", hint: "Tap to type a value.")
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
