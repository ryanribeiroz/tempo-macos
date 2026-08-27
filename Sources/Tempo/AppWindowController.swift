import AppKit

@MainActor
final class AppWindowController {
    static let shared = AppWindowController()

    private init() {}

    func minimizeMainWindow() {
        guard let window = NSApplication.shared.keyWindow ?? mainWindow else { return }
        window.miniaturize(nil)
    }

    func showMainWindow() {
        let application = NSApplication.shared
        application.activate(ignoringOtherApps: true)
        guard let window = mainWindow else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
    }

    private var mainWindow: NSWindow? {
        NSApplication.shared.windows.first {
            !($0 is NSPanel) && $0.canBecomeMain && ($0.isVisible || $0.isMiniaturized)
        }
    }
}
