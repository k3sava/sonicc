import SwiftUI

/// iPad shell. Vertical stack — header, transport, full-width inspector
/// strip, then the performance surface fills the rest. No right rail; the
/// keyboard and pattern grid get the full screen width.
struct IPadRootView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar()
            ControlBar(sequencer: app.sequencer)
            InspectorStrip()
            currentMode
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(app.theme.bg)
        }
        .background(app.theme.bg)
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
