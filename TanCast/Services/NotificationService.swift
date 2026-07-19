import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    // One-shot 8 AM notification built from tomorrow's forecast, rescheduled on each
    // app open. A repeating trigger would replay stale forecast text indefinitely.
    func scheduleMorningForecast(tomorrow: DailyForecast?, hasPhotosensitivity: Bool = false) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morning_forecast"])
        guard let tomorrow else { return }

        var body: String
        if hasPhotosensitivity {
            body = "UV forecast for today: \(Int(tomorrow.maxUV)). Seek shade and wear high SPF 🧴"
        } else {
            body = "UV stays low today — low burn risk ☁️"
            if let window = tomorrow.tanningWindow {
                let fmt = DateFormatter()
                fmt.dateFormat = "h a"
                body = "Today's exposure window: \(fmt.string(from: window.start))–\(fmt.string(from: window.end)) (UV \(Int(tomorrow.maxUV))) ☀️ Don't forget SPF"
            }
        }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow.date)
        comps.hour = 8
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "Tan Cast"
        content.body = body
        content.sound = .default
        add(request: UNNotificationRequest(identifier: "morning_forecast", content: content, trigger: trigger))
    }

    func scheduleSessionHalfway(after seconds: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds / 2, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "Tan Cast"
        content.body = "Halfway through your exposure limit — consider covering up or flipping over 🧴"
        content.sound = .default
        add(request: UNNotificationRequest(identifier: "session_halfway", content: content, trigger: trigger))
    }

    func scheduleSessionEnd(after seconds: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = "Tan Cast"
        content.body = "Exposure limit reached — seek shade or apply SPF now 🧴"
        content.sound = .default
        add(request: UNNotificationRequest(identifier: "session_end", content: content, trigger: trigger))
    }

    func cancelSessionNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "session_halfway", "session_end"
        ])
    }

    private func add(request: UNNotificationRequest) {
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Notification error: \(error)") }
        }
    }
}
