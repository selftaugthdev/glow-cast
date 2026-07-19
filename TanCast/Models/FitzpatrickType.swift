import SwiftUI

enum FitzpatrickType: String, CaseIterable, Codable {
    case typeI = "I"
    case typeII = "II"
    case typeIII = "III"
    case typeIV = "IV"
    case typeV = "V"
    case typeVI = "VI"

    var displayName: String { "Type \(rawValue)" }

    var description: String {
        switch self {
        case .typeI:   return "Very fair, always burns, never tans"
        case .typeII:  return "Fair skin, burns easily, tans minimally"
        case .typeIII: return "Medium, sometimes burns, tans gradually"
        case .typeIV:  return "Olive skin, rarely burns, tans easily"
        case .typeV:   return "Brown skin, very rarely burns, tans darkly"
        case .typeVI:  return "Dark brown/black, never burns, deeply pigmented"
        }
    }

    var emoji: String {
        switch self {
        case .typeI:   return "🌸"
        case .typeII:  return "🌷"
        case .typeIII: return "🌻"
        case .typeIV:  return "🌴"
        case .typeV:   return "🌺"
        case .typeVI:  return "🌙"
        }
    }

    var skinColor: Color {
        switch self {
        case .typeI:   return Color(red: 1.0, green: 0.92, blue: 0.87)
        case .typeII:  return Color(red: 0.98, green: 0.84, blue: 0.74)
        case .typeIII: return Color(red: 0.92, green: 0.74, blue: 0.58)
        case .typeIV:  return Color(red: 0.78, green: 0.58, blue: 0.40)
        case .typeV:   return Color(red: 0.58, green: 0.38, blue: 0.24)
        case .typeVI:  return Color(red: 0.30, green: 0.18, blue: 0.10)
        }
    }

    // MED (Minimal Erythemal Dose) in mJ/cm².
    // Standard literature values are 200–800 J/m²; 1 J/m² = 0.1 mJ/cm².
    var med: Double {
        switch self {
        case .typeI:   return 20
        case .typeII:  return 25
        case .typeIII: return 30
        case .typeIV:  return 45
        case .typeV:   return 60
        case .typeVI:  return 80
        }
    }

    func safeExposureMinutes(uvIndex: Double) -> Int {
        guard uvIndex >= 1 else { return 0 }
        let irradiance = uvIndex * 0.0025 // mW/cm²
        let seconds = med / irradiance
        return min(120, max(1, Int(seconds / 60)))
    }

    func recommendedSPF(uvIndex: Double) -> Int {
        switch uvIndex {
        case ..<3:  return 0
        case 3..<6:
            switch self {
            case .typeI, .typeII: return 30
            default: return 15
            }
        case 6..<8:
            switch self {
            case .typeI, .typeII: return 50
            case .typeIII, .typeIV: return 30
            default: return 15
            }
        default:
            switch self {
            case .typeI, .typeII: return 50
            case .typeIII: return 50
            case .typeIV: return 30
            default: return 30
            }
        }
    }

    static func from(romanNumeral: String) -> FitzpatrickType? {
        allCases.first { $0.rawValue == romanNumeral.uppercased() }
    }

    /// Maps an Individual Typology Angle (ITA°) to a Fitzpatrick type using the
    /// standard dermatological thresholds (Chardon et al.).
    static func from(ita: Double) -> FitzpatrickType {
        switch ita {
        case 55...:      return .typeI
        case 41..<55:    return .typeII
        case 28..<41:    return .typeIII
        case 10..<28:    return .typeIV
        case -30..<10:   return .typeV
        default:         return .typeVI
        }
    }
}
