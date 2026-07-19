import SwiftUI

enum ExposureLevel: String {
    case low      = "Low"
    case moderate = "Moderate"
    case high     = "High"
    case avoid    = "Avoid"

    var color: Color {
        switch self {
        case .low:      return Color(red: 0.3, green: 0.85, blue: 0.4)
        case .moderate: return Color(red: 1.0, green: 0.8, blue: 0.1)
        case .high:     return Color(red: 1.0, green: 0.5, blue: 0.1)
        case .avoid:    return Color(red: 0.9, green: 0.2, blue: 0.2)
        }
    }

    var icon: String {
        switch self {
        case .low:      return "sun.min.fill"
        case .moderate: return "sun.max.fill"
        case .high:     return "exclamationmark.triangle.fill"
        case .avoid:    return "xmark.shield.fill"
        }
    }

    var advice: String {
        switch self {
        case .low:      return "Safe to be outside. Light SPF recommended."
        case .moderate: return "Apply SPF and limit unprotected time."
        case .high:     return "High burn risk. Cover up and reapply SPF."
        case .avoid:    return "Stay in shade. Seek shelter from UV."
        }
    }
}

struct SunExposureScore {
    static func calculate(
        uvIndex: Double,
        skinType: FitzpatrickType,
        cloudCoverPercent: Int
    ) -> ExposureLevel {
        guard uvIndex > 0 else { return .low }

        // Effective UV accounting for cloud cover
        let cloudFactor = 1.0 - (Double(cloudCoverPercent) / 100.0) * 0.75
        let effectiveUV = uvIndex * cloudFactor

        // Burn risk threshold relative to skin type MED
        let irradiance = effectiveUV * 0.0025
        let burnMinutes = irradiance > 0 ? (skinType.med / irradiance / 60) : 999

        switch burnMinutes {
        case 60...:  return .low
        case 30..<60: return .moderate
        case 15..<30: return .high
        default:     return .avoid
        }
    }
}
