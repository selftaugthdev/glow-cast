import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var currentUV: Double = 0
    @Published var todayForecast: DailyForecast?
    @Published var threeDayForecast: [DailyForecast] = []
    @Published var locationName: String = "Locating..."
    @Published var isLoading = true

    // Timer session state
    @Published var sessionActive = false
    @Published var sessionSecondsRemaining: Int = 0
    @Published var sessionTotalSeconds: Int = 0
    @Published var sessionComplete = false

    private var timerTask: Task<Void, Never>?
    private var currentSession: TanSession?

    let locationService = LocationService()
    let uvService = UVService()

    var skinType: FitzpatrickType {
        let raw = UserDefaults.standard.string(forKey: "skinType") ?? "II"
        return FitzpatrickType.from(romanNumeral: raw) ?? .typeII
    }

    var tanGoal: TanGoal {
        let raw = UserDefaults.standard.string(forKey: "tanGoal") ?? TanGoal.gradualExposure.rawValue
        return TanGoal(rawValue: raw) ?? .gradualExposure
    }

    var safeMinutes: Int {
        let base = skinType.safeExposureMinutes(uvIndex: currentUV)
        guard base > 0 else { return 0 }
        return min(120, max(1, Int(Double(base) * tanGoal.multiplier)))
    }

    var recommendedSPF: Int {
        skinType.recommendedSPF(uvIndex: currentUV)
    }

    var tanningWindow: (start: Date, end: Date)? {
        todayForecast?.tanningWindow
    }

    var exposureScore: ExposureLevel {
        SunExposureScore.calculate(
            uvIndex: currentUV,
            skinType: skinType,
            cloudCoverPercent: todayForecast?.averageCloudCover ?? 0
        )
    }

    var sessionProgress: Double {
        guard sessionTotalSeconds > 0 else { return 0 }
        return 1.0 - Double(sessionSecondsRemaining) / Double(sessionTotalSeconds)
    }

    func load() async {
        locationService.requestLocation()
        // Wait up to 15 seconds for first location fix
        let deadline = Date().addingTimeInterval(15)
        while locationService.location == nil && Date() < deadline {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        if let loc = locationService.location {
            locationName = locationService.locationName
            await uvService.fetch(for: loc)
            todayForecast = uvService.todayForecast
            threeDayForecast = uvService.threeDayForecast
            currentUV = uvService.currentUV
        }
        isLoading = false
    }

    func startSession() {
        guard !sessionActive, currentUV >= 3 else { return }
        let seconds = safeMinutes * 60
        sessionTotalSeconds = seconds
        sessionSecondsRemaining = seconds
        sessionActive = true
        sessionComplete = false
        currentSession = TanSession(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            uvIndex: currentUV,
            skinType: skinType,
            safeMinutes: safeMinutes
        )
        NotificationService.shared.scheduleSessionHalfway(after: TimeInterval(seconds))
        NotificationService.shared.scheduleSessionEnd(after: TimeInterval(seconds))
        startTimer()
    }

    func stopSession() {
        timerTask?.cancel()
        timerTask = nil
        sessionActive = false
        NotificationService.shared.cancelSessionNotifications()
        currentSession = nil
    }

    private func startTimer() {
        timerTask = Task {
            while sessionSecondsRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    sessionSecondsRemaining -= 1
                    if sessionSecondsRemaining == 0 {
                        sessionActive = false
                        sessionComplete = true
                    }
                }
            }
        }
    }
}
