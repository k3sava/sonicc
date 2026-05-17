import SwiftUI

@main
struct SoniccApp: App {
    @StateObject private var appState = AppState()

    init() {
        AudioSessionConfigurator.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.theme.preferredColorScheme)
                .onAppear { appState.start() }
        }
    }
}
