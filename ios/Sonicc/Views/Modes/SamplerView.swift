import AVFoundation
import SwiftUI

/// Waveform display + slice markers + 4 pads.
struct SamplerView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sampler: SamplerEngine

    var body: some View {
        VStack(spacing: 16) {
            WaveformView(buffer: sampler.currentBuffer, start: $sampler.sliceStart, end: $sampler.sliceEnd)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(app.theme.canvasBG)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    Button {
                        if sampler.pads[i] != nil {
                            sampler.playPad(i)
                        } else {
                            sampler.sliceToPad(i)
                        }
                    } label: {
                        VStack {
                            Text("PAD \(i + 1)")
                                .font(.system(size: 10, design: .monospaced))
                            Spacer()
                            Image(systemName: sampler.pads[i] == nil ? "scissors" : "play.fill")
                                .font(.system(size: 24))
                            Spacer()
                            Text(sampler.pads[i] == nil ? "slice" : "play")
                                .font(.system(size: 10, design: .monospaced))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .background(sampler.pads[i] == nil ? app.theme.surface : app.theme.accentSoft)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(app.theme.border))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            sampler.clearPad(i)
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    }
                }
            }

            HStack {
                Toggle("Loop", isOn: $sampler.loop)
                    .toggleStyle(.switch)
                    .font(.system(size: 11, design: .monospaced))
                Spacer()
                Text("Start: \(Int(sampler.sliceStart * 100))%   End: \(Int(sampler.sliceEnd * 100))%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(app.theme.textMuted)
            }
        }
        .padding(16)
    }
}

/// Renders an AVAudioPCMBuffer as a waveform with two draggable slice handles.
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
                    .stroke(app.theme.accent.opacity(0.85), lineWidth: 1)
                } else {
                    Text("No sample loaded — record in Mic mode or hand-off to a pad")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                // Slice markers
                marker(at: start, color: .green, geo: geo) { v in start = min(end - 0.01, v) }
                marker(at: end, color: .red, geo: geo) { v in end = max(start + 0.01, v) }
            }
        }
    }

    @ViewBuilder
    private func marker(at value: Double, color: Color, geo: GeometryProxy, set: @escaping (Double) -> Void) -> some View {
        let x = CGFloat(value) * geo.size.width
        Rectangle()
            .fill(color)
            .frame(width: 2)
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
