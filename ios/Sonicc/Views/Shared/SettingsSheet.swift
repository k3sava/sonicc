import SwiftUI

/// In-app settings. Master volume, haptics toggle, default export format,
/// theme picker, MIDI status, and an About section. Standard iOS form
/// styling — looks at home alongside Apple's own Settings panels.
struct SettingsSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                purchaseSection
                outputSection
                inputSection
                exportSection
                appearanceSection
                accessibilitySection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(gate: app.trial, store: app.iap, allowDismiss: true)
                    .environmentObject(app)
            }
        }
    }

    private var purchaseSection: some View {
        Section {
            switch app.trial.state {
            case .trial(let days):
                Button {
                    showPaywall = true
                    Haptics.select()
                } label: {
                    HStack {
                        Image(systemName: "sparkles").foregroundStyle(app.theme.semantic.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unlock sonicc")
                                .font(DS.font(.body, weight: .semibold))
                                .foregroundStyle(app.theme.semantic.ink)
                            Text("\(days) day\(days == 1 ? "" : "s") of trial left")
                                .font(DS.font(.caption))
                                .foregroundStyle(app.theme.semantic.inkSoft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(app.theme.semantic.inkMuted)
                    }
                }
            case .expired:
                Button {
                    showPaywall = true
                    Haptics.select()
                } label: {
                    Label("Unlock sonicc", systemImage: "lock.open.fill")
                        .foregroundStyle(app.theme.semantic.accent)
                }
            case .purchased:
                Label("sonicc unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(app.theme.semantic.success)
            }
            Button {
                Task { await app.iap.restore() }
                Haptics.select()
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
            .disabled(app.iap.isPurchasing)
        }
    }

    // MARK: - Sections

    private var outputSection: some View {
        Section("Output") {
            HStack {
                Image(systemName: "speaker.wave.2.fill").foregroundStyle(app.theme.semantic.accent)
                Slider(value: $app.masterVolume, in: 0...1)
                Text("\(Int(app.masterVolume * 100))%")
                    .font(DS.font(.caption, monospaced: true))
                    .frame(width: 44, alignment: .trailing)
            }
            .a11y("Master volume", value: "\(Int(app.masterVolume * 100)) percent")
        }
    }

    private var inputSection: some View {
        Section("Input") {
            HStack {
                Image(systemName: "pianokeys").foregroundStyle(app.theme.semantic.accent)
                Toggle("Velocity sensitivity", isOn: $app.velocitySensitive)
            }
            HStack {
                Image(systemName: app.midiConnected ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(app.midiConnected ? app.theme.semantic.success : app.theme.semantic.inkMuted)
                Text("MIDI")
                Spacer()
                Text(app.midiConnected ? "Connected" : "Not connected")
                    .foregroundStyle(app.theme.semantic.inkMuted)
                    .font(DS.font(.caption, monospaced: true))
            }
        }
    }

    private var exportSection: some View {
        Section {
            Picker("Default format", selection: $app.preferredExportFormat) {
                ForEach(AppState.ExportFormat.allCases) { f in
                    Text(f.displayName).tag(f)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Recording & Export")
        } footer: {
            Text("M4A is small and great for sharing. WAV is uncompressed and friendlier to DAWs like Logic, Ableton, or GarageBand.")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { app.theme.id },
                set: { newID in
                    if let t = AppTheme.all.first(where: { $0.id == newID }) {
                        app.setTheme(t)
                        Haptics.select()
                    }
                }
            )) {
                ForEach(AppTheme.all) { t in
                    Text(t.displayName).tag(t.id)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var accessibilitySection: some View {
        Section {
            Toggle(isOn: $app.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap.fill")
            }
        } header: {
            Text("Accessibility")
        } footer: {
            Text("Sonicc also respects your system Reduce Motion and Dynamic Type settings.")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(versionString)
                    .foregroundStyle(app.theme.semantic.inkMuted)
                    .font(DS.font(.caption, monospaced: true))
            }
            Button {
                app.hasOnboarded = false
                dismiss()
            } label: {
                Label("Show welcome again", systemImage: "sparkles")
            }
            Link(destination: URL(string: "https://github.com/k3sava/sonicc")!) {
                Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        } header: {
            Text("About")
        } footer: {
            Text("Made with care. Powered by AVAudioEngine.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
