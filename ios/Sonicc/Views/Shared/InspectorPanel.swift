import SwiftUI

/// Sound-design sheet on iPhone — waveform, ADSR, filter, FX. Each
/// waveform/FX tap previews the new timbre via a quick middle C so the
/// player hears every change. Reflects the same content as the iPad
/// InspectorStrip but in a vertical, scroll-friendly form.
struct InspectorPanel: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                section("Waveform") {
                    LazyVGrid(columns: waveformColumns, spacing: DS.Space.xs) {
                        ForEach(Waveform.allCases) { w in
                            waveformPill(w)
                        }
                    }
                }
                section("Envelope") {
                    VStack(spacing: DS.Space.xs) {
                        slider("Attack",  $app.synth.attack,  range: 0.001...2, unit: "s")
                        slider("Decay",   $app.synth.decay,   range: 0.01...2,  unit: "s")
                        slider("Sustain", $app.synth.sustain, range: 0...1,     unit: "")
                        slider("Release", $app.synth.release, range: 0.01...3,  unit: "s")
                    }
                }
                section("Filter · Level") {
                    VStack(spacing: DS.Space.xs) {
                        slider("Cutoff", $app.synth.filterFreq, range: 50...15000, unit: "Hz", format: "%.0f")
                        slider("Res",    $app.synth.filterRes,  range: 0.1...20,   unit: "Q")
                        slider("Volume", $app.synth.volume,     range: 0...1,      unit: "")
                        slider("Pan",    $app.synth.pan,        range: -1...1,     unit: "")
                    }
                }
                section("Effects") {
                    LazyVGrid(columns: fxColumns, spacing: DS.Space.xs) {
                        fx("Reverb",      \.reverb)
                        fx("Delay",       \.delay)
                        fx("Distortion",  \.distortion)
                        fx("Lo-Fi",       \.lofi)
                        fx("Chorus",      \.chorus)
                        fx("Phaser",      \.phaser)
                        fx("Compressor",  \.compressor)
                        fx("Bitcrusher",  \.bitcrusher)
                        fx("Tremolo",     \.tremolo)
                        fx("EQ",          \.eq)
                        fx("Flanger",     \.flanger)
                        fx("Autowah",     \.autowah)
                    }
                }
            }
            .padding(DS.Space.lg)
        }
    }

    private var waveformColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DS.Space.xs), count: 3)
    }

    private var fxColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DS.Space.xs), count: 2)
    }

    private func waveformPill(_ w: Waveform) -> some View {
        let isActive = app.synth.waveform == w
        return Button {
            var s = app.synth
            s.waveform = w
            app.synth = s
            Haptics.select()
            app.previewCurrentTimbre()
        } label: {
            Text(w.displayName)
                .font(DS.font(.caption, weight: isActive ? .semibold : .regular, monospaced: true))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: DS.minTarget)
                .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .fill(isActive ? app.theme.semantic.accent : app.theme.semantic.canvas))
                .foregroundStyle(isActive ? Color.white : app.theme.semantic.ink)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .stroke(isActive ? app.theme.semantic.accent : app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y("Waveform \(w.displayName)", value: isActive ? "selected" : "")
    }

    private func slider(_ label: String, _ value: Binding<Double>,
                        range: ClosedRange<Double>, unit: String,
                        format: String = "%.2f") -> some View {
        HStack(spacing: DS.Space.sm) {
            Text(label)
                .font(DS.font(.label, weight: .medium))
                .foregroundStyle(app.theme.semantic.inkSoft)
                .frame(width: 76, alignment: .leading)
            Slider(value: value, in: range)
                .tint(app.theme.semantic.accent)
            Text(unitLabel(value.wrappedValue, format: format, unit: unit))
                .font(DS.font(.label, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
                .frame(width: 64, alignment: .trailing)
        }
        .a11y(label, value: unitLabel(value.wrappedValue, format: format, unit: unit))
    }

    private func unitLabel(_ v: Double, format: String, unit: String) -> String {
        let n = String(format: format, v)
        return unit.isEmpty ? n : "\(n) \(unit)"
    }

    private func fx(_ label: String, _ kp: WritableKeyPath<SynthState.FXState, Bool>) -> some View {
        let isOn = app.synth.fx[keyPath: kp]
        return Button {
            var s = app.synth
            s.fx[keyPath: kp].toggle()
            app.synth = s
            Haptics.tap(.light)
            app.previewCurrentTimbre()
        } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                Text(label)
                    .font(DS.font(.label, weight: isOn ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DS.Space.sm)
            .frame(maxWidth: .infinity, minHeight: DS.minTarget)
            .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                .fill(isOn ? app.theme.semantic.accentSoft : app.theme.semantic.canvas))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                .stroke(isOn ? app.theme.semantic.accent : app.theme.semantic.hairline))
            .foregroundStyle(isOn ? app.theme.semantic.accent : app.theme.semantic.inkSoft)
        }
        .buttonStyle(.plain)
        .a11y("Effect \(label)", value: isOn ? "on" : "off")
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(title)
                .font(DS.font(.label, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(app.theme.semantic.ink)
            content()
        }
    }
}
