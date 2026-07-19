import Foundation

struct TanSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    let uvIndex: Double
    let skinType: FitzpatrickType
    let safeMinutes: Int

    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var durationMinutes: Int { Int(duration / 60) }

    var isActive: Bool { endTime == nil }
}

enum TanGoal: String, CaseIterable, Codable {
    case gradualExposure = "Gradual Exposure"
    case extendedExposure = "Extended Exposure"
    case protect = "Protect My Skin"

    var icon: String {
        switch self {
        case .gradualExposure:  return "sun.and.horizon"
        case .extendedExposure: return "sparkles"
        case .protect:          return "shield.lefthalf.filled"
        }
    }

    var description: String {
        switch self {
        case .gradualExposure:  return "Stay well within your burn-risk limit"
        case .extendedExposure: return "Use your full estimated exposure window"
        case .protect:          return "UV alerts only — minimize all exposure"
        }
    }

    var multiplier: Double {
        switch self {
        case .gradualExposure:  return 0.8
        case .extendedExposure: return 1.0
        case .protect:          return 0.6
        }
    }
}
