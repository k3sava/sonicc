import SwiftUI

/// Step sequencer grid with layer switcher, step-count picker, save and
/// bounce controls. The grid scales to fit the available area; cells are
/// at least 32pt for comfortable tapping. The current playing step is
/// highlighted with a column glow.
struct PatternView: View {
    @EnvironmentObject var app: AppState
    @ObservedObject var sequencer: Sequencer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var library = PatternLibrary.shared
    @StateObject private var recordings = RecordingLibrary.shared
    @State private var showLibrary: Bool = false
    @State private var showSaveDialog: Bool = false
    @State private var saveName: String = ""
    @State private var isBouncing: Bool = false
    @State private var toast: ToastMessage?

    struct ToastMessage: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let kind: Kind
        enum Kind { case success, info, warning }
    }

    var body: some View {
        VStack(spacing: DS.Space.md) {
            slotsBar
            controlsBar
            stepIndicator
            grid
            if let toast {
                ToastView(message: toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(DS.Space.md)
        .animation(DS.ease(reduceMotion: reduceMotion), value: toast)
        .sheet(isPresented: $showLibrary) {
            PatternLibrarySheet(
                library: library,
                onLoad: { p in
                    sequencer.restore(p)
                    showLibrary = false
                    show(.success, "Loaded \"\(p.name)\"")
                }
            )
        }
        .alert("Save pattern", isPresented: $showSaveDialog) {
            TextField("Name", text: $saveName)
            Button("Save") {
                let name = saveName.trimmingCharacters(in: .whitespacesAndNewlines)
                let final = name.isEmpty ? "Pattern \(library.patterns.count + 1)" : name
                library.save(sequencer.snapshot(named: final))
                saveName = ""
                Haptics.notify(.success)
                show(.success, "Saved \"\(final)\"")
            }
            Button("Cancel", role: .cancel) { saveName = "" }
        } message: {
            Text("\(sequencer.stepCount.rawValue) steps · \(Int(sequencer.bpm)) BPM")
        }
    }

    // MARK: - Controls

    private var slotsBar: some View {
        HStack(spacing: DS.Space.sm) {
            ForEach(0..<4, id: \.self) { i in
                slotChip(i)
            }
            Spacer(minLength: DS.Space.sm)
            chainToggle
        }
    }

    private func slotChip(_ index: Int) -> some View {
        let isActive = sequencer.activeSlot == index
        let isEmpty = sequencer.slotIsEmpty(index)
        return Menu {
            Button {
                sequencer.saveSlot(index)
                Haptics.notify(.success)
                show(.success, "Saved into slot \(sequencer.slotLetter(index))")
            } label: {
                Label(isEmpty ? "Save current pattern here" : "Overwrite with current pattern",
                      systemImage: "square.and.arrow.down")
            }
            if !isEmpty {
                Button {
                    sequencer.loadSlot(index)
                    Haptics.tap(.medium)
                    show(.info, "Loaded slot \(sequencer.slotLetter(index))")
                } label: {
                    Label("Load this slot", systemImage: "play.fill")
                }
                Button(role: .destructive) {
                    sequencer.clearSlot(index)
                    Haptics.notify(.warning)
                    show(.warning, "Cleared slot \(sequencer.slotLetter(index))")
                } label: {
                    Label("Clear this slot", systemImage: "trash")
                }
            }
        } label: {
            VStack(spacing: 2) {
                Text(sequencer.slotLetter(index))
                    .font(DS.font(.body, weight: .semibold, monospaced: true))
                Text(isEmpty ? "empty" : "saved")
                    .font(DS.font(.micro, monospaced: true))
                    .opacity(0.7)
            }
            .frame(minWidth: 56, minHeight: DS.minTarget)
            .foregroundStyle(isActive ? Color.white : (isEmpty ? app.theme.semantic.inkMuted : app.theme.semantic.ink))
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .fill(isActive ? app.theme.semantic.accent : (isEmpty ? app.theme.semantic.surface : app.theme.semantic.accentSoft))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.chip)
                    .stroke(isActive ? app.theme.semantic.accent : app.theme.semantic.hairline)
            )
        }
        .a11y("Slot \(sequencer.slotLetter(index))",
              value: isActive ? "active" : (isEmpty ? "empty" : "saved"),
              hint: "Hold to save, load, or clear this song slot.")
    }

    private var chainToggle: some View {
        Button {
            sequencer.setChain(!sequencer.chainEnabled)
            Haptics.select()
        } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: sequencer.chainEnabled ? "link.circle.fill" : "link")
                    .imageScale(.small)
                Text("Chain")
                    .font(DS.font(.caption, weight: .semibold, monospaced: true))
            }
            .padding(.horizontal, DS.Space.md)
            .frame(minHeight: DS.minTarget)
            .foregroundStyle(sequencer.chainEnabled ? app.theme.semantic.accent : app.theme.semantic.inkSoft)
            .background(Capsule().fill(sequencer.chainEnabled ? app.theme.semantic.accentSoft : app.theme.semantic.surface))
            .overlay(Capsule().stroke(sequencer.chainEnabled ? app.theme.semantic.accent : app.theme.semantic.hairline))
        }
        .a11y("Chain mode", value: sequencer.chainEnabled ? "on" : "off",
              hint: "When on, the sequencer advances through populated slots each loop.")
    }

    private var controlsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.md) {
                layerToggle
                stepSizePicker
                subdivisionPicker
                Spacer(minLength: DS.Space.md)
                actionButton("Save", systemImage: "square.and.arrow.down") {
                    showSaveDialog = true
                    Haptics.select()
                }
                actionButton("Library", systemImage: "tray.full") {
                    showLibrary = true
                    Haptics.select()
                }
                actionButton(isBouncing ? "Bouncing…" : "Bounce",
                             systemImage: isBouncing ? "stop.circle.fill" : "waveform.path.badge.plus",
                             destructive: isBouncing,
                             action: toggleBounce)
                actionButton("Clear", systemImage: "trash") {
                    sequencer.clear()
                    Haptics.notify(.warning)
                    show(.warning, "Pattern cleared")
                }
            }
            .padding(.horizontal, DS.Space.xs)
        }
    }

    private var subdivisionPicker: some View {
        Menu {
            ForEach(Sequencer.Subdivision.allCases) { s in
                Button {
                    sequencer.subdivision = s
                    Haptics.select()
                } label: {
                    HStack {
                        Text(s.rawValue)
                        if sequencer.subdivision == s {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: "music.note").imageScale(.small)
                Text(sequencer.subdivision.rawValue)
                    .font(DS.font(.caption, weight: .semibold, monospaced: true))
                Image(systemName: "chevron.down").imageScale(.small)
            }
            .padding(.horizontal, DS.Space.md)
            .frame(minHeight: DS.minTarget)
            .background(Capsule().fill(app.theme.semantic.surface))
            .overlay(Capsule().stroke(app.theme.semantic.hairline))
            .foregroundStyle(app.theme.semantic.ink)
        }
        .a11y("Subdivision", value: sequencer.subdivision.rawValue,
              hint: "Sets rhythmic resolution. Use 1/16t for sixteenth triplets.")
    }

    private var layerToggle: some View {
        Picker("Layer", selection: $sequencer.layer) {
            Text("Synth").tag(Sequencer.Layer.synth)
            Text("Drums").tag(Sequencer.Layer.drum)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 200)
        .a11y("Layer", value: sequencer.layer == .synth ? "synth" : "drums",
              hint: "Switches which row of pads you're editing.")
    }

    private var stepSizePicker: some View {
        HStack(spacing: DS.Space.xs) {
            ForEach(Sequencer.StepSize.allCases) { s in
                Button {
                    sequencer.setStepCount(s)
                    Haptics.select()
                } label: {
                    Text(s.label)
                        .font(DS.font(.caption, weight: .semibold, monospaced: true))
                        .padding(.horizontal, DS.Space.md)
                        .frame(minHeight: DS.minTarget)
                        .background(Capsule().fill(sequencer.stepCount == s ? app.theme.semantic.accent : app.theme.semantic.surface))
                        .foregroundStyle(sequencer.stepCount == s ? Color.white : app.theme.semantic.ink)
                        .overlay(Capsule().stroke(sequencer.stepCount == s ? app.theme.semantic.accent : app.theme.semantic.hairline))
                }
                .buttonStyle(.plain)
                .a11y("\(s.rawValue) steps",
                      value: sequencer.stepCount == s ? "selected" : "")
            }
        }
    }

    private func actionButton(_ label: String, systemImage: String,
                              destructive: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: systemImage).imageScale(.small)
                Text(label)
                    .font(DS.font(.caption, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, DS.Space.md)
            .frame(minHeight: DS.minTarget)
            .foregroundStyle(destructive ? app.theme.semantic.destructive : app.theme.semantic.ink)
            .background(Capsule().fill(app.theme.semantic.surface))
            .overlay(Capsule().stroke(destructive ? app.theme.semantic.destructive : app.theme.semantic.hairline))
        }
        .buttonStyle(.plain)
        .a11y(label)
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            Text("\(sequencer.currentStep + 1)/\(sequencer.stepCount.rawValue)")
                .font(DS.font(.caption, weight: .semibold, monospaced: true))
                .foregroundStyle(sequencer.isPlaying ? app.theme.semantic.accent : app.theme.semantic.inkMuted)
            Spacer()
            Text(library.patterns.count == 0 ? "No saved patterns yet"
                                              : "\(library.patterns.count) saved")
                .font(DS.font(.micro, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
        }
        .padding(.horizontal, DS.Space.xs)
        .frame(height: 20)
    }

    // MARK: - Grid

    private var grid: some View {
        let rows = 8
        let steps = sequencer.stepCount.rawValue
        let labelWidth: CGFloat = 36
        return GeometryReader { geo in
            let gap: CGFloat = 4
            let cellH = (geo.size.height - gap * CGFloat(rows + 1)) / CGFloat(rows)
            let fitWidth = (geo.size.width - labelWidth - gap * CGFloat(steps + 1)) / CGFloat(steps)
            let cellW = max(28, fitWidth)
            let size = min(cellW, max(28, cellH))
            let needsScroll = cellW > fitWidth
            HStack(alignment: .top, spacing: gap) {
                rowLabels(rows: rows, size: size, gap: gap, width: labelWidth)
                cellsBody(rows: rows, steps: steps, size: size, gap: gap, needsScroll: needsScroll)
            }
            .padding(gap)
        }
    }

    private func rowLabels(rows: Int, size: CGFloat, gap: CGFloat, width: CGFloat) -> some View {
        VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                rowLabel(row: row)
                    .frame(width: width, height: size)
            }
        }
    }

    @ViewBuilder
    private func rowLabel(row: Int) -> some View {
        let isSynth = sequencer.layer == .synth
        let text: String = {
            if isSynth, row < sequencer.synthRowPitches.count {
                return sequencer.synthRowPitches[row].label
            }
            if !isSynth, let kind = DrumKind(rawValue: row) {
                return kind.label.uppercased()
            }
            return ""
        }()
        Menu {
            if isSynth {
                ForEach(synthPitchOptions, id: \.midi) { p in
                    Button {
                        sequencer.synthRowPitches[row] = p
                        Haptics.select()
                    } label: {
                        HStack {
                            Text(p.label)
                            if sequencer.synthRowPitches[row].id == p.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Text(text)
                .font(DS.font(.micro, weight: .semibold, monospaced: true))
                .foregroundStyle(app.theme.semantic.inkMuted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(app.theme.semantic.surface.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(app.theme.semantic.hairline)
                )
        }
        .a11y(text, hint: isSynth ? "Tap to change the pitch this row plays." : "")
    }

    private var synthPitchOptions: [NotePitch] {
        var out: [NotePitch] = []
        for octave in 2...6 {
            for n in 0..<12 {
                out.append(NotePitch(note: n, octave: octave))
            }
        }
        return out
    }

    @ViewBuilder
    private func cellsBody(rows: Int, steps: Int, size: CGFloat, gap: CGFloat, needsScroll: Bool) -> some View {
        let inner = VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<steps, id: \.self) { step in
                        cell(row: row, step: step)
                            .frame(width: size, height: size)
                    }
                }
            }
        }
        if needsScroll {
            ScrollView(.horizontal, showsIndicators: false) { inner }
        } else {
            inner
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
            Haptics.tap(.soft)
        } label: {
            RoundedRectangle(cornerRadius: 5)
                .fill(on ? app.theme.semantic.accent : (active ? app.theme.semantic.cellActive : app.theme.semantic.cellOff))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(active ? app.theme.semantic.accent : app.theme.semantic.hairline, lineWidth: active ? 2 : 1)
                )
                .shadow(color: on ? app.theme.semantic.accent.opacity(0.25) : .clear,
                        radius: on ? 4 : 0, y: 1)
        }
        .buttonStyle(.plain)
        .a11y("Step \(step + 1) row \(row + 1)",
              value: on ? "on" : "off")
    }

    // MARK: - Bounce

    private func toggleBounce() {
        if isBouncing {
            sequencer.stop()
            if let url = app.audio.stopTrackRender() {
                let stamp = Int(Date().timeIntervalSince1970)
                if let rec = recordings.adopt(from: url, name: "Bounce \(stamp)") {
                    show(.success, "Saved \"\(rec.name)\"")
                    Haptics.notify(.success)
                } else {
                    show(.warning, "Bounce failed to save")
                    Haptics.notify(.error)
                }
            }
            isBouncing = false
            return
        }
        let stamp = Int(Date().timeIntervalSince1970)
        let ext = app.preferredExportFormat.rawValue
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("bounce-\(stamp).\(ext)")
        let fmt: AudioEngine.RenderFormat = app.preferredExportFormat == .wav ? .wav : .m4a
        do {
            try app.audio.startTrackRender(to: url, format: fmt)
            sequencer.play()
            isBouncing = true
            Haptics.tap(.medium)
        } catch {
            show(.warning, "Couldn't start bounce")
            Haptics.notify(.error)
        }
    }

    private func show(_ kind: ToastMessage.Kind, _ text: String) {
        toast = ToastMessage(text: text, kind: kind)
        let token = toast?.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if toast?.id == token { toast = nil }
        }
    }
}

// MARK: - Toast

struct ToastView: View {
    @EnvironmentObject var app: AppState
    let message: PatternView.ToastMessage

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(message.text)
                .font(DS.font(.caption, weight: .medium))
                .foregroundStyle(app.theme.semantic.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, DS.Space.md)
        .padding(.vertical, DS.Space.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.chip)
                .fill(app.theme.semantic.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.chip)
                .stroke(tint.opacity(0.5))
        )
    }

    private var icon: String {
        switch message.kind {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    private var tint: Color {
        switch message.kind {
        case .success: return app.theme.semantic.success
        case .info: return app.theme.semantic.accent
        case .warning: return app.theme.semantic.warning
        }
    }
}
