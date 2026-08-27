import SwiftUI

@main
struct TempoApp: App {
    @StateObject private var model = AppModel()
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode = AppearanceMode.system

    var body: some Scene {
        WindowGroup("Tempo", id: "main") {
            ContentView(model: model, appearanceMode: $appearanceMode)
                .onChange(of: model.phase) { oldPhase, newPhase in
                    if AppChromePolicy.shouldMinimize(from: oldPhase, to: newPhase) {
                        AppWindowController.shared.minimizeMainWindow()
                    }
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        MenuBarExtra {
            MenuBarControlView(model: model, appearanceMode: $appearanceMode)
                .preferredColorScheme(appearanceMode.colorScheme)
        } label: {
            Image(systemName: AppChromePolicy.presentation(
                for: model.phase,
                frameCount: model.frameCount,
                recordingDuration: model.recordingDuration()
            ).systemImage)
            .accessibilityLabel("Tempo")
        }
        .menuBarExtraStyle(.menu)
    }
}
