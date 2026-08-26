import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

@MainActor
final class AppModel: ObservableObject {
    @Published var phase: AppPhase = .idle
    @Published var displays: [DisplayInfo] = []
    @Published var quality: OutputQuality = .sharp
    @Published var frameCount = 0
    @Published var captureInterval: TimeInterval = 2
    @Published var exportProgress = 0.0
    @Published var accumulatedRecordingDuration: TimeInterval = 0
    @Published var showResumePrompt = false

    private var session: CaptureSession?
    private var recordingTask: Task<Void, Never>?
    private var pauseSettlingTask: Task<Void, Never>?
    private var segmentStartedAt: Date?
    private var wakePromptSent = false
    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    init() {
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
    var canStart: Bool { phase == .idle || isFinishedOrFailed }
    var resumePromptMessage: String {
        if case .paused(.captureInterrupted) = phase {
            return "A captura foi interrompida, mas seus quadros estão seguros. Você pode tentar continuar ou manter a gravação pausada."
        }
        return "As telas voltaram e seus quadros estão seguros. A gravação permanece pausada até você decidir."
    }
    var isFinishedOrFailed: Bool {
        if case .finished = phase { return true }
        if case .failed = phase { return true }
        return false
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
            segmentStartedAt = Date()
            wakePromptSent = false
            showResumePrompt = false
            phase = .recording
            NotificationCoordinator.shared.requestAuthorizationIfNeeded()
            startCaptureLoop(session: newSession)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    private func startCaptureLoop(session activeSession: CaptureSession) {
        recordingTask = Task { [weak self] in
            do {
                try await activeSession.run { count, interval in
                    await MainActor.run {
                        self?.frameCount = count
                        self?.captureInterval = interval
                    }
                }
            } catch is CancellationError {
                // Expected when the user pauses or stops.
            } catch {
                await Task.yield()
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.pauseAfterCaptureInterruption()
                }
            }
        }
    }

    func pauseManually() {
        pauseRecording(reason: .manual)
    }

    func resumeRecording() {
        guard case .paused = phase, let session else { return }
        showResumePrompt = false
        wakePromptSent = false
        NotificationCoordinator.shared.clearWakeNotification()
        refreshDisplays()
        segmentStartedAt = Date()
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
        guard (isRecording || isPaused), let session else { return }
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

    private func pauseAutomatically(reason: PauseReason) {
        guard phase == .recording else { return }
        pauseRecording(reason: reason)
    }

    private func pauseAfterCaptureInterruption() {
        guard phase == .recording else { return }
        finishActiveSegment()
        recordingTask = nil
        phase = .paused(.captureInterrupted)
        wakePromptSent = true
        showResumePrompt = true
    }

    private func handleSystemWake() {
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
            self?.pauseAutomatically(reason: .screensAsleep)
        }
        observe(workspaceCenter, name: NSWorkspace.willSleepNotification) { [weak self] in
            self?.pauseAutomatically(reason: .systemSleep)
        }
        observe(workspaceCenter, name: NSWorkspace.sessionDidResignActiveNotification) { [weak self] in
            self?.pauseAutomatically(reason: .sessionInactive)
        }
        observe(workspaceCenter, name: NSWorkspace.screensDidWakeNotification) { [weak self] in
            self?.handleSystemWake()
        }
        observe(workspaceCenter, name: NSWorkspace.didWakeNotification) { [weak self] in
            self?.handleSystemWake()
        }
        observe(workspaceCenter, name: NSWorkspace.sessionDidBecomeActiveNotification) { [weak self] in
            self?.handleSystemWake()
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
        let temporaryDirectory = FileManager.default.temporaryDirectory
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: nil
        ) else { return }
        for item in items where item.lastPathComponent.hasPrefix("Tempo-") {
            try? FileManager.default.removeItem(at: item)
        }
    }

    deinit {
        for observer in observers {
            observer.center.removeObserver(observer.token)
        }
    }
}
