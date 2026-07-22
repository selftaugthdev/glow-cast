import SwiftUI

extension Color {
    static let glowAmber     = Color(red: 1.00, green: 0.72, blue: 0.20)
    static let glowCoral     = Color(red: 1.00, green: 0.45, blue: 0.33)
    static let glowGold      = Color(red: 1.00, green: 0.84, blue: 0.40)
    static let glowCream     = Color(red: 1.00, green: 0.97, blue: 0.90)
    static let glowDark      = Color(red: 0.12, green: 0.08, blue: 0.04)
    static let glowMedium    = Color(red: 0.25, green: 0.16, blue: 0.08)
    static let glowDarkText  = Color(red: 0.45, green: 0.18, blue: 0.02)

    // UV level colors
    static let uvLow         = Color(red: 0.30, green: 0.69, blue: 0.31)
    static let uvModerate    = Color(red: 1.00, green: 0.84, blue: 0.00)
    static let uvHigh        = Color(red: 1.00, green: 0.60, blue: 0.00)
    static let uvVeryHigh    = Color(red: 0.96, green: 0.26, blue: 0.21)
    static let uvExtreme     = Color(red: 0.61, green: 0.15, blue: 0.69)

    static func uvColor(for index: Double) -> Color {
        switch index {
        case ..<3:   return .uvLow
        case 3..<6:  return .uvModerate
        case 6..<8:  return .uvHigh
        case 8..<11: return .uvVeryHigh
        default:     return .uvExtreme
        }
    }

    static func backgroundGradient(for uvIndex: Double) -> [Color] {
        // EXPERIMENTAL: each stop lightened 50% toward white (testing whether a
        // lighter background reads better than darkening text further). Original
        // values are in git history — see the commit that introduced this comment.
        switch uvIndex {
        case ..<2:
            return [Color(red: 0.765, green: 0.825, blue: 0.915), Color(red: 0.68, green: 0.72, blue: 0.80)]
        case 2..<4:
            return [Color(red: 1.0, green: 0.925, blue: 0.775), Color(red: 0.975, green: 0.85, blue: 0.65)]
        case 4..<7:
            return [Color(red: 1.0, green: 0.86, blue: 0.60), Color(red: 0.975, green: 0.75, blue: 0.575)]
        case 7..<10:
            return [Color(red: 1.0, green: 0.775, blue: 0.60), Color(red: 0.95, green: 0.65, blue: 0.55)]
        default:
            return [Color(red: 0.925, green: 0.60, blue: 0.55), Color(red: 0.775, green: 0.55, blue: 0.525)]
        }
    }

    static func isLightBackground(for uvIndex: Double) -> Bool {
        uvIndex < 7
    }
}

struct GlowGradient: View {
    let uvIndex: Double
    var body: some View {
        LinearGradient(
            colors: Color.backgroundGradient(for: uvIndex),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct OnboardingGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.07, blue: 0.03),
                Color(red: 0.20, green: 0.12, blue: 0.05),
                Color(red: 0.30, green: 0.16, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
