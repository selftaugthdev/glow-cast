import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    func scheduleMorningForecast(tanningWindow: (start: Date, end: Date)?, uvMax: Double) {
        let start = tanningWindow?.start
        var body = "UV stays low today — not worth it ☁️"
        if let s = start {
            let fmt = DateFormatter()
            fmt.dateFormat = "h a"
            let end = tanningWindow!.end
            body = "Today's tanning window: \(fmt.string(from: s))–\(fmt.string(from: end)) (UV \(Int(uvMax))) ☀️ Perfect for your skin type"
        }
        schedule(id: "morning_forecast", title: "GlowCast", body: body, hour: 8, minute: 0)
    }

    func scheduleSessionHalfway(after seconds: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds / 2, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "GlowCast"
        content.body = "Halfway through your safe tan time — flip over! 😄"
        content.sound = .default
        add(request: UNNotificationRequest(identifier: "session_halfway", content: content, trigger: trigger))
    }

    func scheduleSessionEnd(after seconds: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "GlowCast"
        content.body = "That's your dose for today — cover up or apply SPF 🧴"
        content.sound = .default
        add(request: UNNotificationRequest(identifier: "session_end", content: content, trigger: trigger))
    }

    func cancelSessionNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "session_halfway", "session_end"
        ])
    }

    private func schedule(id: String, title: String, body: String, hour: Int, minute: Int) {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        add(request: UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func add(request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Notification error: \(error)") }
        }
    }
}
