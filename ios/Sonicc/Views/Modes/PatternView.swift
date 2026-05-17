import SwiftUI

/// Step sequencer grid with layer switcher and step-count selector.
struct PatternView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sequencer: Sequencer

    var body: some View {
        VStack(spacing: 12) {
            controls
            Divider()
            grid
        }
        .padding(16)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Picker("Layer", selection: $sequencer.layer) {
                Text("SYNTH").tag(Sequencer.Layer.synth)
                Text("DRUM").tag(Sequencer.Layer.drum)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)

            HStack(spacing: 4) {
                ForEach(Sequencer.StepSize.allCases) { s in
                    Button {
                        sequencer.setStepCount(s)
                    } label: {
                        Text(s.label)
                            .font(.system(size: 10, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(sequencer.stepCount == s ? app.theme.accent : app.theme.surface)
                            .foregroundStyle(sequencer.stepCount == s ? .white : app.theme.text)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(app.theme.border))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button {
                sequencer.clear()
            } label: {
                Label("Clear", systemImage: "trash")
                    .font(.system(size: 11, design: .monospaced))
            }
        }
    }

    private var grid: some View {
        let rows = 8
        let steps = sequencer.stepCount.rawValue
        return GeometryReader { geo in
            let gap: CGFloat = 4
            // Target ~32pt per cell for comfortable tapping; if the grid would
            // need to be smaller than that to fit, switch to horizontal scroll.
            let cellH = (geo.size.height - gap * CGFloat(rows + 1)) / CGFloat(rows)
            let fitWidth = (geo.size.width - gap * CGFloat(steps + 1)) / CGFloat(steps)
            let minTouch: CGFloat = 32
            let cellW = max(minTouch, fitWidth)
            let size = min(cellW, max(minTouch, cellH))
            let needsScroll = cellW > fitWidth
            let body = VStack(spacing: gap) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<steps, id: \.self) { step in
                            cell(row: row, step: step)
                                .frame(width: size, height: size)
                        }
                    }
                }
            }
            .padding(gap)
            if needsScroll {
                ScrollView(.horizontal, showsIndicators: false) { body }
            } else {
                body
            }
        }
    }

    @ViewBuilder
    private func cell(row: Int, step: Int) -> some View {
        let on: Bool = {
            switch sequencer.layer {
            case .synth: return sequencer.synthGrid.isOn(row: row, step: step)
            case .drum: return sequencer.drumGrid.isOn(row: row, step: step)
            }
        }()
        let active = sequencer.currentStep == step
        Button {
            sequencer.toggleCell(row: row, step: step)
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(on ? app.theme.accent : (active ? app.theme.accentSoft : app.theme.surface))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(active ? app.theme.accent : app.theme.border, lineWidth: active ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}
