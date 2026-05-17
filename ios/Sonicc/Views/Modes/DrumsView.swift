import SwiftUI

/// 4×2 drum pad grid. Pads are square, hit Apple's 44pt minimum (in
/// practice much larger), animate on hit with both color flash + a
/// short scale pulse, fire haptic. VoiceOver labels each kit element.
struct DrumsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        GeometryReader { geo in
            let cols = 4
            let rows = 2
            let gap: CGFloat = DS.Space.md
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let kind: DrumKind
    @State private var pulsing = false

    var body: some View {
        Button {
            app.playDrum(index: kind.rawValue)
            Haptics.tap(.medium)
            pulsing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { pulsing = false }
        } label: {
            VStack(spacing: DS.Space.xs) {
                Spacer()
                Image(systemName: kind.sfSymbol)
                    .font(.system(size: 36, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .opacity(pulsing ? 1 : 0.7)
                    .scaleEffect(pulsing && !reduceMotion ? 1.12 : 1.0)
                Spacer()
                Text(kind.label.uppercased())
                    .font(DS.font(.caption, weight: .semibold, monospaced: true))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DS.Space.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .fill(pulsing ? app.theme.semantic.accent : app.theme.semantic.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(pulsing ? app.theme.semantic.accent : app.theme.semantic.hairline, lineWidth: 1)
            )
            .foregroundStyle(pulsing ? Color.white : app.theme.semantic.ink)
            .shadow(color: .black.opacity(pulsing ? 0.15 : 0.05),
                    radius: pulsing ? 8 : 4,
                    y: pulsing ? 3 : 1)
        }
        .buttonStyle(.plain)
        .animation(DS.spring(reduceMotion: reduceMotion), value: pulsing)
        .hoverEffect(.lift)
        .a11y("\(kind.label) drum pad",
              hint: "Tap to trigger \(kind.label).")
    }
}

extension DrumKind {
    var sfSymbol: String {
        switch self {
        case .kick:    return "circle.fill"
        case .snare:   return "circle.dotted"
        case .hihat:   return "circle.hexagongrid.fill"
        case .clap:    return "hands.clap.fill"
        case .tom:     return "circle.grid.2x1.fill"
        case .crash:   return "burst.fill"
        case .perc:    return "circle.grid.3x3.fill"
        case .cowbell: return "bell.fill"
        }
    }
}
