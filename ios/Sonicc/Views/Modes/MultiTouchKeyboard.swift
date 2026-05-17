import SwiftUI
import UIKit

/// Multi-touch piano keyboard backed by a UIView. Highlights:
///   - Velocity from touch y-position (top of key = soft, bottom = forte)
///   - Scale-tinted background on in-scale white keys
///   - Middle-C anchor mark so the player can orient instantly
///   - Real key depth: top highlight on white keys, shadow under black keys
///   - Chord-aware highlight color when pressed
struct MultiTouchKeyboard: UIViewRepresentable {
    let pitches: [NotePitch]
    let theme: AppTheme
    let heldNotes: Set<NotePitch>
    let sustainedNotes: Set<NotePitch>
    let scaleSelection: ScaleSelection
    let velocitySensitive: Bool
    let onNoteOn: (NotePitch, Double) -> Void
    let onNoteOff: (NotePitch) -> Void

    func makeUIView(context: Context) -> MultiTouchKeyboardUIView {
        let v = MultiTouchKeyboardUIView()
        v.onNoteOn = onNoteOn
        v.onNoteOff = onNoteOff
        return v
    }

    func updateUIView(_ uiView: MultiTouchKeyboardUIView, context: Context) {
        uiView.onNoteOn = onNoteOn
        uiView.onNoteOff = onNoteOff
        uiView.configure(
            pitches: pitches,
            theme: theme,
            externalHeld: heldNotes,
            sustained: sustainedNotes,
            scaleSelection: scaleSelection,
            velocitySensitive: velocitySensitive
        )
    }
}

final class MultiTouchKeyboardUIView: UIView {
    var onNoteOn: ((NotePitch, Double) -> Void)?
    var onNoteOff: ((NotePitch) -> Void)?

    private var pitches: [NotePitch] = []
    private var whitePitches: [NotePitch] = []
    private var blackPitches: [NotePitch] = []
    private var theme: AppTheme = .default
    private var externalHeld: Set<NotePitch> = []
    private var sustained: Set<NotePitch> = []
    private var scaleSelection: ScaleSelection = .none
    private var velocitySensitive: Bool = true

    private var touchPitch: [ObjectIdentifier: NotePitch] = [:]
    private var heldByTouch: Set<NotePitch> = []

    private var whiteRects: [(NotePitch, CGRect)] = []
    private var blackRects: [(NotePitch, CGRect)] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        contentMode = .redraw
        accessibilityLabel = "Piano keyboard"
        accessibilityHint = "Drag a finger up and down on a key for velocity, hold multiple fingers for chords."
        accessibilityTraits = .allowsDirectInteraction
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(pitches: [NotePitch],
                   theme: AppTheme,
                   externalHeld: Set<NotePitch>,
                   sustained: Set<NotePitch>,
                   scaleSelection: ScaleSelection,
                   velocitySensitive: Bool) {
        let needsReset = pitches.map(\.id) != self.pitches.map(\.id)
        self.pitches = pitches
        self.theme = theme
        self.externalHeld = externalHeld
        self.sustained = sustained
        self.scaleSelection = scaleSelection
        self.velocitySensitive = velocitySensitive
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
        let blackWidth = whiteWidth * 0.62
        let blackHeight = height * 0.62
        blackRects = blackPitches.compactMap { black in
            guard let priorWhiteIdx = priorWhiteIndex(for: black) else { return nil }
            let x = CGFloat(priorWhiteIdx + 1) * whiteWidth - blackWidth / 2
            return (black, CGRect(x: x, y: 0, width: blackWidth, height: blackHeight))
        }
    }

    private func priorWhiteIndex(for black: NotePitch) -> Int? {
        let blackMidi = black.midi
        for (i, w) in whitePitches.enumerated().reversed() where w.midi < blackMidi {
            return i
        }
        return nil
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let sem = theme.semantic
        let pressed = heldByTouch.union(externalHeld)
        let ringing = sustained.subtracting(pressed)

        // Outer frame so the instrument reads as a single object
        ctx.setStrokeColor(UIColor(sem.ink).cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(bounds.insetBy(dx: 0.75, dy: 0.75))

        // White keys
        for (pitch, r) in whiteRects {
            drawWhiteKey(pitch: pitch, rect: r, ctx: ctx, sem: sem,
                         isPressed: pressed.contains(pitch),
                         isRinging: ringing.contains(pitch))
        }

        // Black keys (on top)
        for (pitch, r) in blackRects {
            drawBlackKey(pitch: pitch, rect: r, ctx: ctx, sem: sem,
                         isPressed: pressed.contains(pitch),
                         isRinging: ringing.contains(pitch))
        }
    }

    private func drawWhiteKey(pitch: NotePitch, rect r: CGRect,
                              ctx: CGContext, sem: Semantic,
                              isPressed: Bool, isRinging: Bool) {
        // Base fill
        let baseFill: UIColor
        if isPressed { baseFill = UIColor(sem.keyHighlight) }
        else if isRinging { baseFill = UIColor(sem.accentSoft) }
        else if isMiddleC(pitch) { baseFill = UIColor(sem.keyAnchor.opacity(0.10)) }
        else if scaleSelection.scale.id != "chromatic" && scaleSelection.contains(pitchClass: pitch.note) {
            baseFill = UIColor(sem.keyInScale)
        } else { baseFill = UIColor(sem.keyWhite) }

        ctx.setFillColor(baseFill.cgColor)
        ctx.fill(r)

        // Top highlight stripe — gives a sense of a beveled key
        let topGradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                UIColor.white.withAlphaComponent(0.65).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor,
            ] as CFArray,
            locations: [0, 1]
        )
        if let g = topGradient {
            ctx.saveGState()
            ctx.clip(to: r)
            ctx.drawLinearGradient(g, start: CGPoint(x: r.midX, y: r.minY),
                                       end: CGPoint(x: r.midX, y: r.minY + 12),
                                       options: [])
            ctx.restoreGState()
        }

        // Right-edge separator
        ctx.setStrokeColor(UIColor(sem.ink).cgColor)
        ctx.setLineWidth(1)
        ctx.move(to: CGPoint(x: r.maxX, y: r.minY))
        ctx.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        ctx.strokePath()

        // Middle-C anchor mark (small accent dot below the label)
        if isMiddleC(pitch) {
            let dot = CGRect(x: r.midX - 4, y: r.maxY - 26, width: 8, height: 8)
            ctx.setFillColor(UIColor(sem.accent).cgColor)
            ctx.fillEllipse(in: dot)
        }

        // Note label
        let label = pitch.label as NSString
        label.draw(
            at: CGPoint(x: r.midX - 8, y: r.maxY - 16),
            withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor(isPressed ? sem.ink : sem.inkMuted),
            ]
        )
    }

    private func drawBlackKey(pitch: NotePitch, rect r: CGRect,
                              ctx: CGContext, sem: Semantic,
                              isPressed: Bool, isRinging: Bool) {
        let fill: UIColor
        if isPressed { fill = UIColor(sem.accent) }
        else if isRinging { fill = UIColor(sem.accent.opacity(0.65)) }
        else { fill = UIColor(sem.keyBlack) }

        // Drop shadow underneath the black key
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: 1.5),
                      blur: 3,
                      color: UIColor.black.withAlphaComponent(0.20).cgColor)
        let path = UIBezierPath(roundedRect: r, cornerRadius: 2).cgPath
        ctx.addPath(path)
        ctx.setFillColor(fill.cgColor)
        ctx.fillPath()
        ctx.restoreGState()

        // Top gloss
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                UIColor.white.withAlphaComponent(0.28).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor,
            ] as CFArray,
            locations: [0, 1]
        )
        if let g = gradient {
            ctx.saveGState()
            ctx.clip(to: r)
            ctx.drawLinearGradient(g, start: CGPoint(x: r.midX, y: r.minY),
                                       end: CGPoint(x: r.midX, y: r.minY + 10),
                                       options: [])
            ctx.restoreGState()
        }

        // In-scale subtle marker for tinted black keys
        if scaleSelection.scale.id != "chromatic"
            && scaleSelection.contains(pitchClass: pitch.note) {
            let bar = CGRect(x: r.minX + 2, y: r.maxY - 4,
                             width: r.width - 4, height: 2)
            ctx.setFillColor(UIColor(sem.accent).withAlphaComponent(0.8).cgColor)
            ctx.fill(bar)
        }
    }

    private func isMiddleC(_ p: NotePitch) -> Bool {
        p.note == 0 && p.octave == 4
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
                touchPitch[id] = nil
                if let prev { release(prev) }
                if let now { press(now, for: id, touch: t) }
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
            press(pitch, for: ObjectIdentifier(t), touch: t)
        }
    }

    private func handleTouchUp(_ t: UITouch) {
        let id = ObjectIdentifier(t)
        if let pitch = touchPitch.removeValue(forKey: id) {
            release(pitch)
        }
    }

    private func press(_ pitch: NotePitch, for touch: ObjectIdentifier, touch t: UITouch) {
        touchPitch[touch] = pitch
        if heldByTouch.insert(pitch).inserted {
            let v = velocity(for: t, pitch: pitch)
            onNoteOn?(pitch, v)
            Haptics.tap(.light)
        }
    }

    private func release(_ pitch: NotePitch) {
        let stillHeld = touchPitch.values.contains(where: { $0.id == pitch.id })
        if !stillHeld {
            heldByTouch.remove(pitch)
            onNoteOff?(pitch)
        }
    }

    /// Derive velocity from touch y-position. Soft at the top of the key,
    /// forte at the bottom. Honor 3D Touch / Apple Pencil force if present.
    private func velocity(for touch: UITouch, pitch: NotePitch) -> Double {
        if !velocitySensitive { return 1.0 }
        // Force-touch path
        if touch.maximumPossibleForce > 0, touch.force > 0 {
            return max(0.25, min(1.0, Double(touch.force / touch.maximumPossibleForce)))
        }
        // y-position path
        let p = touch.location(in: self)
        let rect = pitch.isBlack
            ? blackRects.first(where: { $0.0.id == pitch.id })?.1
            : whiteRects.first(where: { $0.0.id == pitch.id })?.1
        guard let r = rect else { return 0.8 }
        let normY = max(0, min(1, (p.y - r.minY) / max(1, r.height)))
        // 0.4 (top) → 1.0 (bottom). Avoids near-zero strikes that go inaudible.
        return 0.4 + 0.6 * Double(normY)
    }

    private func pitch(at point: CGPoint) -> NotePitch? {
        for (pitch, rect) in blackRects where rect.contains(point) { return pitch }
        for (pitch, rect) in whiteRects where rect.contains(point) { return pitch }
        return nil
    }
}
