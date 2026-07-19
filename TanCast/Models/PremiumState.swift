import Foundation
import RevenueCat

final class PremiumState: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = PremiumState()

    static let entitlementID = "PRO"

    @Published private(set) var isPremium: Bool = false

    private override init() {
        super.init()
    }

    func configure() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Secrets.revenueCatAPIKey)
        Purchases.shared.delegate = self
        Task { await refresh() }
    }

    @MainActor
    func refresh() async {
        guard let info = try? await Purchases.shared.customerInfo() else { return }
        apply(info)
    }

    func fetchOfferings() async throws -> Offering? {
        try await Purchases.shared.offerings().current
    }

    @discardableResult
    func purchase(package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        await apply(result.customerInfo)
        return result.customerInfo
    }

    @discardableResult
    func restore() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        await apply(info)
        return info
    }

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { await apply(customerInfo) }
    }

    @MainActor
    private func apply(_ info: CustomerInfo) {
        isPremium = info.entitlements[Self.entitlementID]?.isActive == true
    }
}
