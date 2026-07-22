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
    @Published var tanGoal: TanGoal = .gradualExposure
    @Published var hasPhotosensitivity = false
    @Published var isScanning = false
    @Published var scanComplete = false
    @Published var scanError: String?
    @Published var notificationsGranted = false

    // TODO: swap back to SkinToneService (on-device Vision) once the pixel-sampling
    // accuracy is verified against matched-lighting test photos — see commit history.
    private let skinToneService = ClaudeVisionProxyService()

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
            skinType = try await skinToneService.analyzeSkinType(image: image)
            scanComplete = true
        } catch {
            // Don't silently assign a type — the result screen routes to the manual picker.
            scanError = "We couldn't get a clear read from the photo."
        }
        isScanning = false
        advance()
    }

    func skipSkinScan() {
        scanError = "Skipped"
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
        UserDefaults.standard.set(hasPhotosensitivity, forKey: "hasPhotosensitivity")
    }
}
