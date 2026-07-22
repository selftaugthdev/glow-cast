import SwiftUI

struct SPFCalculatorView: View {
    let skinType: FitzpatrickType
    let uvIndex: Double
    var hasPhotosensitivity: Bool = false

    @State private var activity: ActivityType = .outdoor
    @State private var reapplySecondsRemaining: Int = 0
    @State private var reapplyTimerActive = false
    @State private var reapplyTask: Task<Void, Never>?

    enum ActivityType: String, CaseIterable {
        case daily = "Daily"
        case outdoor = "Outdoor"
        case swimming = "Swimming"

        var multiplier: Double {
            switch self {
            case .daily:    return 1.0
            case .outdoor:  return 1.2
            case .swimming: return 1.5
            }
        }

        var reapplyMinutes: Int {
            switch self {
            case .daily:    return 120
            case .outdoor:  return 90
            case .swimming: return 60
            }
        }

        var icon: String {
            switch self {
            case .daily:    return "figure.walk"
            case .outdoor:  return "figure.outdoor.cycle"
            case .swimming: return "figure.open.water.swim"
            }
        }
    }

    var recommendedSPF: Int {
        guard !hasPhotosensitivity else { return 50 }
        let base = skinType.recommendedSPF(uvIndex: uvIndex)
        let adjusted = Double(base) * activity.multiplier
        let rounded = [0, 15, 30, 50].last(where: { Double($0) <= adjusted }) ?? 50
        return Int(adjusted) == 0 ? 0 : max(15, rounded == 0 ? 30 : rounded)
    }

    var reapplyTimeString: String {
        let m = reapplySecondsRemaining / 60
        let s = reapplySecondsRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("SPF Calculator")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.glowDarkText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)

                Spacer().frame(height: 28)

                if hasPhotosensitivity {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 13))
                            .foregroundColor(.glowAmber.opacity(0.8))
                        Text("Sun protection mode: always maximum SPF, reapply often, seek shade.")
                            .font(.system(size: 12))
                            .foregroundColor(.glowDarkText.opacity(0.6))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.glowAmber.opacity(0.08)))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }

                // SPF result
                VStack(spacing: 8) {
                    if recommendedSPF == 0 {
                        Text("No SPF needed")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.uvLow)
                        Text("UV is low, enjoy safely")
                            .font(.system(size: 14))
                            .foregroundColor(.glowDarkText.opacity(0.55))
                    } else {
                        Text("SPF \(recommendedSPF)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundColor(.glowGold)
                        Text("recommended for \(skinType.displayName) • \(activity.rawValue)")
                            .font(.system(size: 14))
                            .foregroundColor(.glowDarkText.opacity(0.55))
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.glowDarkText.opacity(0.07))
                )
                .padding(.horizontal, 20)

                Spacer().frame(height: 24)

                // Activity selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.glowAmber.opacity(0.9))

                    HStack(spacing: 10) {
                        ForEach(ActivityType.allCases, id: \.self) { act in
                            ActivityChip(activity: act, isSelected: activity == act) {
                                withAnimation(.spring(response: 0.3)) { activity = act }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 24)

                // Skin type display
                HStack(spacing: 14) {
                    Circle()
                        .fill(skinType.skinColor)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(skinType.displayName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.glowDarkText)
                        Text(skinType.description)
                            .font(.system(size: 12))
                            .foregroundColor(.glowDarkText.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.glowDarkText.opacity(0.06))
                )
                .padding(.horizontal, 20)

                Spacer().frame(height: 24)

                // Reapplication timer
                if recommendedSPF > 0 {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reapplication Timer")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.glowAmber.opacity(0.9))
                                if reapplyTimerActive {
                                    Text("Reapply in \(reapplyTimeString) 🧴")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(.glowDarkText)
                                } else {
                                    Text("Every \(activity.reapplyMinutes) min")
                                        .font(.system(size: 16))
                                        .foregroundColor(.glowDarkText.opacity(0.6))
                                }
                            }
                            Spacer()
                            if reapplyTimerActive {
                                Button {
                                    stopReapplyTimer()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.glowDarkText.opacity(0.4))
                                }
                            }
                        }

                        if !reapplyTimerActive {
                            Button {
                                startReapplyTimer()
                            } label: {
                                Label("Start Reapply Timer", systemImage: "drop.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.glowDark)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.glowAmber)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.glowDarkText.opacity(0.06))
                    )
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 120)
            }
        }
    }

    private func startReapplyTimer() {
        reapplySecondsRemaining = activity.reapplyMinutes * 60
        reapplyTimerActive = true
        reapplyTask = Task {
            while reapplySecondsRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    await MainActor.run { reapplySecondsRemaining -= 1 }
                }
            }
            await MainActor.run { reapplyTimerActive = false }
        }
    }

    private func stopReapplyTimer() {
        reapplyTask?.cancel()
        reapplyTask = nil
        reapplyTimerActive = false
    }
}

struct ActivityChip: View {
    let activity: SPFCalculatorView.ActivityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: activity.icon)
                    .font(.system(size: 18))
                Text(activity.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .glowDark : .glowDarkText.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.glowAmber : Color.glowDarkText.opacity(0.07))
            )
        }
    }
}
