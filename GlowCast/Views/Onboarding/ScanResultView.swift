import SwiftUI

struct ScanResultView: View {
    @Binding var skinType: FitzpatrickType
    let onNext: () -> Void
    @State private var appeared = false
    @State private var showPicker = false

    var body: some View {
        ZStack {
            OnboardingGradient()
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                Text("Your Skin Profile")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(.glowGold)
                    .opacity(appeared ? 1 : 0)

                Text("AI estimate — adjust below if it's off")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.top, 6)
                    .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 40)

                // Skin type card
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(skinType.skinColor)
                            .frame(width: 100, height: 100)
                            .shadow(color: skinType.skinColor.opacity(0.5), radius: 20)
                        Text(skinType.emoji)
                            .font(.system(size: 44))
                    }

                    VStack(spacing: 8) {
                        Text("Fitzpatrick \(skinType.displayName)")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.glowGold)
                        Text(skinType.description)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.glowAmber.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 24)

                Button(action: { showPicker = true }) {
                    Label("Adjust manually", systemImage: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.glowAmber.opacity(0.8))
                }

                Spacer()

                Button(action: onNext) {
                    Text("That's me!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.glowDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.glowGold)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showPicker) {
            SkinTypePickerSheet(skinType: $skinType)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

struct SkinTypePickerSheet: View {
    @Binding var skinType: FitzpatrickType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(FitzpatrickType.allCases, id: \.self) { type in
                Button {
                    skinType = type
                    dismiss()
                } label: {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(type.skinColor)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(type.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if type == skinType {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.glowAmber)
                        }
                    }
                }
            }
            .navigationTitle("Select Skin Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
