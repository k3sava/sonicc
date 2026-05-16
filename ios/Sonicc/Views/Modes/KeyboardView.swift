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
                KeyboardPanel(baseOctave: app.baseOctave, octaves: octaves)
            }
        }
        .padding(16)
    }

    private func octaveCount(width: CGFloat) -> Int {
        // 7 white keys per octave, target ~64pt per white key for touch.
        let target: CGFloat = 64
        let octaves = Int(max(1, min(4, floor(width / (target * 7)))))
        return octaves
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
            // Pitch bend slider
            PitchBendBar()
                .frame(width: 180, height: 28)
        }
    }
}

struct KeyboardPanel: View {
    @EnvironmentObject var app: AppState
    let baseOctave: Int
    let octaves: Int

    private var pitches: [NotePitch] {
        var p: [NotePitch] = []
        for o in 0..<octaves {
            for n in 0..<12 {
                p.append(NotePitch(note: n, octave: baseOctave + o))
            }
        }
        return p
    }

    var body: some View {
        let whiteIndices = pitches.indices.filter { !pitches[$0].isBlack }
        let blackIndices = pitches.indices.filter { pitches[$0].isBlack }
        GeometryReader { geo in
            let whiteCount = whiteIndices.count
            let whiteWidth = geo.size.width / CGFloat(whiteCount)
            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 0) {
                    ForEach(whiteIndices, id: \.self) { idx in
                        WhiteKey(pitch: pitches[idx])
                            .frame(width: whiteWidth)
                    }
                }
                // Black keys
                ForEach(blackIndices, id: \.self) { idx in
                    let position = blackKeyOffset(at: idx, whiteWidth: whiteWidth)
                    BlackKey(pitch: pitches[idx])
                        .frame(width: whiteWidth * 0.6, height: geo.size.height * 0.6)
                        .offset(x: position - whiteWidth * 0.3)
                }
            }
        }
    }

    /// Compute pixel x for a black key, based on the preceding white keys.
    private func blackKeyOffset(at idx: Int, whiteWidth: CGFloat) -> CGFloat {
        let whitesBefore = pitches.prefix(idx).filter { !$0.isBlack }.count
        return CGFloat(whitesBefore) * whiteWidth
    }
}

struct WhiteKey: View {
    let pitch: NotePitch
    @EnvironmentObject var app: AppState
    @State private var held = false

    var body: some View {
        let isHeld = app.heldNotes.contains(pitch)
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(isHeld ? app.theme.accentSoft : app.theme.surface)
                .overlay(Rectangle().stroke(app.theme.border, lineWidth: 0.5))
            Text(pitch.label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)
                .padding(.bottom, 6)
        }
        .gesture(touch)
    }

    private var touch: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !held {
                    held = true
                    app.noteOn(pitch: pitch)
                    Haptics.light()
                }
            }
            .onEnded { _ in
                held = false
                app.noteOff(pitch: pitch)
            }
    }
}

struct BlackKey: View {
    let pitch: NotePitch
    @EnvironmentObject var app: AppState
    @State private var held = false

    var body: some View {
        let isHeld = app.heldNotes.contains(pitch)
        Rectangle()
            .fill(isHeld ? app.theme.accent : app.theme.text)
            .overlay(
                Text(pitch.label)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 6),
                alignment: .bottom
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !held {
                            held = true
                            app.noteOn(pitch: pitch)
                            Haptics.light()
                        }
                    }
                    .onEnded { _ in
                        held = false
                        app.noteOff(pitch: pitch)
                    }
            )
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
