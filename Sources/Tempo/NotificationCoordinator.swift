import AppKit
import Foundation
import UserNotifications

extension Notification.Name {
    static let tempoResumeRecording = Notification.Name("TempoResumeRecording")
    static let tempoKeepRecordingPaused = Notification.Name("TempoKeepRecordingPaused")
}

final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCoordinator()

    private enum Identifier {
        static let category = "TEMPO_RECORDING_WAKE"
        static let resume = "TEMPO_RESUME_RECORDING"
        static let keepPaused = "TEMPO_KEEP_PAUSED"
        static let wakeNotification = "TEMPO_WAKE_NOTIFICATION"
    }

    private lazy var center = UNUserNotificationCenter.current()
    private var isRunningAsApplication: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    private override init() {
        super.init()
    }

    func configure() {
        guard isRunningAsApplication else { return }
        center.delegate = self
        let resume = UNNotificationAction(
            identifier: Identifier.resume,
            title: "Continuar",
            options: [.foreground]
        )
        let keepPaused = UNNotificationAction(
            identifier: Identifier.keepPaused,
            title: "Manter pausado",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Identifier.category,
            actions: [resume, keepPaused],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func requestAuthorizationIfNeeded() {
        guard isRunningAsApplication else { return }
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    func sendWakeNotification() {
        guard isRunningAsApplication else { return }
        let content = UNMutableNotificationContent()
        content.title = "Timelapse pausado"
        content.body = "As telas voltaram. Quer continuar a gravação?"
        content.sound = .default
        content.categoryIdentifier = Identifier.category
        let request = UNNotificationRequest(
            identifier: Identifier.wakeNotification,
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func clearWakeNotification() {
        guard isRunningAsApplication else { return }
        center.removeDeliveredNotifications(withIdentifiers: [Identifier.wakeNotification])
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.wakeNotification])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let action = response.actionIdentifier
        DispatchQueue.main.async {
            switch action {
            case Identifier.resume:
                NotificationCenter.default.post(name: .tempoResumeRecording, object: nil)
            case Identifier.keepPaused:
                NotificationCenter.default.post(name: .tempoKeepRecordingPaused, object: nil)
            default:
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
        completionHandler()
    }
}
