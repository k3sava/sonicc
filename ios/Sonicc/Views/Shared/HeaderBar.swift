import SwiftUI

struct HeaderBar: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack(spacing: 12) {
            Text("sonicc")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .tracking(-0.5)
                .foregroundStyle(app.theme.text)

            Spacer()

            Text(breadcrumb)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(app.theme.textMuted)

            Spacer()

            HStack(spacing: 8) {
                if app.midiConnected {
                    Label("MIDI", systemImage: "pianokeys.inverse")
                        .font(.caption2.monospaced())
                        .foregroundStyle(app.theme.accent)
                }
                ThemePicker()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(app.theme.surface)
        .overlay(Divider(), alignment: .bottom)
    }

    private var breadcrumb: String {
        let crumbs = ["Sonicc", app.mode.title, app.presets.preset(id: app.currentPresetID)?.displayName ?? ""]
        return crumbs.filter { !$0.isEmpty }.joined(separator: " › ")
    }
}

struct ThemePicker: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        Menu {
            ForEach(AppTheme.all) { t in
                Button(t.displayName) { app.setTheme(t) }
            }
        } label: {
            Image(systemName: "paintpalette")
                .font(.system(size: 14))
                .frame(width: 30, height: 30)
                .background(app.theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(app.theme.border))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
