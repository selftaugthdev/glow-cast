import SwiftUI

struct MainDashboardView: View {
    @ObservedObject var vm: HomeViewModel
    @State private var sunPulse: CGFloat = 1.0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Location + date header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(vm.locationName, systemImage: "location.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                        Text(Date(), format: .dateTime.weekday(.wide).month().day())
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Hero UV display
                ZStack {
                    // Pulsing halo for UV >= 6
                    if vm.currentUV >= 6 {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(Color.uvColor(for: vm.currentUV).opacity(0.06 - Double(i) * 0.015))
                                .frame(width: 160 + CGFloat(i) * 40)
                                .scaleEffect(sunPulse)
                        }
                    }
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", vm.currentUV))
                            .font(.system(size: 88, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("UV Index")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        UVBadge(uvIndex: vm.currentUV)
                    }
                }
                .padding(.vertical, 8)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        sunPulse = 1.12
                    }
                }

                Spacer().frame(height: 32)

                // Tanning window card
                TanningWindowCard(forecast: vm.todayForecast, skinType: vm.skinType)
                    .padding(.horizontal, 20)

                Spacer().frame(height: 16)

                // Safe time + SPF row
                HStack(spacing: 12) {
                    StatCard(
                        icon: "timer",
                        title: "Safe Tan Time",
                        value: "\(vm.safeMinutes) min",
                        color: .glowAmber
                    )
                    StatCard(
                        icon: "drop.fill",
                        title: "SPF Needed",
                        value: vm.recommendedSPF == 0 ? "None" : "SPF \(vm.recommendedSPF)",
                        color: Color(red: 0.4, green: 0.8, blue: 1.0)
                    )
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 16)

                // Quick conditions row
                if let today = vm.todayForecast {
                    ConditionsRow(forecast: today, uvIndex: vm.currentUV)
                        .padding(.horizontal, 20)
                }

                Spacer().frame(height: 16)

                // Start session CTA
                if !vm.sessionActive {
                    Button {
                        vm.startSession()
                    } label: {
                        Label("Start Tan Session", systemImage: "play.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.glowDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowGold)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                } else {
                    ActiveSessionBanner(
                        secondsRemaining: vm.sessionSecondsRemaining,
                        totalSeconds: vm.sessionTotalSeconds,
                        onStop: { vm.stopSession() }
                    )
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 120)
            }
        }
    }
}

struct UVBadge: View {
    let uvIndex: Double
    var body: some View {
        Text(UVCategory(uvIndex: uvIndex).label)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.uvColor(for: uvIndex).opacity(0.7))
            .cornerRadius(8)
    }
}

struct TanningWindowCard: View {
    let forecast: DailyForecast?
    let skinType: FitzpatrickType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Tanning Window", systemImage: "sun.and.horizon.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.glowAmber.opacity(0.9))

            if let window = forecast?.tanningWindow {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timeRange(window.start, window.end))
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                        Text("Best hours for \(skinType.displayName) skin")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(.glowGold)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.glowAmber.opacity(0.25), Color.glowCoral.opacity(0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.glowAmber.opacity(0.35), lineWidth: 1)
                        )
                )
            } else {
                HStack {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.white.opacity(0.4))
                    Text("No ideal tanning window today")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                )
            }
        }
    }

    private func timeRange(_ start: Date, _ end: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h a"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
            }
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
        )
    }
}

struct ConditionsRow: View {
    let forecast: DailyForecast
    let uvIndex: Double

    var body: some View {
        HStack(spacing: 0) {
            ConditionItem(icon: "cloud.fill", label: "Clouds", value: "--")
            Divider().frame(height: 30).background(Color.white.opacity(0.15))
            ConditionItem(icon: "arrow.up.circle.fill", label: "Peak UV", value: String(format: "%.0f", forecast.maxUV))
            Divider().frame(height: 30).background(Color.white.opacity(0.15))
            ConditionItem(icon: "sunset.fill", label: "Sunset", value: timeString(forecast.sunset))
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    private func timeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        return fmt.string(from: date)
    }
}

struct ConditionItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.glowAmber.opacity(0.75))
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActiveSessionBanner: View {
    let secondsRemaining: Int
    let totalSeconds: Int
    let onStop: () -> Void

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - Double(secondsRemaining) / Double(totalSeconds)
    }

    var timeString: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Session Active")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.glowAmber)
                    Text("\(timeString) remaining")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.glowCoral)
                        .padding(10)
                        .background(Circle().fill(Color.glowCoral.opacity(0.15)))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.glowAmber)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.linear(duration: 1), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.glowAmber.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
