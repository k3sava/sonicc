import SwiftUI

/// 4×2 drum pad grid. Adapts to available width; pads always stay square.
struct DrumsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        GeometryReader { geo in
            let cols = 4
            let rows = 2
            let gap: CGFloat = 12
            let padW = (geo.size.width - gap * CGFloat(cols + 1)) / CGFloat(cols)
            let padH = (geo.size.height - gap * CGFloat(rows + 1)) / CGFloat(rows)
            let size = min(padW, padH)
            VStack(spacing: gap) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { c in
                            let i = r * cols + c
                            DrumPad(kind: DrumKind(rawValue: i) ?? .kick)
                                .frame(width: size, height: size)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(gap)
        }
    }
}

struct DrumPad: View {
    @EnvironmentObject var app: AppState
    let kind: DrumKind
    @State private var pulsing = false

    var body: some View {
        Button {
            app.playDrum(index: kind.rawValue)
            pulsing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { pulsing = false }
        } label: {
            VStack {
                Spacer()
                Image(systemName: "circle.fill")
                    .font(.system(size: 28))
                    .opacity(pulsing ? 1 : 0.35)
                Spacer()
                Text(kind.label.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(pulsing ? app.theme.accent : app.theme.surface)
            .foregroundStyle(pulsing ? .white : app.theme.text)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(app.theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.12), value: pulsing)
    }
}
