import SwiftUI

struct GoalSelectorView: View {
    @Binding var selectedGoal: TanGoal
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            OnboardingGradient()
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                VStack(spacing: 12) {
                    Text("What's your goal?")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.glowGold)
                    Text("We'll personalize your tanning plan")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer().frame(height: 48)

                VStack(spacing: 16) {
                    ForEach(TanGoal.allCases, id: \.self) { goal in
                        GoalCard(goal: goal, isSelected: selectedGoal == goal) {
                            withAnimation(.spring(response: 0.3)) { selectedGoal = goal }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: onNext) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.glowDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.glowGold)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
    }
}

struct GoalCard: View {
    let goal: TanGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.glowAmber : Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)
                    Image(systemName: goal.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .glowDark : .white.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isSelected ? .glowGold : .white)
                    Text(goal.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(2)
                }
                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.glowAmber)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? Color.glowAmber.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? Color.glowAmber.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1.5)
                    )
            )
        }
    }
}
