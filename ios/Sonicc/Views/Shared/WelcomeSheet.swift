import SwiftUI

/// First-launch welcome. Brief, warm, sets the tone — Apple-style "what
/// you can do" page with five iconified rows. Dismisses to the live app
/// and marks hasOnboarded = true.
struct WelcomeSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    header
                    rows
                    note
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.top, DS.Space.xl)
                .padding(.bottom, DS.Space.lg)
            }
            footer
        }
        .background(app.theme.semantic.canvas.ignoresSafeArea())
        .interactiveDismissDisabled(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("sonicc")
                .font(.system(.largeTitle, design: .default).weight(.semibold))
                .foregroundStyle(app.theme.semantic.ink)
            Text("a pocket instrument")
                .font(DS.font(.body, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkSoft)
        }
        .padding(.bottom, DS.Space.md)
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            row("pianokeys", "Keys",
                "Play with velocity, sustain, a real pitch-bend wheel, and a scale picker that keeps you in key.")
            row("circle.grid.3x3.fill", "Drums",
                "8 sound-designed kit elements with hit-pulse haptics.")
            row("square.grid.4x3.fill", "Pattern",
                "Step sequencer with auto-save. Your work survives every launch.")
            row("waveform", "Sampler",
                "Slice a sample into 4 pads. Loop, pitch, play.")
            row("mic.fill", "Mic",
                "Record vocals or any sound. Bounce to M4A or WAV. Share to anywhere.")
        }
    }

    private func row(_ symbol: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: DS.Space.md) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(app.theme.semantic.accent)
                .frame(width: 36, height: 36, alignment: .top)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.font(.body, weight: .semibold))
                    .foregroundStyle(app.theme.semantic.ink)
                Text(body)
                    .font(DS.font(.label))
                    .foregroundStyle(app.theme.semantic.inkSoft)
            }
        }
        .a11y("\(title): \(body)")
    }

    private var note: some View {
        Text("Headphones recommended. Sonicc respects your system Reduce Motion, Dynamic Type, and VoiceOver settings.")
            .font(DS.font(.caption))
            .foregroundStyle(app.theme.semantic.inkMuted)
            .padding(.top, DS.Space.md)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                app.hasOnboarded = true
                Haptics.notify(.success)
                dismiss()
            } label: {
                Text("Start playing")
                    .font(DS.font(.body, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                        .fill(app.theme.semantic.accent))
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.md)
            .a11y("Start playing", hint: "Dismisses this welcome and opens the keyboard.")
        }
        .background(app.theme.semantic.surface)
    }
}
