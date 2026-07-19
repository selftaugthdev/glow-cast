import SwiftUI

struct NotificationsOptInView: View {
    let onEnable: () async -> Void
    let onSkip: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            OnboardingGradient()
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(Color.glowAmber.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 52))
                            .foregroundColor(.glowAmber)
                    }
                    .scaleEffect(appeared ? 1 : 0.5)

                    VStack(spacing: 12) {
                        Text("Stay in the golden window")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.glowGold)
                            .multilineTextAlignment(.center)
                        Text("We'll alert you when UV is perfect for your skin type — and warn you before you burn.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    VStack(alignment: .leading, spacing: 14) {
                        NotificationRow(icon: "sun.max.fill", color: .glowGold, text: "Morning tanning window forecast")
                        NotificationRow(icon: "timer", color: .glowAmber, text: "Burn timer halfway + end alerts")
                        NotificationRow(icon: "drop.fill", color: Color(red: 0.4, green: 0.7, blue: 1.0), text: "SPF reapplication reminders")
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.06))
                    )
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        Task { await onEnable() }
                    } label: {
                        Text("Enable Notifications")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.glowDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowGold)
                            .cornerRadius(16)
                    }

                    Button(action: onSkip) {
                        Text("Not now")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

struct NotificationRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
