import AVFoundation
import SwiftUI

/// Sampler — load audio from the mic, view the waveform, set in/out
/// points by dragging the green/red markers, and assign the slice to
/// one of four pads. Tap a pad to play; long-press for clear.
struct SamplerView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sampler: SamplerEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: DS.Space.md) {
            WaveformView(buffer: sampler.currentBuffer,
                         start: $sampler.sliceStart,
                         end: $sampler.sliceEnd)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(app.theme.canvasBG)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(app.theme.semantic.hairline)
                )

            padRow

            footerControls
        }
        .padding(DS.Space.md)
    }

    private var padRow: some View {
        HStack(spacing: DS.Space.md) {
            ForEach(0..<4, id: \.self) { i in
                padButton(i)
            }
        }
        .frame(height: 110)
    }

    @ViewBuilder
    private func padButton(_ i: Int) -> some View {
        let hasSample = sampler.pads[i] != nil
        Button {
            if hasSample { sampler.playPad(i); Haptics.tap(.medium) }
            else { sampler.sliceToPad(i); Haptics.notify(.success) }
        } label: {
            VStack(spacing: DS.Space.xs) {
                Text("PAD \(i + 1)")
                    .font(DS.font(.micro, weight: .semibold, monospaced: true))
                    .tracking(1)
                Spacer(minLength: 0)
                Image(systemName: hasSample ? "play.fill" : "scissors")
                    .font(.system(size: 26, weight: .medium))
                Spacer(minLength: 0)
                Text(hasSample ? "play" : "slice → pad")
                    .font(DS.font(.micro, monospaced: true))
            }
            .padding(DS.Space.sm)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(hasSample ? app.theme.semantic.accentSoft : app.theme.semantic.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(hasSample ? app.theme.semantic.accent : app.theme.semantic.hairline)
            )
            .foregroundStyle(hasSample ? app.theme.semantic.accent : app.theme.semantic.inkSoft)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                sampler.clearPad(i); Haptics.notify(.warning)
            } label: {
                Label("Clear", systemImage: "trash")
            }
        }
        .a11y("Pad \(i + 1)", value: hasSample ? "loaded" : "empty",
              hint: hasSample ? "Plays the loaded slice." : "Slices the current selection onto this pad.")
    }

    private var footerControls: some View {
        HStack(spacing: DS.Space.md) {
            Toggle(isOn: $sampler.loop) {
                HStack(spacing: 4) {
                    Image(systemName: "repeat").imageScale(.small)
                    Text("Loop").font(DS.font(.caption, weight: .medium))
                }
            }
            .toggleStyle(.switch)
            .tint(app.theme.semantic.accent)
            Spacer(minLength: 0)
            Text("In: \(Int(sampler.sliceStart * 100))%   Out: \(Int(sampler.sliceEnd * 100))%")
                .font(DS.font(.caption, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
        }
        .padding(.horizontal, DS.Space.xs)
        .frame(minHeight: DS.minTarget)
    }
}

/// Renders an AVAudioPCMBuffer as a waveform with two draggable slice
/// handles. When no buffer is loaded, shows a clear empty-state pointing
/// the user to Mic mode.
struct WaveformView: View {
    let buffer: AVAudioPCMBuffer?
    @Binding var start: Double
    @Binding var end: Double
    @EnvironmentObject var app: AppState

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                if let buf = buffer, let chan = buf.floatChannelData?[0] {
                    let count = Int(buf.frameLength)
                    let step = max(1, count / Int(geo.size.width))
                    Path { path in
                        let mid = geo.size.height / 2
                        for x in 0..<Int(geo.size.width) {
                            let idx = min(count - 1, x * step)
                            let amp = abs(chan[idx])
                            let h = CGFloat(amp) * geo.size.height
                            path.move(to: CGPoint(x: CGFloat(x), y: mid - h / 2))
                            path.addLine(to: CGPoint(x: CGFloat(x), y: mid + h / 2))
                        }
                    }
                    .stroke(app.theme.semantic.accent.opacity(0.85), lineWidth: 1)
                } else {
                    emptyState
                }
                marker(at: start, color: .green, geo: geo) { v in start = min(end - 0.01, v) }
                marker(at: end, color: .red, geo: geo) { v in end = max(start + 0.01, v) }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Space.sm) {
            Image(systemName: "waveform")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white.opacity(0.5))
            Text("No sample loaded")
                .font(DS.font(.body, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            Text("Record in Mic mode, then tap an empty pad to slice it here.")
                .font(DS.font(.caption))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(DS.Space.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func marker(at value: Double, color: Color, geo: GeometryProxy, set: @escaping (Double) -> Void) -> some View {
        let x = CGFloat(value) * geo.size.width
        Rectangle()
            .fill(color)
            .frame(width: 3)
            .position(x: x, y: geo.size.height / 2)
            .gesture(
                DragGesture()
                    .onChanged { g in
                        let v = max(0, min(1, Double(g.location.x / geo.size.width)))
                        set(v)
                    }
            )
    }
}
