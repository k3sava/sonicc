import SwiftUI

/// First-launch welcome with a choreographed reveal. Wordmark fades up
/// and breathes, each of the five surface rows staggers in with a
/// selection haptic, and the Start button pulses gently to invite a tap.
struct WelcomeSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var wordmarkIn = false
    @State private var rowsIn: [Bool] = Array(repeating: false, count: 5)
    @State private var ctaIn = false
    @State private var ctaBreath = false

    private struct Row {
        let symbol: String
        let title: String
        let body: String
    }

    private let rows: [Row] = [
        Row(symbol: "pianokeys",
            title: "Keys",
            body: "Velocity, sustain, a real pitch-bend wheel, and a scale picker that keeps you in key."),
        Row(symbol: "circle.grid.3x3.fill",
            title: "Drums",
            body: "Eight sound-designed kit elements. Hit-pulse haptics on every tap."),
        Row(symbol: "square.grid.4x3.fill",
            title: "Pattern",
            body: "Step sequencer with auto-save. Your work survives every launch."),
        Row(symbol: "waveform",
            title: "Sampler",
            body: "Slice a sample into four pads. Loop, pitch, play."),
        Row(symbol: "mic.fill",
            title: "Mic",
            body: "Record any sound. Bounce to M4A or WAV. Share anywhere."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    header
                    rowsView
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
        .onAppear(perform: choreograph)
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("sonicc")
                .font(.system(.largeTitle, design: .default).weight(.semibold))
                .foregroundStyle(app.theme.semantic.ink)
                .opacity(wordmarkIn ? 1 : 0)
                .scaleEffect(wordmarkIn ? 1 : 0.94, anchor: .leading)
            Text("a pocket instrument")
                .font(DS.font(.body, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkSoft)
                .opacity(wordmarkIn ? 1 : 0)
                .offset(y: wordmarkIn ? 0 : 6)
        }
        .padding(.bottom, DS.Space.md)
        .animation(reduceMotion ? .none : .spring(response: 0.55, dampingFraction: 0.78),
                   value: wordmarkIn)
    }

    private var rowsView: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, r in
                rowView(r)
                    .opacity(rowsIn[idx] ? 1 : 0)
                    .offset(x: rowsIn[idx] ? 0 : -18)
                    .animation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.82),
                               value: rowsIn[idx])
            }
        }
    }

    private func rowView(_ r: Row) -> some View {
        HStack(alignment: .top, spacing: DS.Space.md) {
            Image(systemName: r.symbol)
                .font(.system(size: 26, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(app.theme.semantic.accent)
                .frame(width: 36, height: 36, alignment: .top)
            VStack(alignment: .leading, spacing: 2) {
                Text(r.title)
                    .font(DS.font(.body, weight: .semibold))
                    .foregroundStyle(app.theme.semantic.ink)
                Text(r.body)
                    .font(DS.font(.label))
                    .foregroundStyle(app.theme.semantic.inkSoft)
            }
        }
        .a11y("\(r.title): \(r.body)")
    }

    private var note: some View {
        Text("Headphones recommended. Sonicc respects your system Reduce Motion, Dynamic Type, and VoiceOver settings.")
            .font(DS.font(.caption))
            .foregroundStyle(app.theme.semantic.inkMuted)
            .padding(.top, DS.Space.md)
            .opacity(ctaIn ? 1 : 0)
            .animation(reduceMotion ? .none : .easeOut(duration: 0.4), value: ctaIn)
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
                    .scaleEffect(ctaBreath ? 1.015 : 1.0)
                    .shadow(color: app.theme.semantic.accent.opacity(ctaIn ? 0.28 : 0),
                            radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.md)
            .opacity(ctaIn ? 1 : 0)
            .a11y("Start playing", hint: "Dismisses this welcome and opens the keyboard.")
        }
        .background(app.theme.semantic.surface)
        .animation(reduceMotion ? .none : .spring(response: 0.55, dampingFraction: 0.85), value: ctaIn)
        .animation(reduceMotion ? .none : .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                   value: ctaBreath)
    }

    // MARK: - Choreography

    private func choreograph() {
        // Reduce Motion: snap-in everything immediately, skip haptics.
        if reduceMotion {
            wordmarkIn = true
            for i in rowsIn.indices { rowsIn[i] = true }
            ctaIn = true
            return
        }
        // Wordmark first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            wordmarkIn = true
            Haptics.tap(.soft)
        }
        // Rows stagger in
        for i in rowsIn.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45 + Double(i) * 0.10) {
                rowsIn[i] = true
                Haptics.select()
            }
        }
        // CTA last, then start its breathing pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.10) {
            ctaIn = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.40) {
            ctaBreath = true
        }
    }
}
