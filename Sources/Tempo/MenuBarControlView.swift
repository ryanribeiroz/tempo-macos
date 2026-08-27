import AppKit
import SwiftUI

struct MenuBarControlView: View {
    @ObservedObject var model: AppModel
    @Binding var appearanceMode: AppearanceMode
    @Environment(\.openWindow) private var openWindow

    private func presentation(at date: Date = Date()) -> MenuBarPresentation {
        AppChromePolicy.presentation(
            for: model.phase,
            frameCount: model.frameCount,
            recordingDuration: model.recordingDuration(at: date)
        )
    }

    private var actions: [MenuBarAction] {
        AppChromePolicy.actions(
            for: model.phase,
            canExport: model.canExport,
            canResume: model.canResume
        )
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(presentation(at: context.date).status)
                .monospacedDigit()
        }
        if model.isRecording || model.isPaused {
            Text("\(model.frameCount) \(model.frameCount == 1 ? "quadro salvo" : "quadros salvos")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        Divider()

        ForEach(actions.filter { $0 != .open && $0 != .quit }, id: \.self) { action in
            Button {
                perform(action)
            } label: {
                Label(action.title, systemImage: action.systemImage)
            }
        }

        if actions.count > 2 {
            Divider()
        }

        Menu("Aparência") {
            Picker("Aparência", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
        }

        Button {
            perform(.open)
        } label: {
            Label(MenuBarAction.open.title, systemImage: MenuBarAction.open.systemImage)
        }

        Divider()

        Button {
            perform(.quit)
        } label: {
            Label(MenuBarAction.quit.title, systemImage: MenuBarAction.quit.systemImage)
        }
    }

    private func perform(_ action: MenuBarAction) {
        switch action {
        case .open:
            showMainWindow()
        case .start:
            model.start()
        case .pause:
            model.pauseManually()
        case .resume:
            model.resumeRecording()
        case .stopAndExport:
            showMainWindow()
            Task { @MainActor in
                await Task.yield()
                model.stopAndExport()
            }
        case .cancel:
            model.cancelRecording()
        case .quit:
            NSApplication.shared.terminate(nil)
        }
    }

    private func showMainWindow() {
        openWindow(id: "main")
        AppWindowController.shared.showMainWindow()
        DispatchQueue.main.async {
            AppWindowController.shared.showMainWindow()
        }
    }
}
