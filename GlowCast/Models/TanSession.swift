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
    case safeTan = "Safe Tan"
    case maximizeGlow = "Maximize Glow"
    case protect = "Protect My Skin"

    var icon: String {
        switch self {
        case .safeTan:      return "sun.and.horizon"
        case .maximizeGlow: return "sparkles"
        case .protect:      return "shield.lefthalf.filled"
        }
    }

    var description: String {
        switch self {
        case .safeTan:      return "Build color gradually with full protection"
        case .maximizeGlow: return "Optimize every session for visible results"
        case .protect:      return "UV alerts only — safety is the priority"
        }
    }

    var multiplier: Double {
        switch self {
        case .safeTan:      return 0.8
        case .maximizeGlow: return 1.0
        case .protect:      return 0.6
        }
    }
}
