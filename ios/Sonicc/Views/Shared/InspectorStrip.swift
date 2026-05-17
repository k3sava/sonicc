import SwiftUI

/// Horizontal inspector for iPad — full-width strip above the keyboard.
/// Four columns: Waveform · Envelope · Filter · Effects. Lays out
/// proportionally so columns share the available width evenly, with a
/// little extra given to Waveform + Effects (which carry more cells).
struct InspectorStrip: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        GeometryReader { geo in
            let totalGap = DS.Space.lg * 3
            let totalPad = DS.Space.lg * 2
            let usable   = max(0, geo.size.width - totalGap - totalPad)
            // Weighted split: Waveform 3, Envelope 2, Filter 2, Effects 3
            let unit = usable / 10
            let wWidth = unit * 3
            let envW   = unit * 2
            let filW   = unit * 2
            let fxW    = unit * 3
            HStack(alignment: .top, spacing: DS.Space.lg) {
                waveformColumn.frame(width: wWidth, alignment: .leading)
                envelopeColumn.frame(width: envW,   alignment: .leading)
                filterColumn.frame(width: filW,     alignment: .leading)
                fxColumn.frame(width: fxW,          alignment: .leading)
            }
            .padding(.horizontal, DS.Space.lg)
            .padding(.vertical, DS.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 168)
        .background(app.theme.semantic.surface)
        .overlay(Divider(), alignment: .bottom)
    }

    // MARK: - Sections

    private var waveformColumn: some View {
        sectionHeader("Waveform") {
            LazyVGrid(columns: waveformGridColumns, spacing: DS.Space.xs) {
                ForEach(Waveform.allCases) { w in waveformPill(w) }
            }
        }
    }

    private var envelopeColumn: some View {
        sectionHeader("Envelope") {
            VStack(spacing: DS.Space.xs) {
                slider("Atk", $app.synth.attack,  range: 0.001...2, unit: "s")
                slider("Dec", $app.synth.decay,   range: 0.01...2,  unit: "s")
                slider("Sus", $app.synth.sustain, range: 0...1,     unit: "")
                slider("Rel", $app.synth.release, range: 0.01...3,  unit: "s")
            }
        }
    }

    private var filterColumn: some View {
        sectionHeader("Filter · Level") {
            VStack(spacing: DS.Space.xs) {
                slider("Cut", $app.synth.filterFreq, range: 50...15000, unit: "Hz", format: "%.0f")
                slider("Res", $app.synth.filterRes,  range: 0.1...20,   unit: "Q")
                slider("Vol", $app.synth.volume,     range: 0...1,      unit: "")
                slider("Pan", $app.synth.pan,        range: -1...1,     unit: "")
            }
        }
    }

    private var fxColumn: some View {
        sectionHeader("Effects") {
            LazyVGrid(columns: fxGridColumns, spacing: DS.Space.xs) {
                fxToggle("Reverb",  \.reverb)
                fxToggle("Delay",   \.delay)
                fxToggle("Distort", \.distortion)
                fxToggle("Lo-Fi",   \.lofi)
                fxToggle("Chorus",  \.chorus)
                fxToggle("Phaser",  \.phaser)
                fxToggle("Comp",    \.compressor)
                fxToggle("Bitcrsh", \.bitcrusher)
                fxToggle("Tremolo", \.tremolo)
                fxToggle("EQ",      \.eq)
                fxToggle("Flanger", \.flanger)
                fxToggle("Autowah", \.autowah)
            }
        }
    }

    // MARK: - Grids

    private var waveformGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DS.Space.xs), count: 4)
    }

    private var fxGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: DS.Space.xs), count: 3)
    }

    // MARK: - Primitives

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
                .frame(maxWidth: .infinity, minHeight: 30)
                .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .fill(isActive ? app.theme.semantic.accent : app.theme.semantic.canvas))
                .foregroundStyle(isActive ? Color.white : app.theme.semantic.ink)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .stroke(isActive ? app.theme.semantic.accent : app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y("Waveform \(w.displayName)", value: isActive ? "selected" : "",
              hint: "Switches the synthesizer's tone and previews a quick middle C.")
    }

    @ViewBuilder
    private func sectionHeader<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(title)
                .font(DS.font(.label, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(app.theme.semantic.ink)
                .lineLimit(1)
            content()
        }
    }

    private func slider(_ label: String, _ value: Binding<Double>,
                        range: ClosedRange<Double>, unit: String,
                        format: String = "%.2f") -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(DS.font(.caption, weight: .medium, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkSoft)
                .frame(width: 32, alignment: .leading)
            Slider(value: value, in: range)
                .tint(app.theme.semantic.accent)
            Text(unitLabel(value.wrappedValue, format: format, unit: unit))
                .font(DS.font(.caption, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
                .frame(width: 52, alignment: .trailing)
                .lineLimit(1)
        }
        .a11y(label, value: unitLabel(value.wrappedValue, format: format, unit: unit))
    }

    private func unitLabel(_ v: Double, format: String, unit: String) -> String {
        let n = String(format: format, v)
        return unit.isEmpty ? n : "\(n) \(unit)"
    }

    private func fxToggle(_ label: String, _ kp: WritableKeyPath<SynthState.FXState, Bool>) -> some View {
        let isOn = app.synth.fx[keyPath: kp]
        return Button {
            var s = app.synth
            s.fx[keyPath: kp].toggle()
            app.synth = s
            Haptics.tap(.light)
            app.previewCurrentTimbre()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                Text(label)
                    .font(DS.font(.caption, weight: isOn ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                .fill(isOn ? app.theme.semantic.accentSoft : app.theme.semantic.canvas))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                .stroke(isOn ? app.theme.semantic.accent : app.theme.semantic.hairline))
            .foregroundStyle(isOn ? app.theme.semantic.accent : app.theme.semantic.inkSoft)
        }
        .buttonStyle(.plain)
        .a11y("Effect \(label)", value: isOn ? "on" : "off",
              hint: "Toggles the effect and previews the new tone.")
    }
}
