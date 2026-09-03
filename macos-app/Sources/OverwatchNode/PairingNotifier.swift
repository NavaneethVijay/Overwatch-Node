import UserNotifications

/// Surfaces a new device's pairing code to the user. Primary channel is a
/// system notification (immediate, doesn't require knowing to open the
/// menu bar); also logged via AppLog as a fallback if notification
/// permission is denied or the notification gets dismissed before it's
/// read — this is a single-user tool, so a Console.app fallback is
/// reasonable, not a real gap.
enum PairingNotifier {
    static func notify(deviceName: String, code: String) {
        AppLog.lifecycle.info("pairing code for \(deviceName, privacy: .public): \(code, privacy: .public)")

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Overwatch Node — Pairing Request"
            content.body = "\(deviceName) wants to connect. Code: \(code)"
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
}
