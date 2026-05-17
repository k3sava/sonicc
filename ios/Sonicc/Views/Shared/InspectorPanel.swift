import SwiftUI

/// FX toggles + ADSR + filter knobs. Lives as a thin right-rail on iPad
/// (~200pt wide) and as a settings sheet on iPhone. All sections collapse
/// to a single-column vertical layout so they fit a narrow rail cleanly.
struct InspectorPanel: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section("WAVEFORM") {
                    // Two compact columns of pills — readable at ~180pt, comfy at ~220pt.
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 6)], spacing: 6) {
                        ForEach(Waveform.allCases) { w in
                            Button {
                                var s = app.synth
                                s.waveform = w
                                app.synth = s
                            } label: {
                                Text(w.displayName)
                                    .font(.system(size: 11, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(app.synth.waveform == w ? app.theme.accent : app.theme.surface)
                                    .foregroundStyle(app.synth.waveform == w ? .white : app.theme.text)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(app.theme.border))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                section("ENVELOPE") {
                    sliderRow("ATTACK",  value: $app.synth.attack,     range: 0.001...2)
                    sliderRow("DECAY",   value: $app.synth.decay,      range: 0.01...2)
                    sliderRow("SUSTAIN", value: $app.synth.sustain,    range: 0...1)
                    sliderRow("RELEASE", value: $app.synth.release,    range: 0.01...3)
                }

                section("FILTER") {
                    sliderRow("CUTOFF", value: $app.synth.filterFreq, range: 50...15000, format: "%.0fHz")
                    sliderRow("RES",    value: $app.synth.filterRes,  range: 0.1...20)
                    sliderRow("VOL",    value: $app.synth.volume,     range: 0...1)
                    sliderRow("PAN",    value: $app.synth.pan,        range: -1...1)
                }

                section("FX") {
                    VStack(spacing: 4) {
                        fxToggle("Reverb",     \.reverb)
                        fxToggle("Delay",      \.delay)
                        fxToggle("Distortion", \.distortion)
                        fxToggle("Lo-Fi",      \.lofi)
                        fxToggle("Chorus",     \.chorus)
                        fxToggle("Phaser",     \.phaser)
                        fxToggle("Compressor", \.compressor)
                        fxToggle("Bitcrusher", \.bitcrusher)
                        fxToggle("Tremolo",    \.tremolo)
                        fxToggle("EQ",         \.eq)
                        fxToggle("Flanger",    \.flanger)
                        fxToggle("Autowah",    \.autowah)
                    }
                }
            }
            .padding(14)
        }
    }

    @ViewBuilder
    private func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, format: String = "%.2f") -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted.opacity(0.8))
            }
            Slider(value: value, in: range)
                .tint(app.theme.accent)
        }
    }

    private func fxToggle(_ label: String, _ kp: WritableKeyPath<SynthState.FXState, Bool>) -> some View {
        let isOn = app.synth.fx[keyPath: kp]
        return Button {
            var s = app.synth
            s.fx[keyPath: kp].toggle()
            app.synth = s
        } label: {
            HStack {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11, design: .monospaced))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isOn ? app.theme.accentSoft : app.theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isOn ? app.theme.accent : app.theme.border))
            .foregroundStyle(isOn ? app.theme.accent : app.theme.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
            content()
        }
    }
}
