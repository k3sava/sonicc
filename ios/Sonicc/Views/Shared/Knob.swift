import SwiftUI

/// Drag-to-adjust circular knob. Double-tap to reset.
struct Knob: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let defaultValue: Double
    var formatter: (Double) -> String = { String(format: "%.2f", $0) }

    @State private var startValue: Double?
    @EnvironmentObject var app: AppState

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(app.theme.border, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: normalized)
                    .stroke(app.theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(app.theme.surface)
                    .padding(8)
                Rectangle()
                    .fill(app.theme.text)
                    .frame(width: 2, height: 12)
                    .offset(y: -14)
                    .rotationEffect(.degrees(-135 + normalized * 270))
            }
            .frame(width: 52, height: 52)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if startValue == nil { startValue = value }
                        let dy = -g.translation.height
                        let delta = Double(dy) / 150.0 * (range.upperBound - range.lowerBound)
                        let newValue = (startValue ?? value) + delta
                        value = min(range.upperBound, max(range.lowerBound, newValue))
                    }
                    .onEnded { _ in startValue = nil }
            )
            .onTapGesture(count: 2) {
                value = defaultValue
            }
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
            Text(formatter(value))
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(app.theme.text)
        }
    }

    private var normalized: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return (value - range.lowerBound) / span
    }
}
