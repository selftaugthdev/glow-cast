import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case hero = 0
    case skinScan
    case scanResult
    case goalSelector
    case notifications
    case paywall
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .hero
    @Published var skinType: FitzpatrickType = .typeII
    @Published var tanGoal: TanGoal = .safeTan
    @Published var isScanning = false
    @Published var scanComplete = false
    @Published var scanError: String?
    @Published var notificationsGranted = false

    private let claudeService = ClaudeVisionService()

    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentStep = next
        }
    }

    func analyzeSkin(image: UIImage) async {
        isScanning = true
        scanError = nil
        // Fake progress delay for dramatic effect
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        do {
            skinType = try await claudeService.analyzeSkinType(image: image)
        } catch {
            // Fallback silently — don't block onboarding
            skinType = .typeII
        }
        isScanning = false
        scanComplete = true
        advance()
    }

    func requestNotifications() async {
        notificationsGranted = await NotificationService.shared.requestPermission()
        advance()
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        UserDefaults.standard.set(skinType.rawValue, forKey: "skinType")
        UserDefaults.standard.set(tanGoal.rawValue, forKey: "tanGoal")
    }
}
