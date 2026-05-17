import SwiftUI

/// Horizontal inspector for iPad — lives above the performance surface
/// and uses the full screen width. Four side-by-side columns: WAVEFORM,
/// ENVELOPE, FILTER, FX. Designed to be short enough that the keyboard
/// still owns the bottom half of the screen.
struct InspectorStrip: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            waveformColumn
                .frame(minWidth: 220, maxWidth: 280)
            envelopeColumn
                .frame(minWidth: 200, maxWidth: 260)
            filterColumn
                .frame(minWidth: 200, maxWidth: 260)
            fxColumn
                .frame(minWidth: 220, maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(app.theme.surface)
        .overlay(Divider(), alignment: .bottom)
    }

    // MARK: - Sections

    private var waveformColumn: some View {
        sectionHeader("WAVEFORM") {
            LazyVGrid(columns: waveformGridColumns, spacing: 4) {
                ForEach(Waveform.allCases) { w in
                    waveformPill(w)
                }
            }
        }
    }

    private var waveformGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
    }

    private func waveformPill(_ w: Waveform) -> some View {
        let isActive = app.synth.waveform == w
        return Button {
            var s = app.synth
            s.waveform = w
            app.synth = s
        } label: {
            Text(w.displayName)
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(isActive ? app.theme.accent : app.theme.bg)
                .foregroundStyle(isActive ? Color.white : app.theme.text)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(app.theme.border))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private var envelopeColumn: some View {
        sectionHeader("ENVELOPE") {
            VStack(spacing: 4) {
                sliderRow("ATTACK",  $app.synth.attack,  range: 0.001...2)
                sliderRow("DECAY",   $app.synth.decay,   range: 0.01...2)
                sliderRow("SUSTAIN", $app.synth.sustain, range: 0...1)
                sliderRow("RELEASE", $app.synth.release, range: 0.01...3)
            }
        }
    }

    private var filterColumn: some View {
        sectionHeader("FILTER · LEVEL") {
            VStack(spacing: 4) {
                sliderRow("CUTOFF", $app.synth.filterFreq, range: 50...15000, format: "%.0f")
                sliderRow("RES",    $app.synth.filterRes,  range: 0.1...20)
                sliderRow("VOL",    $app.synth.volume,     range: 0...1)
                sliderRow("PAN",    $app.synth.pan,        range: -1...1)
            }
        }
    }

    private var fxColumn: some View {
        sectionHeader("FX") {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3),
                spacing: 4
            ) {
                fxToggle("Reverb",     \.reverb)
                fxToggle("Delay",      \.delay)
                fxToggle("Distortion", \.distortion)
                fxToggle("Lo-Fi",      \.lofi)
                fxToggle("Chorus",     \.chorus)
                fxToggle("Phaser",     \.phaser)
                fxToggle("Comp.",      \.compressor)
                fxToggle("Bitcrush",   \.bitcrusher)
                fxToggle("Tremolo",    \.tremolo)
                fxToggle("EQ",         \.eq)
                fxToggle("Flanger",    \.flanger)
                fxToggle("Autowah",    \.autowah)
            }
        }
    }

    // MARK: - Primitives

    @ViewBuilder
    private func sectionHeader<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(app.theme.textMuted)
            content()
        }
    }

    private func sliderRow(_ label: String, _ value: Binding<Double>, range: ClosedRange<Double>, format: String = "%.2f") -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
                .frame(width: 50, alignment: .leading)
            Slider(value: value, in: range)
                .tint(app.theme.accent)
            Text(String(format: format, value.wrappedValue))
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(app.theme.textMuted.opacity(0.8))
                .frame(width: 38, alignment: .trailing)
        }
    }

    private func fxToggle(_ label: String, _ kp: WritableKeyPath<SynthState.FXState, Bool>) -> some View {
        let isOn = app.synth.fx[keyPath: kp]
        return Button {
            var s = app.synth
            s.fx[keyPath: kp].toggle()
            app.synth = s
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 9))
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(isOn ? app.theme.accentSoft : app.theme.bg)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(isOn ? app.theme.accent : app.theme.border))
            .foregroundStyle(isOn ? app.theme.accent : app.theme.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }
}
