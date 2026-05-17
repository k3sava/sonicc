import SwiftUI

/// Touch-driven piano keyboard. Adapts to width: on iPad in landscape we
/// show 2.5 octaves; on iPhone portrait we show 1 octave plus shift buttons.
struct KeyboardView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        VStack(spacing: 8) {
            octaveControl
            GeometryReader { geo in
                let octaves = octaveCount(width: geo.size.width)
                let pitches = makePitches(baseOctave: app.baseOctave, octaves: octaves)
                MultiTouchKeyboard(
                    pitches: pitches,
                    theme: app.theme,
                    heldNotes: app.heldNotes,
                    onNoteOn: { app.noteOn(pitch: $0) },
                    onNoteOff: { app.noteOff(pitch: $0) }
                )
            }
        }
        .padding(16)
    }

    private func octaveCount(width: CGFloat) -> Int {
        // Target ~36pt per white key. The keys are tall touch zones, so a
        // narrower key is still comfortable, and this lets 2 octaves fit
        // in an iPad center column with both side rails open (~544pt).
        let target: CGFloat = 36
        return Int(max(1, min(4, floor(width / (target * 7)))))
    }

    private func makePitches(baseOctave: Int, octaves: Int) -> [NotePitch] {
        var p: [NotePitch] = []
        for o in 0..<octaves {
            for n in 0..<12 {
                p.append(NotePitch(note: n, octave: baseOctave + o))
            }
        }
        return p
    }

    private var octaveControl: some View {
        HStack {
            Text("OCTAVE")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
            Button { app.baseOctave = max(0, app.baseOctave - 1) } label: {
                Image(systemName: "minus")
            }
            Text("\(app.baseOctave)")
                .font(.system(size: 14, design: .monospaced))
                .frame(minWidth: 30)
            Button { app.baseOctave = min(7, app.baseOctave + 1) } label: {
                Image(systemName: "plus")
            }
            Spacer()
            PitchBendBar()
                .frame(width: 180, height: 28)
        }
    }
}

/// Two-axis bend bar; horizontal drag = pitch bend, snaps back on release.
struct PitchBendBar: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(app.theme.border)
                    .background(RoundedRectangle(cornerRadius: 14).fill(app.theme.surface))
                Circle()
                    .fill(app.theme.accent)
                    .frame(width: 22, height: 22)
                    .offset(x: CGFloat(app.pitchBend) * geo.size.width / 2 - 11)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let mid = geo.size.width / 2
                        let v = Double((g.location.x - mid) / mid)
                        app.setPitchBend(v)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.2)) { app.setPitchBend(0) }
                    }
            )
        }
    }
}
