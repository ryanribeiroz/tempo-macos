import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "TempoAppearanceMode"

    var id: Self { self }

    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Escuro"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum MenuBarAction: Hashable {
    case open
    case start
    case pause
    case resume
    case stopAndExport
    case cancel
    case quit

    var title: String {
        switch self {
        case .open: return "Abrir Tempo"
        case .start: return "Iniciar gravação"
        case .pause: return "Pausar gravação"
        case .resume: return "Continuar gravação"
        case .stopAndExport: return "Parar e criar vídeo"
        case .cancel: return "Cancelar gravação"
        case .quit: return "Sair do Tempo"
        }
    }

    var systemImage: String {
        switch self {
        case .open: return "macwindow"
        case .start: return "record.circle"
        case .pause: return "pause.fill"
        case .resume: return "play.fill"
        case .stopAndExport: return "stop.fill"
        case .cancel: return "xmark"
        case .quit: return "power"
        }
    }
}

struct MenuBarPresentation: Equatable {
    let status: String
    let systemImage: String
}

enum AppChromePolicy {
    static func shouldMinimize(from oldPhase: AppPhase, to newPhase: AppPhase) -> Bool {
        oldPhase == .requestingPermission && newPhase == .recording
    }

    static func presentation(
        for phase: AppPhase,
        frameCount: Int,
        recordingDuration: TimeInterval = 0
    ) -> MenuBarPresentation {
        switch phase {
        case .idle:
            return MenuBarPresentation(status: "Pronto para gravar", systemImage: "clock.arrow.circlepath")
        case .requestingPermission:
            return MenuBarPresentation(status: "Preparando captura…", systemImage: "ellipsis.circle")
        case .recording:
            return MenuBarPresentation(
                status: "Gravando • \(formattedDuration(recordingDuration))",
                systemImage: "record.circle.fill"
            )
        case .paused:
            return MenuBarPresentation(
                status: "Pausada • \(formattedDuration(recordingDuration))",
                systemImage: "pause.circle.fill"
            )
        case .exporting:
            return MenuBarPresentation(status: "Criando vídeo…", systemImage: "film.stack")
        case .finished:
            return MenuBarPresentation(status: "Vídeo criado", systemImage: "checkmark.circle.fill")
        case .failed:
            return MenuBarPresentation(status: "Ação necessária", systemImage: "exclamationmark.triangle.fill")
        }
    }

    static func formattedDuration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds / 60) % 60, seconds % 60)
    }

    static func actions(
        for phase: AppPhase,
        canExport: Bool,
        canResume: Bool
    ) -> [MenuBarAction] {
        var actions: [MenuBarAction] = [.open]
        switch phase {
        case .idle, .finished, .failed:
            actions.append(.start)
        case .requestingPermission, .exporting:
            break
        case .recording:
            actions.append(.pause)
            actions.append(canExport ? .stopAndExport : .cancel)
        case .paused:
            if canResume { actions.append(.resume) }
            actions.append(canExport ? .stopAndExport : .cancel)
        }
        actions.append(.quit)
        return actions
    }
}
