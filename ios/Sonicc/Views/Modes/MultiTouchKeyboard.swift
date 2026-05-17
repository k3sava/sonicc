import SwiftUI
import UIKit

/// SwiftUI wrapper for a UIKit-backed multi-touch keyboard. The native
/// `DragGesture` setup per key only tracks one touch at a time, which
/// breaks chords on iPad. This view captures every UITouch and routes it
/// to the right pitch, so a user can hold a triad with three fingers and
/// still glissando with a fourth.
struct MultiTouchKeyboard: UIViewRepresentable {
    let pitches: [NotePitch]
    let theme: AppTheme
    let heldNotes: Set<NotePitch>
    let onNoteOn: (NotePitch) -> Void
    let onNoteOff: (NotePitch) -> Void

    func makeUIView(context: Context) -> MultiTouchKeyboardUIView {
        let v = MultiTouchKeyboardUIView()
        v.onNoteOn = onNoteOn
        v.onNoteOff = onNoteOff
        return v
    }

    func updateUIView(_ uiView: MultiTouchKeyboardUIView, context: Context) {
        uiView.configure(pitches: pitches, theme: theme, externalHeld: heldNotes)
    }
}

final class MultiTouchKeyboardUIView: UIView {
    var onNoteOn: ((NotePitch) -> Void)?
    var onNoteOff: ((NotePitch) -> Void)?

    private var pitches: [NotePitch] = []
    private var whitePitches: [NotePitch] = []
    private var blackPitches: [NotePitch] = []
    private var theme: AppTheme = .default
    private var externalHeld: Set<NotePitch> = []

    // Per-touch state so multiple fingers can hold independent notes.
    private var touchPitch: [ObjectIdentifier: NotePitch] = [:]
    private var heldByTouch: Set<NotePitch> = []

    // Hit-test geometry, recomputed in layoutSubviews.
    private var whiteRects: [(NotePitch, CGRect)] = []
    private var blackRects: [(NotePitch, CGRect)] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(pitches: [NotePitch], theme: AppTheme, externalHeld: Set<NotePitch>) {
        let needsReset = pitches.map(\.id) != self.pitches.map(\.id)
        self.pitches = pitches
        self.theme = theme
        self.externalHeld = externalHeld
        if needsReset {
            whitePitches = pitches.filter { !$0.isBlack }
            blackPitches = pitches.filter { $0.isBlack }
            setNeedsLayout()
        }
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !whitePitches.isEmpty else {
            whiteRects = []
            blackRects = []
            return
        }
        let whiteWidth = bounds.width / CGFloat(whitePitches.count)
        let height = bounds.height
        whiteRects = whitePitches.enumerated().map { idx, pitch in
            (pitch, CGRect(x: CGFloat(idx) * whiteWidth, y: 0, width: whiteWidth, height: height))
        }
        // Position black keys at the right edge of their preceding white key.
        let blackWidth = whiteWidth * 0.6
        let blackHeight = height * 0.6
        blackRects = blackPitches.compactMap { black in
            guard let priorWhiteIdx = priorWhiteIndex(for: black) else { return nil }
            let x = CGFloat(priorWhiteIdx + 1) * whiteWidth - blackWidth / 2
            return (black, CGRect(x: x, y: 0, width: blackWidth, height: blackHeight))
        }
    }

    private func priorWhiteIndex(for black: NotePitch) -> Int? {
        // The black key sits between the previous white key and the next.
        // Find the last white key whose pitch is just below `black`.
        let blackMidi = black.midi
        for (i, w) in whitePitches.enumerated().reversed() where w.midi < blackMidi {
            return i
        }
        return nil
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let pressed = heldByTouch.union(externalHeld)

        // White keys
        for (pitch, r) in whiteRects {
            let fill = pressed.contains(pitch) ? theme.accentSoft : theme.surface
            ctx.setFillColor(UIColor(fill).cgColor)
            ctx.fill(r)
            ctx.setStrokeColor(UIColor(theme.border).cgColor)
            ctx.setLineWidth(0.5)
            ctx.stroke(r)
            let label = pitch.label as NSString
            label.draw(
                at: CGPoint(x: r.midX - 8, y: r.maxY - 14),
                withAttributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular),
                    .foregroundColor: UIColor(theme.textMuted),
                ]
            )
        }
        // Black keys (drawn on top)
        for (pitch, r) in blackRects {
            let fill = pressed.contains(pitch) ? theme.accent : theme.text
            ctx.setFillColor(UIColor(fill).cgColor)
            ctx.fill(r)
        }
    }

    // MARK: Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { handleTouchDown(t) }
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let id = ObjectIdentifier(t)
            let prev = touchPitch[id]
            let now = pitch(at: t.location(in: self))
            if prev?.id != now?.id {
                // Clear the mapping before release() so its
                // "still held by another touch?" check is accurate.
                touchPitch[id] = nil
                if let prev { release(prev) }
                if let now { press(now, for: id) }
            }
        }
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { handleTouchUp(t) }
        setNeedsDisplay()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { handleTouchUp(t) }
        setNeedsDisplay()
    }

    private func handleTouchDown(_ t: UITouch) {
        if let pitch = pitch(at: t.location(in: self)) {
            press(pitch, for: ObjectIdentifier(t))
        }
    }

    private func handleTouchUp(_ t: UITouch) {
        let id = ObjectIdentifier(t)
        if let pitch = touchPitch.removeValue(forKey: id) {
            release(pitch)
        }
    }

    private func press(_ pitch: NotePitch, for touch: ObjectIdentifier) {
        touchPitch[touch] = pitch
        if heldByTouch.insert(pitch).inserted {
            onNoteOn?(pitch)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func release(_ pitch: NotePitch) {
        // Only release if no other active touch still holds this pitch.
        let stillHeld = touchPitch.values.contains(where: { $0.id == pitch.id })
        if !stillHeld {
            heldByTouch.remove(pitch)
            onNoteOff?(pitch)
        }
    }

    private func pitch(at point: CGPoint) -> NotePitch? {
        // Black keys take precedence in their narrower zone.
        for (pitch, rect) in blackRects where rect.contains(point) { return pitch }
        for (pitch, rect) in whiteRects where rect.contains(point) { return pitch }
        return nil
    }
}
