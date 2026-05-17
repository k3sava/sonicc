import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    var body: some View {
        Group {
            if isPad {
                IPadRootView()
            } else {
                IPhoneRootView()
            }
        }
        .tint(app.theme.accent)
        .background(app.theme.bg.ignoresSafeArea())
        .keyboardShortcutLayer()
    }

    private var isPad: Bool {
        // iPad in any orientation has regular hSize. Treat regular+regular as
        // the iPad layout; everything else uses the phone shell.
        hSize == .regular && vSize == .regular
    }
}
