import CoreGraphics
import Foundation

struct DisplayInfo: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let frame: CGRect
    let isBuiltIn: Bool

    var title: String { isBuiltIn ? "Tela do Mac" : "Monitor externo" }
    var resolution: String { "\(Int(frame.width)) × \(Int(frame.height))" }
}

enum OutputQuality: String, CaseIterable, Identifiable {
    case light
    case sharp

    var id: Self { self }
    var title: String { self == .light ? "Leve" : "Nítido" }
    var detail: String { self == .light ? "até 1080p" : "até 1440p" }
    var maximumSize: CGSize {
        self == .light ? CGSize(width: 1920, height: 1080) : CGSize(width: 2560, height: 1440)
    }
    var jpegQuality: CGFloat { self == .light ? 0.58 : 0.72 }
    var bitrate: Int { self == .light ? 4_000_000 : 7_000_000 }
}

enum AppPhase: Equatable {
    case idle
    case requestingPermission
    case recording
    case paused(PauseReason)
    case exporting
    case finished(URL)
    case failed(String)
}

enum PauseReason: Equatable {
    case manual
    case screensAsleep
    case systemSleep
    case sessionInactive
    case captureInterrupted

    var isAutomatic: Bool { self != .manual }

    var title: String {
        switch self {
        case .manual:
            return "Pausado por você"
        case .screensAsleep:
            return "Pausado porque as telas dormiram"
        case .systemSleep:
            return "Pausado porque o Mac entrou em repouso"
        case .sessionInactive:
            return "Pausado porque a sessão foi bloqueada"
        case .captureInterrupted:
            return "Pausado após uma interrupção da captura"
        }
    }

    var detail: String {
        switch self {
        case .manual:
            return "Seus quadros estão seguros. Continue quando estiver pronto."
        case .captureInterrupted:
            return "Seus quadros estão seguros. Você pode tentar continuar ou criar o vídeo agora."
        default:
            return "Seus quadros estão seguros. A gravação só continua com sua confirmação."
        }
    }

    var systemImage: String {
        switch self {
        case .manual:
            return "pause.fill"
        case .screensAsleep, .systemSleep:
            return "moon.zzz.fill"
        case .sessionInactive:
            return "lock.fill"
        case .captureInterrupted:
            return "exclamationmark.triangle.fill"
        }
    }
}

enum TempoError: LocalizedError {
    case noDisplays
    case permissionDenied
    case captureFailed
    case contextCreationFailed
    case imageWriteFailed
    case noFrames
    case videoSetupFailed(String)

    var errorDescription: String? {
        switch self {
        case .noDisplays:
            return "Nenhuma tela ativa foi encontrada."
        case .permissionDenied:
            return "O Tempo precisa da permissão de gravação da tela."
        case .captureFailed:
            return "Não foi possível capturar uma das telas."
        case .contextCreationFailed:
            return "Não foi possível montar a imagem das telas."
        case .imageWriteFailed:
            return "Não foi possível salvar um quadro temporário."
        case .noFrames:
            return "A gravação terminou antes do primeiro quadro."
        case .videoSetupFailed(let message):
            return "Não foi possível criar o vídeo: \(message)"
        }
    }
}
