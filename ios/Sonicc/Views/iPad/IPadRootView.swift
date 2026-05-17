import SwiftUI

/// iPad-native shell. Sidebar (mode + presets) + performance surface
/// (keyboard / drums / pattern / sampler) + a thin right rail with the
/// patch inspector (waveform, envelope, filter, FX). The keyboard claims
/// the bulk of the canvas; the inspector is glanceable, not dominant.
struct IPadRootView: View {
    @EnvironmentObject var app: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar()
            NavigationSplitView(columnVisibility: $columnVisibility) {
                sidebar
                    .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            } content: {
                center
                    .navigationSplitViewColumnWidth(min: 480, ideal: 700)
            } detail: {
                InspectorPanel()
                    .frame(width: 200)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .navigationSplitViewColumnWidth(200)
            }
            .navigationSplitViewStyle(.balanced)
        }
        .background(app.theme.bg)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List {
                Section("MODE") {
                    ForEach(AppState.Mode.allCases) { m in
                        Button {
                            app.mode = m
                        } label: {
                            HStack {
                                Image(systemName: m.sfSymbol)
                                Text(m.title)
                                Spacer()
                                if app.mode == m {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(app.theme.text)
                    }
                }
                Section("PRESETS") {
                    ForEach(app.presets.presets) { p in
                        Button {
                            app.applyPreset(id: p.id)
                        } label: {
                            HStack {
                                Text(p.displayName)
                                    .font(.system(size: 12, design: .monospaced))
                                Spacer()
                                if app.currentPresetID == p.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .foregroundStyle(app.theme.text)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    @ViewBuilder
    private var center: some View {
        VStack(spacing: 0) {
            ControlBar(sequencer: app.sequencer)
            currentMode
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(app.theme.bg)
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
