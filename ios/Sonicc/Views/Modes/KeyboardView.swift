import SwiftUI

/// The Keys mode performance surface.
///
/// Layout (top to bottom):
///   • Performance bar — scale picker, sustain toggle, pitch-bend wheel,
///     octave stepper, held-chord readout
///   • Chord recognition panel — big serif chord name when notes are held
///   • Piano keyboard — velocity-sensitive, scale-tinted, middle-C anchored
///
/// All controls hit the Apple 44pt minimum and carry VoiceOver labels.
struct KeyboardView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showScalePicker = false

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 700
            // Keyboard expands greedily; ChordReadout takes a fixed small
            // slice so the middle doesn't read as empty.
            VStack(spacing: DS.Space.sm) {
                performanceBar(isWide: isWide)
                    .padding(.horizontal, DS.Space.lg)
                    .padding(.top, DS.Space.md)
                ChordReadout()
                    .frame(height: isWide ? 110 : 96)
                    .padding(.horizontal, DS.Space.lg)
                keyboard(width: geo.size.width)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, DS.Space.md)
                    .padding(.bottom, DS.Space.md)
            }
        }
        .sheet(isPresented: $showScalePicker) {
            ScalePickerSheet(selection: $app.scaleSelection)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Performance bar

    private func performanceBar(isWide: Bool) -> some View {
        HStack(spacing: DS.Space.sm) {
            scaleChip(showLabel: isWide)
            sustainToggle(showLabel: isWide)
            if isWide {
                PitchBendWheel()
                    .frame(maxWidth: 280, maxHeight: 48)
            }
            Spacer(minLength: 0)
            octaveStepper
            Menu {
                Toggle("Velocity sensitivity",
                       isOn: Binding(
                        get: { app.velocitySensitive },
                        set: { app.velocitySensitive = $0; Haptics.select() }
                       ))
                Toggle("Sustain", isOn: Binding(
                    get: { app.sustainHeld },
                    set: { app.setSustain($0) }
                ))
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
                    .foregroundStyle(app.theme.semantic.inkSoft)
                    .frame(width: DS.minTarget, height: DS.minTarget)
                    .contentShape(Circle())
            }
            .a11y("More options")
        }
        .frame(minHeight: DS.minTarget)
    }

    private func scaleChip(showLabel: Bool) -> some View {
        let isActive = app.scaleSelection.scale.id != "chromatic"
        return Button {
            Haptics.select()
            showScalePicker = true
        } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: "waveform.path")
                    .imageScale(.small)
                if showLabel {
                    Text(isActive ? app.scaleSelection.displayName : "Scale")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .font(DS.font(.label, weight: .medium))
            .foregroundStyle(isActive ? app.theme.semantic.accent : app.theme.semantic.inkSoft)
            .padding(.horizontal, showLabel ? DS.Space.md : 0)
            .frame(minWidth: DS.minTarget, minHeight: DS.minTarget)
            .background(Capsule().fill(isActive ? app.theme.semantic.accentSoft : app.theme.semantic.surface))
            .overlay(Capsule().stroke(isActive ? app.theme.semantic.accent : app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y("Scale", value: app.scaleSelection.displayName,
              hint: "Pick a key and scale to softly tint in-scale notes on the keyboard.")
    }

    private func sustainToggle(showLabel: Bool) -> some View {
        Button {
            app.setSustain(!app.sustainHeld)
            Haptics.tap(.medium)
        } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: app.sustainHeld ? "pedal.brake.fill" : "pedal.brake")
                    .imageScale(.small)
                if showLabel {
                    Text("Sustain")
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .font(DS.font(.label, weight: .medium))
            .foregroundStyle(app.sustainHeld ? app.theme.semantic.accent : app.theme.semantic.inkSoft)
            .padding(.horizontal, showLabel ? DS.Space.md : 0)
            .frame(minWidth: DS.minTarget, minHeight: DS.minTarget)
            .background(Capsule().fill(app.sustainHeld ? app.theme.semantic.accentSoft : app.theme.semantic.surface))
            .overlay(Capsule().stroke(app.sustainHeld ? app.theme.semantic.accent : app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y("Sustain", value: app.sustainHeld ? "on" : "off",
              hint: "Held notes ring out even after you lift your finger.")
    }

    private var octaveStepper: some View {
        HStack(spacing: DS.Space.sm) {
            Text("OCT")
                .font(DS.font(.micro, weight: .semibold, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
                .accessibilityHidden(true)
            stepperButton(systemName: "minus") {
                guard app.baseOctave > 0 else { return }
                app.baseOctave -= 1
                Haptics.select()
            }
            .a11y("Octave down", value: "\(app.baseOctave)")
            Text("\(app.baseOctave)")
                .font(DS.font(.body, weight: .semibold, monospaced: true))
                .frame(minWidth: 24)
                .accessibilityHidden(true)
            stepperButton(systemName: "plus") {
                guard app.baseOctave < 7 else { return }
                app.baseOctave += 1
                Haptics.select()
            }
            .a11y("Octave up", value: "\(app.baseOctave)")
        }
        .padding(.horizontal, DS.Space.sm)
        .padding(.vertical, DS.Space.xs)
        .background(Capsule().fill(app.theme.semantic.surface))
        .overlay(Capsule().stroke(app.theme.semantic.hairline))
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundStyle(app.theme.semantic.ink)
                .frame(width: DS.minTarget, height: DS.minTarget)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Keyboard

    private func keyboard(width: CGFloat) -> some View {
        let octaves = octaveCount(width: width)
        let pitches = makePitches(baseOctave: app.baseOctave, octaves: octaves)
        return MultiTouchKeyboard(
            pitches: pitches,
            theme: app.theme,
            heldNotes: app.heldNotes,
            sustainedNotes: app.sustainedNotes,
            scaleSelection: app.scaleSelection,
            velocitySensitive: app.velocitySensitive,
            onNoteOn: { app.noteOn(pitch: $0, velocity: $1) },
            onNoteOff: { app.noteOff(pitch: $0) }
        )
    }

    private func octaveCount(width: CGFloat) -> Int {
        // Target ~32pt per white key on iPad, ~46pt on iPhone. Cap at 5
        // octaves so individual keys stay chordable under the average
        // finger.
        let target: CGFloat = width > 700 ? 32 : 46
        return Int(max(1, min(5, floor((width - 24) / (target * 7)))))
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

// MARK: - Pitch-bend wheel

/// Center-snap pitch bend bar that reads as an actual control. Drag left
/// for ±2 semitones down, right for ±2 semitones up. Snaps back on release.
struct PitchBendWheel: View {
    @EnvironmentObject var app: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let centerTick = geo.size.width / 2
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(app.theme.semantic.surface)
                    .overlay(Capsule().stroke(app.theme.semantic.hairline))

                // center tick
                Rectangle()
                    .fill(app.theme.semantic.inkMuted.opacity(0.4))
                    .frame(width: 1, height: 12)
                    .offset(x: centerTick - 0.5, y: (geo.size.height - 12) / 2)

                // value bar from center → handle
                Capsule()
                    .fill(app.theme.semantic.accent.opacity(0.20))
                    .frame(width: abs(CGFloat(app.pitchBend)) * (geo.size.width / 2),
                           height: geo.size.height - 8)
                    .offset(x: app.pitchBend >= 0
                            ? centerTick
                            : centerTick - abs(CGFloat(app.pitchBend)) * (geo.size.width / 2),
                            y: 4)
                    .animation(reduceMotion ? .linear(duration: 0.001) : .easeOut(duration: 0.06),
                               value: app.pitchBend)

                // handle
                Circle()
                    .fill(app.theme.semantic.accent)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    .offset(x: CGFloat(app.pitchBend) * (geo.size.width / 2) + centerTick - 13,
                            y: (geo.size.height - 26) / 2)

                // label
                Text("BEND")
                    .font(DS.font(.micro, weight: .semibold, monospaced: true))
                    .tracking(1)
                    .foregroundStyle(app.theme.semantic.inkMuted)
                    .padding(.leading, DS.Space.sm)
                    .accessibilityHidden(true)
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let mid = geo.size.width / 2
                        let v = Double((g.location.x - mid) / mid)
                        app.setPitchBend(max(-1, min(1, v)))
                    }
                    .onEnded { _ in
                        withAnimation(DS.spring(reduceMotion: reduceMotion)) {
                            app.setPitchBend(0)
                        }
                        Haptics.tap(.soft)
                    }
            )
        }
        .frame(height: DS.minTarget)
        .a11y("Pitch bend",
              value: "\(Int(app.pitchBend * 200)) cents",
              hint: "Drag left for pitch down, right for pitch up. Releases to neutral.")
    }
}

// MARK: - Scale picker sheet

struct ScalePickerSheet: View {
    @EnvironmentObject var app: AppState
    @Binding var selection: ScaleSelection
    @Environment(\.dismiss) private var dismiss

    private let rootNames = ["C", "C♯", "D", "E♭", "E", "F", "F♯", "G", "A♭", "A", "B♭", "B"]
    private let rootColumns = Array(repeating: GridItem(.flexible(), spacing: DS.Space.sm), count: 6)
    private let scaleColumns = Array(repeating: GridItem(.flexible(), spacing: DS.Space.sm), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    section("Root note") {
                        LazyVGrid(columns: rootColumns, spacing: DS.Space.sm) {
                            ForEach(0..<12, id: \.self) { idx in
                                rootButton(idx)
                            }
                        }
                    }
                    section("Scale") {
                        LazyVGrid(columns: scaleColumns, spacing: DS.Space.sm) {
                            ForEach(Scale.all) { s in
                                scaleButton(s)
                            }
                        }
                    }
                    Text("In-scale notes are softly tinted on the keyboard so you can hear yourself stay in key. Pick \"Chromatic\" to turn the highlight off.")
                        .font(DS.font(.caption))
                        .foregroundStyle(app.theme.semantic.inkSoft)
                        .padding(.top, DS.Space.sm)
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle("Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func rootButton(_ idx: Int) -> some View {
        let isOn = selection.root == idx
        return Button {
            selection.root = idx
            Haptics.select()
        } label: {
            Text(rootNames[idx])
                .font(DS.font(.body, weight: isOn ? .semibold : .regular, monospaced: true))
                .foregroundStyle(isOn ? Color.white : app.theme.semantic.ink)
                .frame(maxWidth: .infinity, minHeight: DS.minTarget)
                .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .fill(isOn ? app.theme.semantic.accent : app.theme.semantic.surface))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .stroke(app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y("Root \(rootNames[idx])", value: isOn ? "selected" : "")
    }

    private func scaleButton(_ s: Scale) -> some View {
        let isOn = selection.scale == s
        return Button {
            selection.scale = s
            Haptics.select()
        } label: {
            Text(s.displayName)
                .font(DS.font(.label, weight: isOn ? .semibold : .regular))
                .foregroundStyle(isOn ? Color.white : app.theme.semantic.ink)
                .frame(maxWidth: .infinity, minHeight: DS.minTarget)
                .background(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .fill(isOn ? app.theme.semantic.accent : app.theme.semantic.surface))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .stroke(app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y("Scale \(s.displayName)", value: isOn ? "selected" : "")
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(title.uppercased())
                .font(DS.font(.caption, weight: .semibold, monospaced: true))
                .tracking(1.4)
                .foregroundStyle(app.theme.semantic.inkSoft)
            content()
        }
    }
}
