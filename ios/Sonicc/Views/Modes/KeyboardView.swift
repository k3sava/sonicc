import SwiftUI

/// Touch-driven piano keyboard. The keyboard itself is capped to a piano-
/// like height and anchored to the bottom of the performance surface; the
/// upper area carries the octave + bend controls and a held-note readout.
struct KeyboardView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 700
            let keyboardHeight: CGFloat = min(geo.size.height * 0.55,
                                              isWide ? 340 : 280)
            VStack(spacing: 0) {
                topPanel
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                ChordReadout()
                    .frame(maxHeight: .infinity)
                keyboard(width: geo.size.width)
                    .frame(height: keyboardHeight)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
    }

    private var topPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                octaveStepper
                Divider().frame(height: 28)
                PitchBendBar()
                    .frame(maxWidth: 260, maxHeight: 28)
                Spacer()
                heldReadout
            }
        }
    }

    private var octaveStepper: some View {
        HStack(spacing: 8) {
            Text("OCT")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
            Button { app.baseOctave = max(0, app.baseOctave - 1) } label: {
                Image(systemName: "minus")
                    .frame(width: 28, height: 28)
                    .background(app.theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(app.theme.border))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            Text("\(app.baseOctave)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .frame(minWidth: 24)
            Button { app.baseOctave = min(7, app.baseOctave + 1) } label: {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
                    .background(app.theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(app.theme.border))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .buttonStyle(.plain)
    }

    private var heldReadout: some View {
        let sorted = app.heldNotes.sorted { $0.midi < $1.midi }
        let label = sorted.isEmpty ? "—" : sorted.map(\.label).joined(separator: " ")
        return Text(label)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(sorted.isEmpty ? app.theme.textMuted : app.theme.accent)
            .lineLimit(1)
            .frame(minWidth: 60, alignment: .trailing)
    }

    private func keyboard(width: CGFloat) -> some View {
        let octaves = octaveCount(width: width)
        let pitches = makePitches(baseOctave: app.baseOctave, octaves: octaves)
        return MultiTouchKeyboard(
            pitches: pitches,
            theme: app.theme,
            heldNotes: app.heldNotes,
            onNoteOn: { app.noteOn(pitch: $0) },
            onNoteOff: { app.noteOff(pitch: $0) }
        )
    }

    private func octaveCount(width: CGFloat) -> Int {
        // Target ~32pt per white key on iPad, ~42pt on iPhone — both still
        // feel comfortable under a finger. Cap at 4 octaves so individual
        // keys never collapse below a chordable size.
        let target: CGFloat = width > 700 ? 32 : 42
        return Int(max(1, min(4, floor((width - 24) / (target * 7)))))
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
