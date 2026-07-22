import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            switch vm.currentStep {
            case .hero:
                OnboardingHeroView { vm.advance() }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .skinScan:
                SkinScanView(
                    onCapture: { image in
                        Task { await vm.analyzeSkin(image: image) }
                    },
                    onSkip: { vm.skipSkinScan() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .scanResult:
                ScanResultView(skinType: $vm.skinType, scanFailed: vm.scanError != nil) { vm.advance() }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .goalSelector:
                GoalSelectorView(selectedGoal: $vm.tanGoal, hasPhotosensitivity: $vm.hasPhotosensitivity) { vm.advance() }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))

            case .notifications:
                NotificationsOptInView(
                    onEnable: { await vm.requestNotifications() },
                    onSkip: { vm.advance() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .paywall:
                PaywallView(
                    onSubscribe: {
                        vm.completeOnboarding()
                        onComplete()
                    },
                    onRestore: {
                        vm.completeOnboarding()
                        onComplete()
                    },
                    onDismiss: {
                        vm.completeOnboarding()
                        onComplete()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: vm.currentStep)
        .overlay(alignment: .top) {
            if vm.currentStep != .hero && vm.currentStep != .paywall {
                ProgressBar(progress: vm.progress)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
            }
        }
    }
}

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.glowAmber)
                    .frame(width: geo.size.width * progress, height: 3)
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 3)
    }
}
