import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var currentUV: Double = 0
    @Published var todayForecast: DailyForecast?
    @Published var threeDayForecast: [DailyForecast] = []
    @Published var locationName: String = "Locating..."
    @Published var isLoading = true
    @Published var loadError: LoadError?

    enum LoadError {
        case locationDenied
        case locationUnavailable
        case fetchFailed
    }

    // Timer session state
    @Published var sessionActive = false
    @Published var sessionSecondsRemaining: Int = 0
    @Published var sessionTotalSeconds: Int = 0
    @Published var sessionComplete = false
    @Published var sessionHistory: [TanSession] = []

    private var timerTask: Task<Void, Never>?
    private var currentSession: TanSession?
    private var sessionEndDate: Date?

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
        sessionHistory = SessionHistoryStore.shared.load()

        locationService.requestLocation()
        // Wait up to 15 seconds for first location fix; bail early on denial
        let deadline = Date().addingTimeInterval(15)
        while locationService.location == nil && Date() < deadline {
            if locationService.authorizationStatus == .denied ||
               locationService.authorizationStatus == .restricted {
                break
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        if locationService.authorizationStatus == .denied ||
           locationService.authorizationStatus == .restricted {
            loadError = .locationDenied
        } else if let loc = locationService.location {
            locationName = locationService.locationName
            await uvService.fetch(for: loc)
            if uvService.todayForecast == nil {
                loadError = .fetchFailed
            } else {
                loadError = nil
                todayForecast = uvService.todayForecast
                threeDayForecast = uvService.threeDayForecast
                currentUV = uvService.currentUV
            }
        } else {
            loadError = .locationUnavailable
        }
        isLoading = false

        if PremiumState.shared.isPremium {
            NotificationService.shared.scheduleMorningForecast(
                tomorrow: threeDayForecast.count > 1 ? threeDayForecast[1] : nil
            )
        }
    }

    func retry() async {
        isLoading = true
        loadError = nil
        await load()
    }

    func startSession() {
        guard !sessionActive, currentUV >= 3 else { return }
        let seconds = safeMinutes * 60
        sessionTotalSeconds = seconds
        sessionSecondsRemaining = seconds
        sessionEndDate = Date().addingTimeInterval(TimeInterval(seconds))
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
        sessionComplete = false
        sessionEndDate = nil
        NotificationService.shared.cancelSessionNotifications()
        saveCurrentSession()
        currentSession = nil
    }

    private func saveCurrentSession() {
        guard var session = currentSession, session.duration >= 60 else { return }
        session.endTime = Date()
        SessionHistoryStore.shared.add(session)
        sessionHistory = SessionHistoryStore.shared.load()
    }

    // Remaining time is derived from the wall clock, not a decrement counter:
    // the task suspends while the app is backgrounded, so ticks are not reliable.
    private func startTimer() {
        timerTask = Task {
            while !Task.isCancelled {
                syncRemainingTime()
                guard sessionActive else { break }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func syncRemainingTime() {
        guard let endDate = sessionEndDate, sessionActive else { return }
        let remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
        sessionSecondsRemaining = remaining
        if remaining == 0 {
            sessionActive = false
            sessionComplete = true
            sessionEndDate = nil
            saveCurrentSession()
            currentSession = nil
        }
    }
}
