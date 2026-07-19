import SwiftUI
import RevenueCat

struct PaywallView: View {
    let onSubscribe: () -> Void
    let onRestore: () -> Void
    var onDismiss: (() -> Void)? = nil

    @State private var offering: Offering?
    @State private var offeringsFailed = false
    @State private var selectedPackage: Package?
    @State private var appeared = false
    @State private var dismissEnabled = false
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var hasFreeTrial: Bool {
        selectedPackage?.storeProduct.introductoryDiscount != nil
    }

    private var annualSavingsPercent: Int? {
        guard let monthly = offering?.monthly, let annual = offering?.annual else { return nil }
        let monthlyPrice = (monthly.storeProduct.price as NSDecimalNumber).doubleValue
        let annualPrice = (annual.storeProduct.price as NSDecimalNumber).doubleValue
        guard monthlyPrice > 0 else { return nil }
        let savings = 1 - (annualPrice / 12 / monthlyPrice)
        guard savings > 0 else { return nil }
        return Int((savings * 100).rounded())
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.05, blue: 0.02), Color(red: 0.18, green: 0.10, blue: 0.03)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if let onDismiss {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(dismissEnabled ? 0.5 : 0.0))
                                .frame(width: 44, height: 44)
                        }
                        .disabled(!dismissEnabled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    Spacer()
                }
                .zIndex(1)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Sun hero
                    ZStack {
                        Circle()
                            .fill(Color.glowAmber.opacity(0.12))
                            .frame(width: 140, height: 140)
                        Circle()
                            .fill(Color.glowAmber.opacity(0.08))
                            .frame(width: 180, height: 180)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.glowGold)
                    }
                    .padding(.top, 48)
                    .scaleEffect(appeared ? 1 : 0.6)

                    Spacer().frame(height: 24)

                    Text("Your personal UV safety guide")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.glowGold)
                        .multilineTextAlignment(.center)

                    Text("Personalized to your skin type")
                        .font(.system(size: 14))
                        .foregroundColor(.glowAmber.opacity(0.7))
                        .padding(.top, 6)

                    Spacer().frame(height: 32)

                    // Benefits
                    VStack(spacing: 14) {
                        BenefitRow(icon: "airplane", text: "Trip Planner for any destination")
                        BenefitRow(icon: "sun.and.horizon.fill", text: "Personalized exposure windows")
                        BenefitRow(icon: "timer", text: "Burn-risk limit timer")
                        BenefitRow(icon: "drop.fill", text: "SPF reapplication reminders")
                        BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "3-day UV forecasts")
                    }
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 32)

                    // Plan picker
                    if let offering {
                        HStack(spacing: 12) {
                            if let monthly = offering.monthly {
                                PlanCard(
                                    title: "Monthly",
                                    price: monthly.storeProduct.localizedPriceString,
                                    subtitle: "per month",
                                    badge: nil,
                                    isSelected: selectedPackage?.identifier == monthly.identifier
                                ) { selectedPackage = monthly }
                            }

                            if let annual = offering.annual {
                                PlanCard(
                                    title: "Annual",
                                    price: annual.storeProduct.localizedPriceString,
                                    subtitle: "per year",
                                    badge: annualSavingsPercent.map { "SAVE \($0)%" } ?? "BEST VALUE",
                                    isSelected: selectedPackage?.identifier == annual.identifier
                                ) { selectedPackage = annual }
                            }
                        }
                        .padding(.horizontal, 24)
                        .opacity(appeared ? 1 : 0)

                        if hasFreeTrial {
                            Text("Free trial included")
                                .font(.system(size: 13))
                                .foregroundColor(.glowAmber.opacity(0.7))
                                .padding(.top, 12)
                        }
                    } else if offeringsFailed {
                        VStack(spacing: 14) {
                            Text("Couldn't load subscription plans.")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)

                            Button {
                                Task { await loadOfferings() }
                            } label: {
                                Text("Retry")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.glowDark)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 12)
                                    .background(Color.glowGold)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 32)
                    } else {
                        ProgressView()
                            .tint(.glowGold)
                            .padding(.vertical, 40)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 12)
                    }

                    Spacer().frame(height: 32)

                    Button(action: purchase) {
                        if isPurchasing {
                            ProgressView()
                                .tint(.glowDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                        } else {
                            Text(hasFreeTrial ? "Start Free Trial" : "Subscribe")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.glowDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                        }
                    }
                    .background(Color.glowGold)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .disabled(selectedPackage == nil || isPurchasing)
                    .opacity(selectedPackage == nil ? 0.5 : 1)

                    Button(action: restore) {
                        Text("Restore Purchase")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.top, 14)
                    .disabled(isPurchasing)

                    Text("Cancel anytime. Billed \(selectedPackage?.packageType == .annual ? "annually" : "monthly").")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.top, 8)

                    // Required for auto-renewing subscriptions (App Review 3.1.2).
                    // TODO: point Privacy Policy at the real hosted URL before submission.
                    HStack(spacing: 16) {
                        Link("Terms of Use",
                             destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        Link("Privacy Policy",
                             destination: URL(string: "https://tancast.app/privacy")!)
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                appeared = true
            }
            if onDismiss != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation { dismissEnabled = true }
                }
            }
        }
        .task {
            await loadOfferings()
        }
    }

    private func loadOfferings() async {
        offeringsFailed = false
        do {
            guard let currentOffering = try await PremiumState.shared.fetchOfferings() else {
                offeringsFailed = true
                return
            }
            offering = currentOffering
            selectedPackage = currentOffering.annual ?? currentOffering.availablePackages.first
        } catch {
            offeringsFailed = true
        }
    }

    private func purchase() {
        guard let package = selectedPackage else { return }
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                try await PremiumState.shared.purchase(package: package)
                isPurchasing = false
                onSubscribe()
            } catch ErrorCode.purchaseCancelledError {
                isPurchasing = false
            } catch {
                isPurchasing = false
                errorMessage = "Something went wrong with the purchase. Please try again."
            }
        }
    }

    private func restore() {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                let info = try await PremiumState.shared.restore()
                isPurchasing = false
                if info.entitlements[PremiumState.entitlementID]?.isActive == true {
                    onRestore()
                } else {
                    errorMessage = "No previous purchase found for this account."
                }
            } catch {
                isPurchasing = false
                errorMessage = "Restore failed. Please try again."
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.glowAmber)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.glowAmber)
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let subtitle: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.glowDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.glowAmber)
                        .cornerRadius(4)
                } else {
                    Spacer().frame(height: 20)
                }

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .glowGold : .white.opacity(0.6))

                Text(price)
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(isSelected ? .glowGold : .white)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.glowAmber.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.glowAmber : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
    }
}
