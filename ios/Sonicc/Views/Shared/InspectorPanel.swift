import SwiftUI

/// FX toggles + ADSR + filter knobs. Used by both the iPad inspector and
/// the iPhone settings sheet.
struct InspectorPanel: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("WAVEFORM") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 6)], spacing: 6) {
                        ForEach(Waveform.allCases) { w in
                            Button {
                                var s = app.synth
                                s.waveform = w
                                app.synth = s
                            } label: {
                                Text(w.displayName)
                                    .font(.system(size: 11, design: .monospaced))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
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
                    HStack {
                        Knob(label: "ATTACK", value: $app.synth.attack, range: 0.001...2, defaultValue: 0.01)
                        Knob(label: "DECAY", value: $app.synth.decay, range: 0.01...2, defaultValue: 0.2)
                        Knob(label: "SUSTAIN", value: $app.synth.sustain, range: 0...1, defaultValue: 0.7)
                        Knob(label: "RELEASE", value: $app.synth.release, range: 0.01...3, defaultValue: 0.3)
                    }
                }

                section("FILTER") {
                    HStack {
                        Knob(label: "CUTOFF", value: $app.synth.filterFreq, range: 50...15000, defaultValue: 4000) { String(format: "%.0fHz", $0) }
                        Knob(label: "RES", value: $app.synth.filterRes, range: 0.1...20, defaultValue: 1.0)
                        Knob(label: "VOL", value: $app.synth.volume, range: 0...1, defaultValue: 0.7)
                        Knob(label: "PAN", value: $app.synth.pan, range: -1...1, defaultValue: 0)
                    }
                }

                section("FX") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 6)], spacing: 6) {
                        fxToggle("Reverb", \.reverb)
                        fxToggle("Delay", \.delay)
                        fxToggle("Distortion", \.distortion)
                        fxToggle("Lo-Fi", \.lofi)
                        fxToggle("Chorus", \.chorus)
                        fxToggle("Phaser", \.phaser)
                        fxToggle("Compressor", \.compressor)
                        fxToggle("Bitcrusher", \.bitcrusher)
                        fxToggle("Tremolo", \.tremolo)
                        fxToggle("EQ", \.eq)
                        fxToggle("Flanger", \.flanger)
                        fxToggle("Autowah", \.autowah)
                    }
                }
            }
            .padding(16)
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
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 11, design: .monospaced))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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
