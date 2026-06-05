import SwiftUI

final class PremiumState: ObservableObject {
    static let shared = PremiumState()

    @Published var isPremium: Bool {
        didSet { UserDefaults.standard.set(isPremium, forKey: "isPremium") }
    }

    private init() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }

    func unlock() {
        isPremium = true
    }
}
