import SwiftUI

struct OnboardingHeroView: View {
    let onNext: () -> Void
    @State private var sunScale: CGFloat = 1.0
    @State private var appeared = false

    var body: some View {
        ZStack {
            OnboardingGradient()
            VStack(spacing: 0) {
                Spacer()
                // Animated sun
                ZStack {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.glowAmber.opacity(0.08 - Double(i) * 0.025))
                            .frame(width: 220 + CGFloat(i) * 50, height: 220 + CGFloat(i) * 50)
                            .scaleEffect(sunScale)
                    }
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.glowGold, Color.glowAmber, Color.glowCoral],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .shadow(color: Color.glowAmber.opacity(0.6), radius: 40)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 48)

                VStack(spacing: 16) {
                    Text("GlowCast")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.glowGold)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Text("Get the perfect tan,\nwithout the burn.")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color.glowCream.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 56)

                Button(action: onNext) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.glowDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.glowGold)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)

                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                sunScale = 1.08
            }
        }
    }
}
