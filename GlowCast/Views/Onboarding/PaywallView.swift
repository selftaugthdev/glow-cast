import SwiftUI

struct PaywallView: View {
    let onSubscribe: () -> Void
    let onRestore: () -> Void
    var onDismiss: (() -> Void)? = nil
    @State private var selectedPlan: PlanOption = .annual
    @State private var appeared = false
    @State private var dismissEnabled = false

    enum PlanOption { case monthly, annual }

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

                    Text("Join 50,000+ sun-smart people")
                        .font(.system(size: 14))
                        .foregroundColor(.glowAmber.opacity(0.7))
                        .padding(.top, 6)

                    Spacer().frame(height: 32)

                    // Benefits
                    VStack(spacing: 14) {
                        BenefitRow(icon: "wand.and.stars", text: "AI skin type estimate")
                        BenefitRow(icon: "sun.and.horizon.fill", text: "Personalized exposure windows")
                        BenefitRow(icon: "timer", text: "Burn-risk limit timer")
                        BenefitRow(icon: "drop.fill", text: "SPF reapplication reminders")
                        BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "3-day UV forecasts")
                    }
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 32)

                    // Plan picker
                    HStack(spacing: 12) {
                        PlanCard(
                            title: "Monthly",
                            price: "$6.99",
                            subtitle: "per month",
                            badge: nil,
                            isSelected: selectedPlan == .monthly
                        ) { selectedPlan = .monthly }

                        PlanCard(
                            title: "Annual",
                            price: "$29.99",
                            subtitle: "$2.50/month",
                            badge: "BEST VALUE",
                            isSelected: selectedPlan == .annual
                        ) { selectedPlan = .annual }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    Text("7-day free trial included")
                        .font(.system(size: 13))
                        .foregroundColor(.glowAmber.opacity(0.7))
                        .padding(.top, 12)

                    Spacer().frame(height: 32)

                    Button(action: onSubscribe) {
                        Text(selectedPlan == .annual ? "Start Free Trial" : "Subscribe Monthly")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.glowDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowGold)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)

                    Button(action: onRestore) {
                        Text("Restore Purchase")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.top, 14)

                    Text("Cancel anytime. Billed \(selectedPlan == .annual ? "annually" : "monthly").")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.25))
                        .padding(.top, 8)
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
