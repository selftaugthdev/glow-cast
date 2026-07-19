import SwiftUI

struct TanTimerView: View {
    @ObservedObject var vm: HomeViewModel
    @EnvironmentObject private var premium: PremiumState
    var onUpgrade: () -> Void = {}

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("Exposure Timer")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.glowDarkText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)

                Text(vm.hasPhotosensitivity ? "Sun protection mode" : "Burn-risk limit for your skin type")
                    .font(.system(size: 15))
                    .foregroundColor(.glowDarkText.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 4)

                Spacer().frame(height: 48)

                if vm.hasPhotosensitivity {
                    PhotosensitivityProtectionCard()
                        .padding(.horizontal, 28)

                    Spacer().frame(height: 120)
                } else {
                    timerContent
                }
            }
        }
    }

    @ViewBuilder
    private var timerContent: some View {
        Group {
                // Ring timer
                ZStack {
                    Circle()
                        .stroke(Color.glowDarkText.opacity(0.08), lineWidth: 12)
                        .frame(width: 240, height: 240)

                    Circle()
                        .trim(from: 0, to: vm.sessionActive ? vm.sessionProgress : 0)
                        .stroke(
                            LinearGradient(
                                colors: [Color.glowAmber, Color.glowCoral],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: vm.sessionProgress)

                    VStack(spacing: 4) {
                        if vm.sessionComplete {
                            VStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.glowAmber)
                                Text("Done!")
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(.glowDarkText)
                                Text("Apply SPF or find shade")
                                    .font(.system(size: 14))
                                    .foregroundColor(.glowDarkText.opacity(0.6))
                            }
                        } else if vm.sessionActive {
                            Text(timerString)
                                .font(.system(size: 52, weight: .black, design: .monospaced))
                                .foregroundColor(.glowDarkText)
                            Text("remaining")
                                .font(.system(size: 14))
                                .foregroundColor(.glowDarkText.opacity(0.5))
                        } else if vm.currentUV < 3 {
                            VStack(spacing: 6) {
                                Text("UV \(String(format: "%.1f", vm.currentUV))")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.glowDarkText.opacity(0.5))
                                Text("Burn risk is low — no timer needed below UV 3")
                                    .font(.system(size: 13))
                                    .foregroundColor(.glowDarkText.opacity(0.35))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        } else {
                            VStack(spacing: 6) {
                                Text(verbatim: "\(vm.safeMinutes)")
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundColor(.glowDarkText)
                                Text("minutes")
                                    .font(.system(size: 16))
                                    .foregroundColor(.glowDarkText.opacity(0.55))
                                Text("estimated limit for \(vm.skinType.displayName) at UV \(String(format: "%.0f", vm.currentUV))")
                                    .font(.system(size: 13))
                                    .foregroundColor(.glowAmber.opacity(0.8))
                            }
                        }
                    }
                }

                Spacer().frame(height: 16)

                Text("Not medical advice. No UV exposure is risk-free.")
                    .font(.system(size: 11))
                    .foregroundColor(.glowDarkText.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 32)

                if vm.sessionComplete {
                    Button {
                        vm.stopSession()
                    } label: {
                        Text("Start New Session")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.glowDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowGold)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 28)
                } else if vm.sessionActive {
                    Button {
                        vm.stopSession()
                    } label: {
                        Label("End Session", systemImage: "stop.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.glowCoral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowCoral.opacity(0.12))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.glowCoral.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 28)
                } else if vm.currentUV >= 3 {
                    Button {
                        vm.startSession()
                    } label: {
                        Label("Start Session", systemImage: "play.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.glowDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.glowGold)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 28)
                }

                Spacer().frame(height: 32)

                SessionHistorySection(
                    sessions: vm.sessionHistory,
                    isPremium: premium.isPremium,
                    onUpgrade: onUpgrade
                )
                .padding(.horizontal, 28)

                Spacer().frame(height: 120)
        }
    }

    private var timerString: String {
        let total = vm.sessionSecondsRemaining
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

struct SessionHistorySection: View {
    let sessions: [TanSession]
    let isPremium: Bool
    var onUpgrade: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Session History", systemImage: "clock.arrow.circlepath")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.glowAmber.opacity(0.9))

            if isPremium {
                if sessions.isEmpty {
                    Text("Your completed sessions will show up here.")
                        .font(.system(size: 13))
                        .foregroundColor(.glowDarkText.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.glowDarkText.opacity(0.05))
                        )
                } else {
                    VStack(spacing: 10) {
                        ForEach(sessions.prefix(5)) { session in
                            SessionHistoryRow(session: session)
                        }
                    }
                }
            } else {
                Button(action: onUpgrade) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.glowGold.opacity(0.12))
                                .frame(width: 44, height: 44)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.glowGold.opacity(0.7))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Track your sessions")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.glowDarkText)
                            Text("Unlock Premium to save your exposure history")
                                .font(.system(size: 12))
                                .foregroundColor(.glowDarkText.opacity(0.55))
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.glowDarkText.opacity(0.05))
                    )
                }
            }
        }
    }
}

struct SessionHistoryRow: View {
    let session: TanSession

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d · h:mm a"
        return f
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.uvColor(for: session.uvIndex).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.uvColor(for: session.uvIndex))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: session.startTime))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.glowDarkText)
                Text("UV \(String(format: "%.0f", session.uvIndex)) · \(session.skinType.displayName)")
                    .font(.system(size: 11))
                    .foregroundColor(.glowDarkText.opacity(0.5))
            }

            Spacer()

            Text("\(session.durationMinutes) min")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.glowAmber)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.glowDarkText.opacity(0.05))
        )
    }
}
