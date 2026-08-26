import AppKit
import CoreGraphics
import Foundation
import OSLog
import ScreenCaptureKit

private actor CaptureFailureTracker {
    private var consecutiveFailures = 0
    private var capturedSinceLastFailure = false

    func markCapture() {
        capturedSinceLastFailure = true
    }

    func registerFailure() -> Int {
        consecutiveFailures = capturedSinceLastFailure ? 1 : consecutiveFailures + 1
        capturedSinceLastFailure = false
        return consecutiveFailures
    }
}

@MainActor
final class AppModel: ObservableObject {
    private static let logger = Logger(subsystem: "com.local.tempo", category: "capture")

    @Published var phase: AppPhase = .idle
    @Published var displays: [DisplayInfo] = []
    @Published var quality: OutputQuality = .sharp
    @Published var frameCount = 0
    @Published var captureInterval: TimeInterval = 2
    @Published var exportProgress = 0.0
    @Published var accumulatedRecordingDuration: TimeInterval = 0
    @Published var showResumePrompt = false
    @Published var lastCaptureErrorMessage: String?

    private enum SystemInterruption: Hashable {
        case screens
        case system
        case session
    }

    private var session: (any CaptureSessionProtocol)?
    private var recordingTask: Task<Void, Never>?
    private var pauseSettlingTask: Task<Void, Never>?
    private var segmentStartedAt: Date?
    private var wakePromptSent = false
    private var activeSystemInterruptions: Set<SystemInterruption> = []
    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []
    private let maximumConsecutiveCaptureFailures: Int
    private let captureRetryBaseDelayNanoseconds: UInt64

    init(
        session: (any CaptureSessionProtocol)? = nil,
        maximumConsecutiveCaptureFailures: Int = 5,
        captureRetryBaseDelayNanoseconds: UInt64 = 500_000_000
    ) {
        self.session = session
        self.maximumConsecutiveCaptureFailures = maximumConsecutiveCaptureFailures
        self.captureRetryBaseDelayNanoseconds = captureRetryBaseDelayNanoseconds
        removeStaleTemporarySessions()
        refreshDisplays()
        NotificationCoordinator.shared.configure()
        observeSystemEvents()
    }

    var isRecording: Bool { phase == .recording }
    var isPaused: Bool {
        if case .paused = phase { return true }
        return false
    }
    var canResume: Bool { isPaused && activeSystemInterruptions.isEmpty }
    var canExport: Bool { frameCount > 0 && (isRecording || isPaused) }
    var canStart: Bool { phase == .idle || isFinishedOrFailed }
    var resumePromptMessage: String {
        if case .paused(.captureInterrupted) = phase {
            return pausedDetail(for: .captureInterrupted)
        }
        return "As telas voltaram e seus quadros estão seguros. A gravação permanece pausada até você decidir."
    }
    var isFinishedOrFailed: Bool {
        if case .finished = phase { return true }
        if case .failed = phase { return true }
        return false
    }

    func pausedDetail(for reason: PauseReason) -> String {
        guard reason == .captureInterrupted else { return reason.detail }
        let frameStatus = frameCount == 0
            ? "Nenhum quadro foi salvo ainda."
            : "Os \(frameCount) quadros já salvos continuam seguros."
        if let lastCaptureErrorMessage {
            return "\(frameStatus) O Tempo tentou novamente antes de pausar. Detalhe: \(lastCaptureErrorMessage)"
        }
        return "\(frameStatus) Você pode tentar continuar."
    }

    func refreshDisplays() {
        var count: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &count)
        var ids = Array(repeating: CGDirectDisplayID(), count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        displays = ids.prefix(Int(count)).map { id in
            DisplayInfo(id: id, frame: CGDisplayBounds(id), isBuiltIn: CGDisplayIsBuiltin(id) != 0)
        }
    }

    func start() {
        guard canStart else { return }
        phase = .requestingPermission
        refreshDisplays()

        Task { [weak self] in
            do {
                try await CaptureSession.verifyAccess()
                self?.beginRecording()
            } catch {
                self?.phase = .failed(Self.captureErrorMessage(for: error))
            }
        }
    }

    private func beginRecording() {
        guard phase == .requestingPermission else { return }
        do {
            let newSession = try CaptureSession(quality: quality)
            session = newSession
            frameCount = 0
            captureInterval = 2
            exportProgress = 0
            accumulatedRecordingDuration = 0
            segmentStartedAt = nil
            wakePromptSent = false
            activeSystemInterruptions.removeAll()
            showResumePrompt = false
            lastCaptureErrorMessage = nil
            phase = .recording
            NotificationCoordinator.shared.requestAuthorizationIfNeeded()
            startCaptureLoop(session: newSession)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func startCaptureLoop(session activeSession: any CaptureSessionProtocol) {
        let maximumFailures = maximumConsecutiveCaptureFailures
        let baseDelay = captureRetryBaseDelayNanoseconds
        let failureTracker = CaptureFailureTracker()
        recordingTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await activeSession.run { count, interval in
                        await failureTracker.markCapture()
                        await MainActor.run {
                            guard let self, self.phase == .recording else { return }
                            if self.segmentStartedAt == nil {
                                self.segmentStartedAt = Date()
                            }
                            self.frameCount = count
                            self.captureInterval = interval
                            self.lastCaptureErrorMessage = nil
                        }
                    }
                    return
                } catch is CancellationError {
                    return
                } catch {
                    await Task.yield()
                    guard !Task.isCancelled else { return }

                    let failureCount = await failureTracker.registerFailure()
                    let message = Self.captureErrorMessage(for: error)
                    Self.logger.error("Capture attempt \(failureCount) failed: \(message, privacy: .public)")
                    await MainActor.run {
                        self?.lastCaptureErrorMessage = message
                    }

                    guard failureCount < maximumFailures else {
                        await MainActor.run {
                            self?.pauseAfterCaptureInterruption(error: error)
                        }
                        return
                    }

                    let exponent = min(failureCount - 1, 3)
                    let delay = baseDelay * UInt64(1 << exponent)
                    do {
                        try await Task.sleep(nanoseconds: delay)
                    } catch {
                        return
                    }
                }
            }
        }
    }

    func pauseManually() {
        pauseRecording(reason: .manual)
    }

    func resumeRecording() {
        guard canResume, let session else { return }
        showResumePrompt = false
        wakePromptSent = false
        activeSystemInterruptions.removeAll()
        NotificationCoordinator.shared.clearWakeNotification()
        refreshDisplays()
        segmentStartedAt = nil
        phase = .recording

        let settlingTask = pauseSettlingTask
        pauseSettlingTask = nil
        Task { [weak self] in
            await settlingTask?.value
            guard let self, self.phase == .recording else { return }
            self.startCaptureLoop(session: session)
        }
    }

    func keepPaused() {
        showResumePrompt = false
        NotificationCoordinator.shared.clearWakeNotification()
    }

    func recordingDuration(at date: Date = Date()) -> TimeInterval {
        accumulatedRecordingDuration + (segmentStartedAt.map { max(0, date.timeIntervalSince($0)) } ?? 0)
    }

    func stopAndExport() {
        guard canExport, let session else { return }
        finishActiveSegment()
        showResumePrompt = false
        wakePromptSent = false
        NotificationCoordinator.shared.clearWakeNotification()
        let task = recordingTask
        task?.cancel()
        recordingTask = nil
        let settlingTask = pauseSettlingTask
        pauseSettlingTask = nil
        phase = .exporting
        exportProgress = 0

        Task {
            await task?.value
            await settlingTask?.value
            let snapshot = await session.stop()
            guard !snapshot.frameURLs.isEmpty else {
                await session.discard()
                self.session = nil
                phase = .failed(TempoError.noFrames.localizedDescription)
                return
            }

            let savePanel = NSSavePanel()
            savePanel.title = "Salvar timelapse"
            savePanel.nameFieldStringValue = Self.suggestedFilename()
            savePanel.allowedContentTypes = [.mpeg4Movie]
            savePanel.canCreateDirectories = true
            if let movies = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first {
                savePanel.directoryURL = movies
            }

            guard savePanel.runModal() == .OK, let outputURL = savePanel.url else {
                await session.discard()
                self.session = nil
                phase = .idle
                resetRecordingClock()
                return
            }

            do {
                let exporter = VideoExporter()
                try await exporter.export(frames: snapshot.frameURLs, to: outputURL, quality: quality) { progress in
                    await MainActor.run { self.exportProgress = progress }
                }
                await session.discard()
                self.session = nil
                phase = .finished(outputURL)
                resetRecordingClock()
                NSSound(named: "Glass")?.play()
            } catch {
                await session.discard()
                self.session = nil
                try? FileManager.default.removeItem(at: outputURL)
                phase = .failed(error.localizedDescription)
                resetRecordingClock()
            }
        }
    }

    func cancelRecording() {
        guard (isRecording || isPaused), let session else { return }
        finishActiveSegment()
        showResumePrompt = false
        wakePromptSent = false
        activeSystemInterruptions.removeAll()
        NotificationCoordinator.shared.clearWakeNotification()

        let task = recordingTask
        task?.cancel()
        recordingTask = nil
        let settlingTask = pauseSettlingTask
        pauseSettlingTask = nil
        self.session = nil
        phase = .idle
        frameCount = 0
        exportProgress = 0
        lastCaptureErrorMessage = nil
        resetRecordingClock()
        refreshDisplays()

        Task {
            await task?.value
            await settlingTask?.value
            await session.discard()
        }
    }

    func revealFinishedVideo() {
        guard case .finished(let url) = phase else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else { return }
        NSWorkspace.shared.open(url)
    }

    func reset() {
        phase = .idle
        frameCount = 0
        exportProgress = 0
        showResumePrompt = false
        wakePromptSent = false
        activeSystemInterruptions.removeAll()
        lastCaptureErrorMessage = nil
        resetRecordingClock()
        refreshDisplays()
    }

    private static func suggestedFilename() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "yyyy-MM-dd 'às' HH-mm"
        return "Timelapse \(formatter.string(from: Date())).mp4"
    }

    private static func captureErrorMessage(for error: Error) -> String {
        let nsError = error as NSError
        let permissionErrorCodes = [-3801, -3803]
        if nsError.domain == SCStreamErrorDomain,
           permissionErrorCodes.contains(nsError.code) {
            return "O macOS bloqueou a captura. Ative o Tempo em Ajustes do Sistema › Privacidade e Segurança › Gravação da Tela e Áudio do Sistema e reabra o app."
        }
        return error.localizedDescription
    }

    private func pauseRecording(reason: PauseReason) {
        guard phase == .recording else { return }
        finishActiveSegment()
        phase = .paused(reason)
        showResumePrompt = false
        wakePromptSent = false

        let task = recordingTask
        task?.cancel()
        recordingTask = nil
        pauseSettlingTask = Task {
            await task?.value
        }
    }

    private func pauseAutomatically(
        reason: PauseReason,
        interruption: SystemInterruption
    ) {
        activeSystemInterruptions.insert(interruption)
        if phase == .recording {
            pauseRecording(reason: reason)
        }
    }

    private func pauseAfterCaptureInterruption(error: Error) {
        guard phase == .recording else { return }
        finishActiveSegment()
        recordingTask = nil
        lastCaptureErrorMessage = Self.captureErrorMessage(for: error)
        phase = .paused(.captureInterrupted)
        wakePromptSent = true
        showResumePrompt = true
    }

    private func handleSystemRecovery(_ interruption: SystemInterruption) {
        guard activeSystemInterruptions.remove(interruption) != nil,
              activeSystemInterruptions.isEmpty else { return }
        offerResumeAfterRecovery()
    }

    private func offerResumeAfterRecovery() {
        guard case .paused(let reason) = phase,
              reason.isAutomatic,
              !wakePromptSent else { return }
        wakePromptSent = true
        showResumePrompt = true
        refreshDisplays()
        NotificationCoordinator.shared.sendWakeNotification()
    }

    private func finishActiveSegment() {
        guard let segmentStartedAt else { return }
        accumulatedRecordingDuration += max(0, Date().timeIntervalSince(segmentStartedAt))
        self.segmentStartedAt = nil
    }

    private func resetRecordingClock() {
        segmentStartedAt = nil
        accumulatedRecordingDuration = 0
    }

    private func observeSystemEvents() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observe(workspaceCenter, name: NSWorkspace.screensDidSleepNotification) { [weak self] in
            self?.pauseAutomatically(reason: .screensAsleep, interruption: .screens)
        }
        observe(workspaceCenter, name: NSWorkspace.willSleepNotification) { [weak self] in
            self?.pauseAutomatically(reason: .systemSleep, interruption: .system)
        }
        observe(workspaceCenter, name: NSWorkspace.sessionDidResignActiveNotification) { [weak self] in
            self?.pauseAutomatically(reason: .sessionInactive, interruption: .session)
        }
        observe(workspaceCenter, name: NSWorkspace.screensDidWakeNotification) { [weak self] in
            self?.handleSystemRecovery(.screens)
        }
        observe(workspaceCenter, name: NSWorkspace.didWakeNotification) { [weak self] in
            self?.handleSystemRecovery(.system)
        }
        observe(workspaceCenter, name: NSWorkspace.sessionDidBecomeActiveNotification) { [weak self] in
            self?.handleSystemRecovery(.session)
        }

        let appCenter = NotificationCenter.default
        observe(appCenter, name: .tempoResumeRecording) { [weak self] in
            self?.resumeRecording()
        }
        observe(appCenter, name: .tempoKeepRecordingPaused) { [weak self] in
            self?.keepPaused()
        }
    }

    private func observe(
        _ center: NotificationCenter,
        name: Notification.Name,
        action: @escaping @MainActor () -> Void
    ) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
            Task { @MainActor in action() }
        }
        observers.append((center, token))
    }

    private func removeStaleTemporarySessions() {
        TemporarySessionCleaner.removeStaleSessions(
            in: FileManager.default.temporaryDirectory
        )
    }

    deinit {
        for observer in observers {
            observer.center.removeObserver(observer.token)
        }
    }
}
