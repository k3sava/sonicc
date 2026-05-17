import SwiftUI

/// Top app chrome — wordmark + status indicators. Keeps to 52pt height
/// so the play surface gets every pixel below it.
struct HeaderBar: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack(spacing: DS.Space.md) {
            Text("sonicc")
                .font(.system(.title3, design: .default).weight(.semibold))
                .tracking(-0.5)
                .foregroundStyle(app.theme.semantic.ink)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            if app.midiConnected {
                Label("MIDI", systemImage: "pianokeys.inverse")
                    .font(DS.font(.micro, weight: .semibold, monospaced: true))
                    .foregroundStyle(app.theme.semantic.accent)
                    .a11y("MIDI connected")
            }
            ThemePicker()
        }
        .padding(.horizontal, DS.Space.lg)
        .frame(height: 52)
        .background(app.theme.semantic.surface)
        .overlay(Divider(), alignment: .bottom)
    }
}

struct ThemePicker: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        Menu {
            ForEach(AppTheme.all) { t in
                Button {
                    app.setTheme(t)
                    Haptics.select()
                } label: {
                    HStack {
                        Text(t.displayName)
                        if app.theme.id == t.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "paintpalette")
                .imageScale(.medium)
                .frame(width: DS.minTarget, height: DS.minTarget)
                .foregroundStyle(app.theme.semantic.ink)
                .contentShape(Rectangle())
        }
        .a11y("Theme", value: app.theme.displayName, hint: "Switches the visual palette.")
    }
}
