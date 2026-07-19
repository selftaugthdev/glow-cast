import SwiftUI

// TODO: SHIP BLOCKER — replace with RevenueCat before App Store submission.
// unlock() is called directly by the paywall's Subscribe/Restore buttons with no
// real purchase behind it, and the entitlement lives in UserDefaults. Submitting
// this with real prices on the paywall is an App Review rejection.
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
