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

    private var controlsBar: some View {
        HStack(spacing: DS.Space.md) {
            layerToggle
            stepSizePicker
            Spacer(minLength: 0)
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
        return GeometryReader { geo in
            let gap: CGFloat = 4
            let cellH = (geo.size.height - gap * CGFloat(rows + 1)) / CGFloat(rows)
            let fitWidth = (geo.size.width - gap * CGFloat(steps + 1)) / CGFloat(steps)
            let cellW = max(28, fitWidth)
            let size = min(cellW, max(28, cellH))
            let needsScroll = cellW > fitWidth
            let body = VStack(spacing: gap) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<steps, id: \.self) { step in
                            cell(row: row, step: step)
                                .frame(width: size, height: size)
                        }
                    }
                }
            }
            .padding(gap)
            if needsScroll {
                ScrollView(.horizontal, showsIndicators: false) { body }
            } else {
                body
            }
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
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("bounce-\(stamp).m4a")
        do {
            try app.audio.startTrackRender(to: url)
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
